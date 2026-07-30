## 1.2.0

* Migrated to `ton_dart` 2.3.0 and `blockchain_utils` 7.1.0. Minimum
  `ton_dart` constraint raised to `^2.3.0` to match the APIs actually used.
* **Breaking: TON testnet wallet addresses have changed.** `ton_dart` 2.3.0
  split the old `TonChainId` into `TonWorkChain` (workchain) and `TonChainId`
  (network); up to 2.2.0 `TonChainId.testnet` implied workchain `-1`, so
  testnet wallets were derived in the masterchain. Wallets are now derived in
  the basechain on both networks, meaning a key has the same raw address on
  mainnet and testnet, as it should on TON. Mainnet addresses are unchanged.
  Stored testnet addresses must be invalidated.
* **Breaking:** `TonProvider` now takes the API type as a second positional
  argument - `TonProvider(service, service.api)`.
* Added `TonAddressParser` (`parse` / `tryParse` / `isValid`) and applied it to
  every address string the service accepts. It rejects a wrong-length account
  hash and an out-of-range workchain, working around a `blockchain_utils`
  7.1.0 regression: the raw (`workchain:hex`) decoder no longer checks that the
  hash is 32 bytes, so `TonAddress('0:aabb')` stopped throwing and produced a
  malformed message that only failed after being signed and broadcast.
  `isValid` is also usable for validating user input up front.
* `TonHTTPProvider` moved to the new service-provider contract: mixed in
  instead of implemented, non-generic `doRequest`, `encodeUrl` / `encodeBody`,
  named `statusCode` in `toResponse`.
* `TonHelper.toNano` -> `toNanoGrams`, `TonAddress.toFriendlyAddress()` ->
  `toFriendly()`, `WalletV4.chain` -> `chainId`.
* Added tests for `TonAddressParser`.
* Added `CLAUDE.md` with the package invariants and the release checklist.

## 1.1.0

* Dependencies updated

## 1.0.2

* defaultRequestTimeout 10 sec

## 1.0.1

* Https dependency migration

## 1.0.0

* Initial release.
