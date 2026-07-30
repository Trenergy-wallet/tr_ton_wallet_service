# tr_ton_wallet_service

TON transaction service for TR.ENERGY Wallet. Thin, opinionated layer over
`ton_dart`: wallet **V4 only**, TON transfers + limited jetton support.

Not on pub.dev (`publish_to: none`). Consumed by `tron_energy_wallet_core`
(`../tron_energy_wallet_core`) — via `path:` during local dev, via git tag
`v<version>` in CI. Upstream deps (`ton_dart`, `blockchain_utils`) are
mrtnetwork, single maintainer, unsigned commits.

## Commands

```bash
dart pub get
dart analyze lib test    # NOT bare `dart analyze` — see Example below
dart format lib test
dart test
```

## Layout

`lib/src/{models,providers,services,utils}/` — each with a barrel
(`models.dart`, …) re-exported from `src/tr_ton_wallet_service_base.dart`.
**A new public file must be added to its barrel**, or it is invisible to
consumers.

Lints: `very_good_analysis`, strict — 80 columns, `public_member_api_docs`,
`cascade_invocations`. Restructure code rather than adding `// ignore:`;
misplaced ignores then trip `unnecessary_ignore`.

## Invariants — do not regress these

- **Never construct `TonAddress` from an outside string.** Use
  `TonAddressParser.parse` / `tryParse` / `isValid`. Since
  `blockchain_utils` 7.1.0 the raw (`workchain:hex`) decoder stopped checking
  that the account hash is 32 bytes, so `TonAddress('0:aabb')` succeeds with a
  2-byte hash and serializes into a malformed 27-bit `MsgAddressInt` that only
  fails after being signed and broadcast. Friendly base64 (`EQ…`/`UQ…`/`0Q…`)
  is still length- and CRC16-checked. `test/ton_address_parser_test.dart` pins
  the regression; if its last test starts failing, upstream fixed it.
- **Wallets derive in the basechain on both networks** (`WalletV4.create` with
  default `workchain`). Up to `ton_dart` 2.2.0 `TonChainId.testnet` implied
  workchain `-1` (masterchain), so testnet addresses changed in 1.2.0. Mainnet
  was never affected. `tonChain` now only selects the network global id
  (`-239`/`-3`) and the `testOnly` flag of the friendly address.
- `TonProvider` takes the api type as a second positional arg:
  `TonProvider(service, service.api)`.
- `TonHTTPProvider` is **mixed in** (`with TonServiceProvider`), non-generic
  `doRequest`, `encodeUrl` / `encodeBody`, named `statusCode` in `toResponse`.

## Dependency stack

`blockchain_utils`, `ton_dart`, `on_chain`, `bitcoin_base` move in lockstep —
each major of `blockchain_utils` forces a matching major of the others, so they
can only be bumped together, across this package and the core. Keep the
`ton_dart` constraint at the version whose APIs are actually used; it was once
left at `^2.2.0` while the code needed 2.3.0, held together only by a
transitive coincidence.

## Example

`example/` is a Flutter workspace member and **does not compile by design**:
it imports `excluded/sensitive_data.dart`, a local-only file with API keys and
mnemonics. That is ~12 pre-existing analyzer errors. Do not try to fix them,
and scope analysis to `lib test`.

## Release

1. `version:` in `pubspec.yaml`
2. `CHANGELOG.md` entry — mark breaking items explicitly; the tag is the only
   contract consumers see
3. `dart pub get && dart analyze lib test && dart format lib test && dart test`
4. commit, then tag `v<version>` (existing convention)
5. update the `ref:` in `tron_energy_wallet_core/pubspec.yaml` when switching
   that package back from `path:` to `git:`

Address-affecting releases also need the consumer to invalidate stored TON
addresses and clean stale records on the backend (`POST /api/wallets`).
