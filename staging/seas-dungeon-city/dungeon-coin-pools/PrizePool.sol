// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IERC721Minimal {
    function ownerOf(uint256 tokenId) external view returns (address);
}

/// @title IOnchainCondition — pluggable eligibility check for ONCHAIN-mode achievements.
/// @notice The PrizePool stores a `condition` adapter + `threshold` per achievement and asks it
///         `meets(...)`. v1 ships ShiftCountCondition and TreeWaterCondition below, but ANY future
///         on-chain milestone (new game state, new vault) can be added by deploying a new adapter
///         and pointing an achievement at it — the PrizePool never needs redeploying.
interface IOnchainCondition {
    /// @return true if (collection, tokenId) currently satisfies the milestone at `threshold`.
    function meets(address collection, uint256 tokenId, uint256 threshold) external view returns (bool);
}

/// @title PrizePool — holds cbBTC and pays it out for configurable, extensible achievements.
/// @notice The cbBTC prize pool for the medieval Acorn court system. Funded by CourtEndowment
///         harvests (each tier funnels its cbBTC yield here) and by anyone via open fund().
///
///         ADD-ONLY ADMIN (HARD RULE — mirrors our add-only reactor rule):
///           The admin may  addAchievement(...) / pause an achievement / pre-attest eligibility
///           and the pool may be funded — but there is NO admin path to withdraw or drain the
///           cbBTC. The ONLY way cbBTC ever leaves this contract is claim(), which pays a verified
///           achievement reward to the NFT's CURRENT OWNER (resolved live). No rug, ever.
///
///         ACHIEVEMENT REGISTRY (extensible over time):
///           RewardType : FIXED (a set cbBTC amount) | BPS_OF_POOL (bps of the live cbBTC balance)
///           EligMode   : ONCHAIN (calls a pluggable IOnchainCondition adapter) |
///                        ADMIN_ATTESTED (admin pre-registers (achievementId,tokenId) eligible)
///           oneTimePerNFT : if true, each (collection,tokenId) may claim the achievement once
///           tierTag       : display/grouping only (e.g. 1=Mayor ... 5=Emperor); not enforced
///
///         claim(achievementId, collection, tokenId):
///           verifies eligibility for the mode, then pays the cbBTC reward to ownerOf(tokenId)
///           (live), marks claimed (one-time per NFT if set). Reverts if the pool balance is
///           insufficient (best-effort — rewards are never promised). nonReentrant + strict
///           checks-effects-interactions; exact transfers; no silent catches.
contract PrizePool is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ======================== IMMUTABLES ========================

    IERC20 public immutable cbBtc;  // the prize token (8 decimals)
    address public immutable admin; // add-only configurator; ZERO fund-withdrawal power

    uint256 public constant BPS_DENOM = 10_000;

    // ======================== ACHIEVEMENT REGISTRY ========================

    enum RewardType { FIXED, BPS_OF_POOL }
    enum EligMode   { ONCHAIN, ADMIN_ATTESTED }

    struct Achievement {
        bool exists;            // set true on add (ids are admin-chosen, so guard existence)
        bool active;            // admin may pause (stop new claims); can NEVER move funds
        RewardType rewardType;  // FIXED amount, or BPS_OF_POOL of live cbBTC balance
        uint256 amountOrBps;    // cbBTC amount (FIXED) or bps in [1..10000] (BPS_OF_POOL)
        EligMode eligMode;      // ONCHAIN (adapter) | ADMIN_ATTESTED (pre-registered)
        bool oneTimePerNFT;     // one claim per (collection,tokenId) if true
        uint8 tierTag;          // display/grouping only
        address condition;      // ONCHAIN: IOnchainCondition adapter (0 for ADMIN_ATTESTED)
        uint256 threshold;      // ONCHAIN: threshold passed to the adapter
    }

    /// @notice achievementId => config. ids are admin-chosen (lets the game map ids to meaning).
    mapping(uint256 => Achievement) public achievements;

    /// @notice achievementId => keccak256(collection,tokenId) => already claimed (one-time guard).
    mapping(uint256 => mapping(bytes32 => bool)) public claimed;

    /// @notice ADMIN_ATTESTED: achievementId => keccak256(collection,tokenId) => admin-marked eligible.
    mapping(uint256 => mapping(bytes32 => bool)) public attested;

    // Tracking (telemetry only)
    uint256 public totalFunded;     // cumulative cbBTC funded via fund()
    uint256 public totalPaidOut;    // cumulative cbBTC paid to winners
    uint256 public totalClaims;     // cumulative successful claims

    // ======================== EVENTS ========================

    event Funded(address indexed from, uint256 amount);
    event AchievementAdded(uint256 indexed id, RewardType rewardType, uint256 amountOrBps, EligMode eligMode, bool oneTimePerNFT, uint8 tierTag, address condition, uint256 threshold);
    event AchievementActiveSet(uint256 indexed id, bool active);
    event Attested(uint256 indexed id, address indexed collection, uint256 indexed tokenId, bool eligible);
    event Claimed(uint256 indexed id, address indexed collection, uint256 indexed tokenId, address recipient, uint256 amount);

    // ======================== CONSTRUCTOR ========================

    constructor(address _cbBtc, address _admin) {
        require(_cbBtc != address(0), "zero cbBtc");
        require(_admin != address(0), "zero admin");
        cbBtc = IERC20(_cbBtc);
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    function _key(address collection, uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(collection, tokenId));
    }

    // ======================== FUNDING (open; add-only by nature) ========================

    /// @notice Add cbBTC to the prize pool. Permissionless — CourtEndowment harvests call this
    ///         path implicitly by transferring cbBTC in, and patrons may top it up directly.
    ///         NOTE: a plain cbBtc.transfer to this contract also funds the pool (claims read the
    ///         live balance); fund() exists so top-ups are explicit and emit an event.
    function fund(uint256 amount) external nonReentrant {
        require(amount > 0, "zero");
        cbBtc.safeTransferFrom(msg.sender, address(this), amount);
        totalFunded += amount;
        emit Funded(msg.sender, amount);
    }

    // ======================== ADMIN: ADD-ONLY CONFIG (NEVER moves funds) ========================

    /// @notice Register a new achievement. Add-only: an id can be configured ONCE. The admin can
    ///         never change a live achievement's economics (only pause it), and can never withdraw.
    function addAchievement(
        uint256 id,
        RewardType rewardType,
        uint256 amountOrBps,
        EligMode eligMode,
        bool oneTimePerNFT,
        uint8 tierTag,
        address condition,   // required for ONCHAIN; must be address(0) for ADMIN_ATTESTED
        uint256 threshold    // ONCHAIN threshold; ignored for ADMIN_ATTESTED
    ) external onlyAdmin {
        require(!achievements[id].exists, "id exists");
        require(amountOrBps > 0, "zero reward");
        if (rewardType == RewardType.BPS_OF_POOL) {
            require(amountOrBps <= BPS_DENOM, "bps > 100%");
        }
        if (eligMode == EligMode.ONCHAIN) {
            require(condition != address(0) && condition.code.length > 0, "bad condition");
            require(threshold > 0, "zero threshold");
        } else {
            require(condition == address(0), "attested: no condition");
        }

        achievements[id] = Achievement({
            exists: true,
            active: true,
            rewardType: rewardType,
            amountOrBps: amountOrBps,
            eligMode: eligMode,
            oneTimePerNFT: oneTimePerNFT,
            tierTag: tierTag,
            condition: condition,
            threshold: threshold
        });

        emit AchievementAdded(id, rewardType, amountOrBps, eligMode, oneTimePerNFT, tierTag, condition, threshold);
    }

    /// @notice Pause / unpause an achievement (stops or resumes NEW claims). This is the ONLY
    ///         mutation allowed post-add, and it can only gate claims — it can NEVER move cbBTC.
    function setAchievementActive(uint256 id, bool active) external onlyAdmin {
        require(achievements[id].exists, "no achievement");
        achievements[id].active = active;
        emit AchievementActiveSet(id, active);
    }

    /// @notice ADMIN_ATTESTED only: pre-register that an NFT is eligible for an achievement (or
    ///         revoke before it claims). Off-chain feats (art contests, events) are attested here;
    ///         the NFT's CURRENT OWNER then calls claim() and the reward goes to that live owner.
    ///         This grants eligibility ONLY — it can never move funds or pay anyone directly.
    function attest(uint256 id, address collection, uint256 tokenId, bool eligible) external onlyAdmin {
        Achievement storage a = achievements[id];
        require(a.exists, "no achievement");
        require(a.eligMode == EligMode.ADMIN_ATTESTED, "not attested mode");
        attested[id][_key(collection, tokenId)] = eligible;
        emit Attested(id, collection, tokenId, eligible);
    }

    /// @notice Batch attest (gas-friendly for event/contest winners). Same add-only guarantee.
    function attestMany(uint256 id, address collection, uint256[] calldata tokenIds, bool eligible) external onlyAdmin {
        Achievement storage a = achievements[id];
        require(a.exists, "no achievement");
        require(a.eligMode == EligMode.ADMIN_ATTESTED, "not attested mode");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            attested[id][_key(collection, tokenIds[i])] = eligible;
            emit Attested(id, collection, tokenIds[i], eligible);
        }
    }

    // ======================== CLAIM (the ONLY cbBTC exit; pays the live NFT owner) ========================

    /// @notice Claim an achievement's cbBTC reward to the NFT's CURRENT owner.
    ///         Anyone may call (the reward always goes to ownerOf(tokenId), resolved live), so a
    ///         keeper or the owner can trigger it; griefers can only pay the rightful owner.
    ///         Reverts if ineligible, already claimed (one-time), paused, or the pool can't cover
    ///         the reward. Reentrancy-safe: effects (claimed flag) are written BEFORE the transfer.
    function claim(uint256 achievementId, address collection, uint256 tokenId) external nonReentrant {
        Achievement storage a = achievements[achievementId];
        require(a.exists, "no achievement");
        require(a.active, "achievement paused");
        require(collection != address(0), "zero collection");

        bytes32 k = _key(collection, tokenId);

        // One-time-per-NFT guard.
        if (a.oneTimePerNFT) {
            require(!claimed[achievementId][k], "already claimed");
        }

        // Resolve the live owner up front — they are the only valid recipient.
        address recipient = IERC721Minimal(collection).ownerOf(tokenId);
        require(recipient != address(0), "no owner");

        // One-time prizes can ONLY be claimed by the NFT's current owner — so a stranger cannot
        // force a premature claim when the pool is low and permanently lock the owner out
        // (audit MEDIUM grief vector). The owner picks the moment (e.g. a full pool). Repeatable
        // achievements stay open-callable (a premature claim there is not a lockout).
        if (a.oneTimePerNFT) {
            require(msg.sender == recipient, "owner must claim");
        }

        // --- Eligibility (CHECKS) ---
        if (a.eligMode == EligMode.ONCHAIN) {
            // Pluggable on-chain milestone (ShiftClock counts, vault treeWater, etc.).
            bool ok = IOnchainCondition(a.condition).meets(collection, tokenId, a.threshold);
            require(ok, "condition not met");
        } else {
            // ADMIN_ATTESTED: admin must have pre-registered this NFT as eligible.
            require(attested[achievementId][k], "not attested");
        }

        // --- Reward sizing ---
        uint256 reward;
        if (a.rewardType == RewardType.FIXED) {
            reward = a.amountOrBps;
        } else {
            // BPS_OF_POOL: a share of the live cbBTC balance.
            reward = (cbBtc.balanceOf(address(this)) * a.amountOrBps) / BPS_DENOM;
        }
        require(reward > 0, "zero reward");
        require(cbBtc.balanceOf(address(this)) >= reward, "pool underfunded");

        // --- EFFECTS (before the external transfer) ---
        if (a.oneTimePerNFT) {
            claimed[achievementId][k] = true;
        }
        // For ADMIN_ATTESTED, consume the attestation so a repeatable (non-one-time) achievement
        // still requires a fresh attestation per claim (prevents unbounded re-claims off one attest).
        if (a.eligMode == EligMode.ADMIN_ATTESTED) {
            attested[achievementId][k] = false;
        }
        totalPaidOut += reward;
        totalClaims += 1;

        // --- INTERACTIONS ---
        cbBtc.safeTransfer(recipient, reward);

        emit Claimed(achievementId, collection, tokenId, recipient, reward);
    }

    // ======================== VIEWS (for UI) ========================

    /// @notice Live cbBTC balance available for prizes.
    function poolBalance() external view returns (uint256) {
        return cbBtc.balanceOf(address(this));
    }

    /// @notice The cbBTC reward this achievement would pay right now (0 if FIXED+underfunded check
    ///         is left to claim()). For BPS_OF_POOL this reflects the current balance.
    function rewardAmount(uint256 achievementId) external view returns (uint256) {
        Achievement storage a = achievements[achievementId];
        if (!a.exists) return 0;
        if (a.rewardType == RewardType.FIXED) return a.amountOrBps;
        return (cbBtc.balanceOf(address(this)) * a.amountOrBps) / BPS_DENOM;
    }

    /// @notice Has this NFT already claimed the given achievement?
    function hasClaimed(uint256 achievementId, address collection, uint256 tokenId) external view returns (bool) {
        return claimed[achievementId][_key(collection, tokenId)];
    }

    /// @notice Would this NFT pass eligibility right now? (Does not check balance/active/claimed.)
    function isEligible(uint256 achievementId, address collection, uint256 tokenId) external view returns (bool) {
        Achievement storage a = achievements[achievementId];
        if (!a.exists) return false;
        if (a.eligMode == EligMode.ONCHAIN) {
            return IOnchainCondition(a.condition).meets(collection, tokenId, a.threshold);
        }
        return attested[achievementId][_key(collection, tokenId)];
    }
}

