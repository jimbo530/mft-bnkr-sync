// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// ═══════════════════════════════════════════════════════════════════════════
/// TASERN CHARACTERS — character-NFT mint path for the play-by-text RPG
/// (game/TEXT-RPG-FLOW.md · game/DM-PROMPT.md · game/stats-engine/)
///
/// PORT, NOT INVENTION. This is the live Tales-of-Tasern character pattern,
/// made mintable:
///   · Every live character (209 registered: 27 Base + 182 Polygon in
///     stats-engine/contracts.ts GAME_NFTS) is ONE contract holding ONE
///     1-of-1 token, id 1.
///   · The game's reader (Tales-of-Tasern useNftStats.ts) checks ownership
///     with ERC1155 `balanceOf(wallet, 1)` — so the child speaks ERC1155.
///   · STATS = the LP tokens (KNOWN_LP_PAIRS) held AT THE CHARACTER'S
///     CONTRACT ADDRESS. update-chain-data reads `pair.balanceOf(character)`,
///     derives underlying token amounts, and computeD20Stats.ts turns USD
///     value into D20 ability scores. The character contract needs NO LP
///     logic — it holds passively. Send LP to the address = stats grow.
///     (Raw non-LP ERC20s at the address do NOT count — LP pairs only.)
///
/// TasernCharacterFactory  — deployed ONCE per chain. createCharacter()
///   stamps a TasernCharacter child per player character and registers it
///   on-chain so the Coordinator can sync new characters into
///   nft-lp-database → GAME_NFTS → Supabase (registry-first rule).
///
/// TasernCharacter (child) — minimal single-token ERC1155:
///   · token id 1, supply 1, minted to the player at construction
///   · characterName + race stored on-chain at birth (identity for the DM)
///   · uri(id) = factory.characterURI(address) → baseURI + child address,
///     the same movable-metadata-host pattern as the live crew NFTs
///     (FeeShareDistributorV2 baseURI — DISPLAY-ONLY, never touches funds)
///
/// ESCAPE HATCH (build) → RENOUNCE (ship), fleet-wide:
///   Characters HOLD value (LP stat-backing; prizes flow into them —
///   TEXT-RPG-FLOW §3). During build the factory admin can recover
///   mis-sent tokens from any child via child.adminWithdraw(). At ship the
///   admin calls factory.renounceAdminWithdraw() ONCE — a one-way bool with
///   no un-set path, checked by every child — and every character's backing
///   becomes provably locked forever (matching the live semantics: LPs at a
///   character address never move).
///
/// GAS: children are stamped one per tx (createCharacter ≈ well under 2M);
/// nothing here approaches the ~16.5M per-tx cap. No staging needed.
/// ═══════════════════════════════════════════════════════════════════════════

interface IERC20Minimal {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC1155TokenReceiver {
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data)
        external returns (bytes4);
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data)
        external returns (bytes4);
}

interface ITasernCharacterFactory {
    function admin() external view returns (address);
    function adminWithdrawRenounced() external view returns (bool);
    function characterURI(address character) external view returns (string memory);
}

