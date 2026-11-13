import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:tr_logger/tr_logger.dart';
import 'package:tr_ton_wallet_service/tr_ton_wallet_service.dart';

final TonPrivateKey _key = TonPrivateKey.fromBytes(List.filled(32, 1));

/// Service over a node that is never reached: the transfer fails on the
/// recipient address before any request
TonWalletService _service({TRLogger? logger}) {
  final provider = TonHTTPProvider(
    tonApiUrl: 'https://tonapi.example',
    tonCenterUrl: 'https://toncenter.example',
    client: MockClient((_) async => http.Response('{}', 500)),
  );
  return TonWalletService.fromPublicKey(
    tonChain: TonChainId.testnet,
    publicKey: _key.toPublicKey(),
    rpc: TonProvider(provider, provider.api),
    logger: logger,
  );
}

Future<void> _failingTransfer(TonWalletService service) =>
    service.createTransfer(
      accessKey: _key,
      addressTo: 'not an address',
      amount: '1',
      sendToBlockchain: false,
    );

void main() {
  group('TonWalletService logging', () {
    setUp(InAppLogger().cleanLog);

    test('nothing is logged without a logger, the error is still '
        'thrown', () async {
      await expectLater(_failingTransfer(_service()), throwsA(anything));

      expect(InAppLogger().getLog, isEmpty);
    });

    test('the error goes to the given logger and is still thrown', () async {
      await expectLater(
        _failingTransfer(_service(logger: InAppLogger())),
        throwsA(anything),
      );

      expect(InAppLogger().getLog, contains('TonWalletService'));
      expect(InAppLogger().getLog, contains('createTransfer'));
    });
  });
}
