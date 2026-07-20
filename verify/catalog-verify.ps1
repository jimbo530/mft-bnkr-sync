# READ-ONLY: checks is_contract + name for catalog addresses via Blockscout v2 API
$targets = @(
  # chain base, host base.blockscout.com
  @{c="base"; n="Money (CharityFund)";        a="0xe3dd3881477c20C17Df080cEec0C1bD0C065A072"},
  @{c="base"; n="CHAR-R";                     a="0xde12963128CBe9aF173a37FFF866cA4D4A194ff4"},
  @{c="base"; n="CCC-R";                      a="0xb1265a9C15a467D7Fce45e61D926e900CCb6bF7B"},
  @{c="base"; n="PRGT";                       a="0xEe6fB5f324B05efF95fD59F4574050a891e6913D"},
  @{c="base"; n="BTC-T";                      a="0x839BAa00734f319C11F2869bC155C6B5Fe35a283"},
  @{c="base"; n="ETH-T";                      a="0x80d1edd0236A06283fd1212FDB12cfA79516933d"},
  @{c="base"; n="MfTVaultFactory";            a="0x1f6fF7370e2E897db7cf5d72684EF76d988Caaf1"},
  @{c="base"; n="MfTVaultFactoryFOT";         a="0x53b418bb3d27D45c34C240A5969121A7A34424C0"},
  @{c="base"; n="CharityFundFactory";         a="0x955383723E8A1AD82800406D6f492260918DF882"},
  @{c="base"; n="FundVaultFactory-CHAR-R";    a="0x503fe2226ed8c93bC7864a3E59cEb2c64C305c64"},
  @{c="base"; n="FundVaultFactory-CCC-R";     a="0x4a2DFd07A13aBD64553d34F65074fc716D97C290"},
  @{c="base"; n="FundVaultFactory-PRGT";      a="0xA54C86b545F6451c761Da684740bb390495170Df"},
  @{c="base"; n="BTCTVaultFactory";           a="0xA7BeD0d9963837E8426F241f132e1F8daEA6bD8B"},
  @{c="base"; n="ETHTVaultFactory";           a="0xc2Dbb3A02CF43270e3A69c2e15354887E094575f"},
  @{c="base"; n="ReactorPrimeV3";             a="0xA97af9770B79C3f0467ec8b3AD7e464154dbc9BA"},
  @{c="base"; n="CommissionBooth-Base";       a="0x1bA68C58d6d774227bf5cf48D8D3C27429616B8f"},
  @{c="base"; n="Unrugable factory";          a="0x90297A8a1F9A7E35bbC9DF8C35Aa7F3FFBe9BDb2"},
  @{c="base"; n="TasernBridgeBase";           a="0x492Ae01aad197D77ebB817597d8Fa096122040F8"},
  @{c="base"; n="MRB-BASE bridge";            a="0xD79360396ECa0c9A1Db6BC486fa80Db6449a93Cb"},
  @{c="base"; n="MfT token";                  a="0x8FB87d13B40B1A67B22ED1a17e2835fe7e3a9bA3"},
  # chain rh, host robinhoodchain.blockscout.com
  @{c="rh"; n="FTP vault";                    a="0x873739aeD7b49f005965377b5645914b1D78Ccd3"},
  @{c="rh"; n="GST vault";                    a="0x95eD511Dbdd7b52795e1F515314bE8d888Ea4F3F"},
  @{c="rh"; n="V4ReactorPrime";               a="0xd51125e200689bf07A9b36A6c12fE440bb92dd4D"},
  @{c="rh"; n="V4FryerTuckReactor";           a="0x90125c8C3103556c3cdc2cbC9B508A84F52497fA"},
  @{c="rh"; n="V4BurgersReactor";             a="0x3dB6BF508060b51FFC2622b81B888442e7B60458"},
  @{c="rh"; n="RHReactorFactory";             a="0xdC36A42cf7F964053EB3Ab2aF169BdaBF4263C80"},
  @{c="rh"; n="RHVaultFactory";               a="0xd41a8E5c44c4a83F6406eB7B530429E5411588Ec"},
  @{c="rh"; n="PrizePool-USDG";               a="0xF20c8d3B7EB81A2cf100e99690DA2E4D79F47D21"},
  @{c="rh"; n="Shillwood factory";            a="0xbc275E1B91d03716846A7a83513f1E47929dEF46"},
  @{c="rh"; n="ShillwoodReactor impl";        a="0xFc3A7EeB3eCE87358A2950F3b96eCc4908132348"},
  @{c="rh"; n="CommissionBooth-RH";           a="0xAfA527CF6Fa1fcFF66837FD3710d498e06aa6b05"},
  @{c="rh"; n="FTP Peg Community Vault v2";   a="0x7562593D18e47aA40EfCd04468b3D5222A40bbf3"},
  @{c="rh"; n="BURGERS Community Vault v2";   a="0x261F76D20983f299962b1481d7968d2F27b79BB1"},
  @{c="rh"; n="MRB-RH bridge";                a="0xa819b6D99135222f604047A3304ba53424D4779d"},
  @{c="rh"; n="MfT twin";                     a="0x6ae576608725677Bf8D05EA7796849E6F8F57608"},
  @{c="rh"; n="USDG";                         a="0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168"},
  @{c="rh"; n="ALAN token";                   a="0x5e35b494f4941cf6f47d407d93fee66a366daba3"},
  @{c="rh"; n="Morpho USDG vault";            a="0xBeEff033F34C046626B8D0A041844C5d1A5409dd"},
  # polygon
  @{c="poly"; n="TasernBridgePolygon";        a="0xBB62C2DCcCa84047b4445b1dB568A3c475B5016f"}
)
$hosts = @{ base="https://base.blockscout.com"; rh="https://robinhoodchain.blockscout.com"; poly="https://polygon.blockscout.com" }
foreach ($t in $targets) {
  $u = "$($hosts[$t.c])/api/v2/addresses/$($t.a)"
  try {
    $r = Invoke-RestMethod -Uri $u -TimeoutSec 20
    $verified = $false
    if ($null -ne $r.is_verified) { $verified = $r.is_verified }
    Write-Output ("{0}|{1}|{2}|is_contract={3}|name={4}|verified={5}" -f $t.c, $t.n, $t.a, $r.is_contract, $r.name, $verified)
  } catch {
    Write-Output ("{0}|{1}|{2}|ERROR={3}" -f $t.c, $t.n, $t.a, $_.Exception.Message)
  }
  Start-Sleep -Milliseconds 350
}
