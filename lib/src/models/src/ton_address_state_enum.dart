/// Addresses state
/// https://docs.ton.org/v3/documentation/smart-contracts/addresses
///
/// [nonexist] - there were no accepted transactions on this address, so it
/// doesn't have any data (or the contract was deleted).
///
/// [uninit] - address has some data, which contains balance and meta info.
/// At this state address doesn't have any smart contract code/persistent data
/// yet. An address enters this state, for example, when it was in a nonexist s
/// tate, and another address sent tokens to it.
///
/// [active] - address has smart contract code, persistent data and balance.
/// At this state it can perform some logic during the transaction and change
/// its persistent data. An address enters this state when it was uninit and
/// there was an incoming message with state_init param (note, that to be able
/// to deploy this address, hash of state_init and code must be equal to
/// address).
/// [frozen] - address cannot perform any operations, this state contains only
/// two hashes of the previous state (code and state cells respectively). When
/// an address's storage charge exceeds its balance, it goes into this state.
/// To unfreeze it, you can send an internal message with state_init and code
/// which store the hashes described earlier and some Toncoin. It can be
/// difficult to recover it, so you should not allow this situation.
enum TonAddressStateType {
  /// Unable to get the state
  unknown,

  /// There were no accepted transactions on this address, so it
  /// doesn't have any data (or the contract was deleted).
  nonexist,

  /// Address has some data, which contains balance and meta info.
  /// At this state address doesn't have any smart contract code/persistent data
  /// yet. An address enters this state, for example, when it was in a nonexist
  /// state, and another address sent tokens to it.
  uninit,

  /// Address has smart contract code, persistent data and balance.
  /// At this state it can perform some logic during the transaction and change
  /// its persistent data. An address enters this state when it was uninit and
  /// there was an incoming message with state_init param (note, that to be able
  /// to deploy this address, hash of state_init and code must be equal to
  /// address).
  active,

  /// Address cannot perform any operations, this state contains only
  /// two hashes of the previous state (code and state cells respectively). When
  /// an address's storage charge exceeds its balance, it goes into this state.
  /// To unfreeze it, you can send an internal message with state_init and code
  /// which store the hashes described earlier and some Toncoin. It can be
  /// difficult to recover it, so you should not allow this situation.
  frozen;

  const TonAddressStateType();

  /// fromJson
  factory TonAddressStateType.fromJson(dynamic json) => values.firstWhere(
    (e) => e.name == json.toString(),
    orElse: () => TonAddressStateType.unknown,
  );

  /// toJson
  String toJson() => name;
}
