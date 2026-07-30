import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:ton_dart/ton_dart.dart';

/// Strict parser for TON address strings.
///
/// Prefer it over the bare [TonAddress] constructor for any address that comes
/// from outside the app - user input, a QR code, a deep link or a backend
/// response.
///
/// Why it exists: since `blockchain_utils` 7.1.0 the raw (`workchain:hex`)
/// branch of the decoder no longer checks that the account hash is 32 bytes,
/// and `TonAddress` returns such an address as is. `TonAddress('0:aabb')` used
/// to throw, now it yields an address with a 2-byte hash. It still serializes
/// without an error, producing a 27-bit `MsgAddressInt` instead of 267 bits -
/// so the failure surfaces only after the transaction has been signed and
/// broadcast, and the node rejects it with an opaque error.
///
/// The friendly base64 form (`EQ…`/`UQ…`/`kQ…`/`0Q…`) is unaffected: it is
/// still validated by an exact length check plus a CRC16 checksum.
abstract final class TonAddressParser {
  /// Parses [address] and guarantees the result is usable on-chain.
  ///
  /// Throws if the string is not a TON address, if the account hash is not
  /// exactly 32 bytes, or if the workchain does not fit into the `int8` used
  /// by the `MsgAddressInt` wire format.
  static TonAddress parse(String address) {
    final TonAddress parsed;
    try {
      parsed = TonAddress(address);
    } catch (e) {
      throw ArgumentException.invalidOperationArguments(
        'TonAddressParser.parse',
        name: 'address',
        reason: 'Invalid TON address: $e',
      );
    }
    if (parsed.hash.length != _addressHashLength) {
      throw ArgumentException.invalidOperationArguments(
        'TonAddressParser.parse',
        name: 'address',
        reason:
            'Invalid TON address: account hash must be $_addressHashLength '
            'bytes, got ${parsed.hash.length}.',
      );
    }
    final workchain = parsed.workchain.id;
    if (workchain < _minWorkchain || workchain > _maxWorkchain) {
      throw ArgumentException.invalidOperationArguments(
        'TonAddressParser.parse',
        name: 'address',
        reason: 'Invalid TON address: workchain $workchain is out of range.',
      );
    }
    return parsed;
  }

  /// Same as [parse] but returns `null` instead of throwing.
  static TonAddress? tryParse(String address) {
    try {
      return parse(address);
    } catch (_) {
      return null;
    }
  }

  /// Whether [address] is a well-formed TON address.
  ///
  /// Handy for validating user input before starting a transfer.
  static bool isValid(String address) => tryParse(address) != null;

  /// Length of a TON account hash.
  static const int _addressHashLength = 32;

  /// `MsgAddressInt` stores the workchain as `int8`.
  static const int _minWorkchain = -128;
  static const int _maxWorkchain = 127;
}