/// @title TasernCharacter — one playable character. 1-of-1 ERC1155, token id 1.
/// @notice The contract ADDRESS is the character's stat vault: LP tokens sent
///         here are read by the stats-engine as D20 ability scores. There is
///         deliberately NO transfer-out function for holdings (only the
///         build-phase adminWithdraw, disabled forever by the factory's
///         one-way renounce).
contract TasernCharacter {
    uint256 public constant CHARACTER_ID = 1;

    ITasernCharacterFactory public immutable factory;
    uint64 public immutable bornAt;

    string public characterName; // set at birth (the player's character name)
    string public race;          // set at birth (fantasy race picked at entry)
    address public holder;       // current owner of token id 1

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event AdminWithdraw(address indexed token, address indexed to, uint256 amount);

    /// @dev Deployed only by the factory. Plain mint at construction (no
    ///      receiver callback → no reentry window; same as MemeTrees.mint).
    constructor(string memory _name, string memory _race, address _player) {
        factory = ITasernCharacterFactory(msg.sender);
        characterName = _name;
        race = _race;
        holder = _player;
        bornAt = uint64(block.timestamp);
        emit TransferSingle(msg.sender, address(0), _player, CHARACTER_ID, 1);
    }

    // ── ERC1155 surface (single 1-of-1 token) ───────────────────────────────

    function balanceOf(address account, uint256 id) public view returns (uint256) {
        return (id == CHARACTER_ID && account != address(0) && account == holder) ? 1 : 0;
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external view returns (uint256[] memory out)
    {
        require(accounts.length == ids.length, "length mismatch");
        out = new uint256[](accounts.length);
        for (uint256 i; i < accounts.length; ++i) {
            out[i] = balanceOf(accounts[i], ids[i]);
        }
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "self approval");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external {
        require(id == CHARACTER_ID && amount == 1, "only the character");
        _transfer(from, to);
        emit TransferSingle(msg.sender, from, to, id, amount);
        if (to.code.length > 0) {
            require(
                IERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data)
                    == IERC1155TokenReceiver.onERC1155Received.selector,
                "receiver rejected"
            );
        }
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external {
        require(ids.length == amounts.length, "length mismatch");
        require(ids.length == 1 && ids[0] == CHARACTER_ID && amounts[0] == 1, "single 1-of-1 only");
        _transfer(from, to);
        emit TransferBatch(msg.sender, from, to, ids, amounts);
        if (to.code.length > 0) {
            require(
                IERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data)
                    == IERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "receiver rejected"
            );
        }
    }

    function _transfer(address from, address to) internal {
        require(to != address(0), "zero to");
        require(from == holder, "not holder");
        require(msg.sender == from || _operatorApprovals[from][msg.sender], "not authorized");
        holder = to;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7    // ERC165
            || interfaceId == 0xd9b67a26    // ERC1155
            || interfaceId == 0x0e89341c;   // ERC1155MetadataURI
    }

    /// @notice Metadata host lives on the factory (movable, display-only) —
    ///         same forever-NFT pattern as the live crew NFTs' baseURI.
    function uri(uint256) external view returns (string memory) {
        return factory.characterURI(address(this));
    }

    // ── Marketplace/DM-friendly views ────────────────────────────────────────

    function name() external view returns (string memory) { return characterName; }
    function symbol() external pure returns (string memory) { return "TOTC"; }
    function ownerOf() external view returns (address) { return holder; }

    // ── Build-phase escape hatch — renounced FLEET-WIDE via the factory ─────

    /// @notice Recover tokens mis-sent during build (wrong LP, wrong address).
    ///         Callable only by the factory admin, and only until the factory's
    ///         ONE-WAY renounceAdminWithdraw() — after that, disabled forever
    ///         on every character at once: backing is provably locked.
    function adminWithdraw(address token, uint256 amount) external {
        address a = factory.admin();
        require(msg.sender == a, "not admin");
        require(!factory.adminWithdrawRenounced(), "renounced");
        _safeTransfer(token, a, amount);
        emit AdminWithdraw(token, a, amount);
    }

    /// @dev Tolerates no-return-value tokens (USDT-style); reverts on failure —
    ///      no silent catches.
    function _safeTransfer(address token, address to, uint256 amount) internal {
        (bool ok, bytes memory ret) = token.call(abi.encodeWithSelector(IERC20Minimal.transfer.selector, to, amount));
        require(ok && (ret.length == 0 || abi.decode(ret, (bool))), "transfer failed");
    }
}

