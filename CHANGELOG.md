## 2.1.0

* `TonHTTPProvider`, `TonWalletService` and `TonJettonWalletService` log only
  when a `logger` is passed. They used to fall back to `InAppLogger`, so an
  app that already logs the traffic of the http client it passes (e.g. through
  its own interceptors) got every TON request in the log twice. Pass
  `logger: InAppLogger()` to keep the old behavior. The `logger` field of
  `TonHTTPProvider` and `TonJettonWalletService` is nullable now.
* `TonHTTPProvider` logs the url of the request instead of
  `response.request`, which is null with some http clients.
* Added tests for logging.

## 2.0.0

* **Breaking:** `TonHTTPProvider` no longer stores the auth token. The
  `authToken` parameter is replaced with the `getAuthorization` callback,
  which is called on every request, so a long-lived provider always sends the
  current value. It returns the whole `Authorization` header value with its
  scheme (`Bearer …`, `DPoP …`), sent as is: the provider no longer adds
  `Bearer`. Migration: `authToken: token` ->
  `getAuthorization: () => 'Bearer $token'`, or better, pass a callback that
  reads the value from its source.
* `TonHTTPProvider` no longer sends `Authorization: Bearer ` for an empty
  token: null and empty both mean no `Authorization` header, as in the other
  wallet providers.
* `TonHTTPProvider` is meant to be created once and shared; it never closes
  the http client it is given.
* Added tests for `TonHTTPProvider`.

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