// ============================================================================
//  v1 ON-CHAIN CONDITION ADAPTERS (pluggable; each is a tiny, immutable, fund-free wrapper)
// ============================================================================

interface IShiftClock {
    function counts(address collection, uint256 tokenId) external view returns (uint32 single, uint32 double);
}

/// @title ShiftCountCondition — ONCHAIN eligibility: total shifts worked >= threshold.
/// @notice Wraps the immutable ShiftClock. `meets` is true once a worker's lifetime shift count
///         (single + double) reaches the achievement's threshold. Holds no funds, immutable.
contract ShiftCountCondition is IOnchainCondition {
    IShiftClock public immutable shiftClock;

    constructor(address _shiftClock) {
        require(_shiftClock != address(0), "zero shiftClock");
        shiftClock = IShiftClock(_shiftClock);
    }

    function meets(address collection, uint256 tokenId, uint256 threshold) external view override returns (bool) {
        (uint32 single, uint32 double) = shiftClock.counts(collection, tokenId);
        return uint256(single) + uint256(double) >= threshold;
    }
}

interface IWaterVault {
    function treeIdFor(address collection, uint256 tokenId) external view returns (uint256); // treeId+1, 0 = unplanted
    function treeWater(uint256 treeId) external view returns (uint256);
}

/// @title TreeWaterCondition — ONCHAIN eligibility: a worker's tree water >= threshold in a vault.
/// @notice Wraps one WaterV2-family vault. `meets` is true once the NFT's planted tree holds at
///         least `threshold` water (6-decimals) in that vault. Holds no funds, immutable.
contract TreeWaterCondition is IOnchainCondition {
    IWaterVault public immutable vault;

    constructor(address _vault) {
        require(_vault != address(0), "zero vault");
        vault = IWaterVault(_vault);
    }

    function meets(address collection, uint256 tokenId, uint256 threshold) external view override returns (bool) {
        uint256 idPlus1 = vault.treeIdFor(collection, tokenId);
        if (idPlus1 == 0) return false; // not planted in this vault
        return vault.treeWater(idPlus1 - 1) >= threshold;
    }
}