/// @title TasernCharacterFactory — stamps one TasernCharacter per player
///        character and keeps the on-chain birth registry the Coordinator
///        syncs into nft-lp-database / GAME_NFTS / Supabase.
contract TasernCharacterFactory {
    address public admin;
    bool public adminWithdrawRenounced;    // ONE-WAY: checked by every child's adminWithdraw
    bool public openMint;                  // false = allowlisted minters only (founder can open later)
    mapping(address => bool) public minters;
    string public baseURI;                 // display-only metadata host (movable)

    address[] public allCharacters;
    mapping(address => bool) public isCharacter;
    mapping(address => address[]) private _mintedFor;  // birth records per player (transfers not tracked)

    event CharacterCreated(address indexed character, address indexed player, string name, string race, uint256 index);
    event MinterSet(address indexed minter, bool allowed);
    event OpenMintSet(bool open);
    event BaseURISet(string baseURI);
    event AdminTransferred(address indexed prev, address indexed next);
    event AdminWithdrawRenounced();

    modifier onlyAdmin() { require(msg.sender == admin, "not admin"); _; }

    /// @param _admin   ops admin (agent wallet). Also a minter from birth.
    /// @param _baseURI metadata host prefix; "" is fine at deploy (set later).
    constructor(address _admin, string memory _baseURI) {
        require(_admin != address(0), "zero admin");
        admin = _admin;
        baseURI = _baseURI;
        minters[_admin] = true;
        emit MinterSet(_admin, true);
        if (msg.sender != _admin) {
            minters[msg.sender] = true;   // the deployer (BNKR) can mint from birth
            emit MinterSet(msg.sender, true);
        }
    }

    // ── Mint ─────────────────────────────────────────────────────────────────

    /// @notice Roll a new character: deploys its 1-of-1 contract and mints
    ///         token id 1 to the player. The new CONTRACT ADDRESS is the
    ///         character — register it, then send LPs to it to raise stats.
    /// @param player the player's wallet (receives token id 1)
    /// @param name_  character name (1–64 bytes)
    /// @param race_  fantasy race picked at entry (1–32 bytes; roster is
    ///               game-layer — e.g. human/dwarf/elf/goblin/orc/dragonborn)
    function createCharacter(address player, string calldata name_, string calldata race_)
        external returns (address character)
    {
        require(openMint || minters[msg.sender], "not a minter");
        require(player != address(0), "zero player");
        require(bytes(name_).length > 0 && bytes(name_).length <= 64, "bad name");
        require(bytes(race_).length > 0 && bytes(race_).length <= 32, "bad race");

        character = address(new TasernCharacter(name_, race_, player));
        isCharacter[character] = true;
        allCharacters.push(character);
        _mintedFor[player].push(character);
        emit CharacterCreated(character, player, name_, race_, allCharacters.length - 1);
    }

    // ── Views (registry sync) ────────────────────────────────────────────────

    function characterCount() external view returns (uint256) { return allCharacters.length; }

    function charactersSlice(uint256 start, uint256 end) external view returns (address[] memory out) {
        if (end > allCharacters.length) end = allCharacters.length;
        require(start <= end, "bad range");
        out = new address[](end - start);
        for (uint256 i = start; i < end; ++i) out[i - start] = allCharacters[i];
    }

    /// @notice Characters MINTED for a player (birth record; later transfers
    ///         are tracked by each character's own holder, not here).
    function charactersMintedFor(address player) external view returns (address[] memory) {
        return _mintedFor[player];
    }

    /// @notice uri for a child: baseURI + child address (crew-meta pattern,
    ///         keyed by contract address). DISPLAY-ONLY.
    function characterURI(address character) external view returns (string memory) {
        return string.concat(baseURI, _toHexString(character));
    }

    // ── Admin (display/config only — no funds ever sit here) ────────────────

    function setMinter(address minter, bool allowed) external onlyAdmin {
        require(minter != address(0), "zero minter");
        minters[minter] = allowed;
        emit MinterSet(minter, allowed);
    }

    function setOpenMint(bool open) external onlyAdmin {
        openMint = open;
        emit OpenMintSet(open);
    }

    function setBaseURI(string calldata _baseURI) external onlyAdmin {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    function transferAdmin(address next) external onlyAdmin {
        require(next != address(0), "zero admin");
        emit AdminTransferred(admin, next);
        admin = next;
    }

    /// @notice ONE-WAY ship-time lock: permanently disables adminWithdraw on
    ///         EVERY character (existing and future). No un-set path.
    function renounceAdminWithdraw() external onlyAdmin {
        adminWithdrawRenounced = true;
        emit AdminWithdrawRenounced();
    }

    // ── Internal ─────────────────────────────────────────────────────────────

    function _toHexString(address addr) internal pure returns (string memory) {
        bytes memory s = new bytes(42);
        s[0] = "0";
        s[1] = "x";
        bytes memory hexc = "0123456789abcdef";
        uint160 a = uint160(addr);
        for (uint256 i = 41; i > 1; i--) {
            s[i] = hexc[a & 0xf];
            a >>= 4;
        }
        return string(s);
    }
}
