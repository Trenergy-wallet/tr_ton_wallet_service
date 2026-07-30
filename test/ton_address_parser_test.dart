import 'package:test/test.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:tr_ton_wallet_service/tr_ton_wallet_service.dart';

void main() {
  const validRaw =
      '0:2a6ee6b7ff41bfecafe383386325c7a895f4fe4ce346b18eb9c14a0152d6629c';
  const validFriendlyMain = 'UQAqbua3_0G_7K_jgzhjJceolfT-TONGsY65wUoBUtZinP1w';
  const validFriendlyTest = '0QAqbua3_0G_7K_jgzhjJceolfT-TONGsY65wUoBUtZinEb6';
  const validMasterchain =
      '-1:de0736f873fe03bb8c4b50adb32ddd5aeec6e6a0f3b88cfa7beb1166b9c65eaa';

  group('accepts well-formed addresses', () {
    const valid = [
      validRaw,
      validFriendlyMain,
      validFriendlyTest,
      validMasterchain,
    ];
    for (final address in valid) {
      test(address.substring(0, 12), () {
        expect(TonAddressParser.parse(address).hash, hasLength(32));
        expect(TonAddressParser.isValid(address), isTrue);
      });
    }

    test('raw and friendly forms of one key share the account hash', () {
      expect(
        TonAddressParser.parse(validRaw).hash,
        TonAddressParser.parse(validFriendlyMain).hash,
      );
    });
  });

  group('rejects what ton_dart 2.3.0 lets through', () {
    final invalid = <String, String>{
      'short hash': '0:aabb',
      'empty hash': '0:',
      'one byte short': '0:${'ab' * 31}',
      'one byte long': '0:${'ab' * 33}',
      'workchain out of int8': '999:${'ab' * 32}',
      'empty string': '',
      'not an address': 'not-an-address',
      'broken crc16': 'UQAqbua3_0G_7K_jgzhjJceolfT-TONGsY65wUoBUtZinP1X',
    };
    for (final entry in invalid.entries) {
      final address = entry.value;
      test(entry.key, () {
        expect(
          () => TonAddressParser.parse(address),
          throwsA(isA<Exception>()),
        );
        expect(TonAddressParser.tryParse(address), isNull);
        expect(TonAddressParser.isValid(address), isFalse);
      });
    }
  });

  test('regression guard: bare TonAddress still accepts a truncated hash', () {
    // Documents why TonAddressParser exists. Should this ever start throwing,
    // the upstream regression is fixed and the guard can be reconsidered.
    expect(TonAddress('0:aabb').hash, hasLength(2));
  });
}
