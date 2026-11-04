import 'dart:async';

import 'package:blockchain_utils/service/service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:tr_ton_wallet_service/tr_ton_wallet_service.dart';

const _tonApiUrl = 'https://tonapi.example';
const _tonCenterUrl = 'https://toncenter.example';

TonRequestDetails _details({
  TonApiType api = TonApiType.tonApi,
  RequestMethod method = RequestMethod.get,
  String? body,
}) => TonRequestDetails(
  requestID: 1,
  path: '/v2/test',
  responseEncoding: ServiceReponseEncoding.map,
  headers: const {},
  requestMethod: method,
  bodyString: body,
  api: api,
);

/// [MockClient] that records every request it gets
MockClient _recordingClient(List<http.Request> requests) =>
    MockClient((request) async {
      requests.add(request);
      return http.Response('{"ok":true}', 200);
    });

TonHTTPProvider _provider({
  required http.Client client,
  String? Function()? getAuthorization,
  String? tonApiKey,
}) => TonHTTPProvider(
  tonApiUrl: _tonApiUrl,
  tonCenterUrl: _tonCenterUrl,
  client: client,
  getAuthorization: getAuthorization,
  tonApiKey: tonApiKey,
);

void main() {
  group('Authorization', () {
    test('is read on every request, a new value is picked up', () async {
      final requests = <http.Request>[];
      var authorization = 'Bearer first';
      var calls = 0;
      final provider = _provider(
        client: _recordingClient(requests),
        getAuthorization: () {
          calls++;
          return authorization;
        },
      );

      await provider.doRequest(_details());
      authorization = 'DPoP second';
      await provider.doRequest(_details());

      expect(calls, 2);
      expect(requests[0].headers['Authorization'], 'Bearer first');
      // The scheme is not added: the header goes as is
      expect(requests[1].headers['Authorization'], 'DPoP second');
    });

    for (final (name, getAuthorization) in [
      ('no callback', null),
      ('callback returns null', () => null),
      ('callback returns an empty string', () => ''),
    ]) {
      test('no Authorization header: $name', () async {
        final requests = <http.Request>[];
        final provider = _provider(
          client: _recordingClient(requests),
          getAuthorization: getAuthorization,
        );

        await provider.doRequest(_details());

        expect(requests.single.headers.containsKey('Authorization'), isFalse);
      });
    }
  });

  test('api_key header is sent when tonApiKey is set', () async {
    final requests = <http.Request>[];
    final provider = _provider(
      client: _recordingClient(requests),
      tonApiKey: 'key',
    );

    await provider.doRequest(_details());

    expect(requests.single.headers['api_key'], 'key');
  });

  test('all requests go through the one injected client', () async {
    final requests = <http.Request>[];
    final provider = _provider(client: _recordingClient(requests));

    await provider.doRequest(_details());
    await provider.doRequest(_details(method: RequestMethod.post, body: '{}'));
    await provider.doRequest(_details(api: TonApiType.tonCenter));

    expect(requests, hasLength(3));
  });

  group('routing', () {
    test('GET to TonApi', () async {
      final requests = <http.Request>[];
      final provider = _provider(client: _recordingClient(requests));

      await provider.doRequest(_details());

      final request = requests.single;
      expect(request.method, 'GET');
      expect(request.url.toString(), '$_tonApiUrl/v2/test');
    });

    test('POST to TonCenter with the body', () async {
      final requests = <http.Request>[];
      final provider = _provider(client: _recordingClient(requests));

      await provider.doRequest(
        _details(
          api: TonApiType.tonCenter,
          method: RequestMethod.post,
          body: '{"a":1}',
        ),
      );

      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.url.toString(), '$_tonCenterUrl/v2/test');
      expect(request.body, '{"a":1}');
    });
  });

  group('THROWS', () {
    test('TimeoutException when the response is late', () async {
      final provider = _provider(
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        provider.doRequest(
          _details(),
          timeout: const Duration(milliseconds: 10),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('ClientException from the client is passed through', () async {
      final provider = _provider(
        client: MockClient((_) async => throw http.ClientException('down')),
      );

      await expectLater(
        provider.doRequest(_details()),
        throwsA(isA<http.ClientException>()),
      );
    });
  });
}
