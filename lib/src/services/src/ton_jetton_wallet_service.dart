import 'package:meta/meta.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:tr_logger/tr_logger.dart';
import 'package:tr_ton_wallet_service/src/models/models.dart';
import 'package:tr_ton_wallet_service/src/services/services.dart';
import 'package:tr_ton_wallet_service/src/utils/utils.dart';

/// Ton jetton wallet service
class TonJettonWalletService {
  TonJettonWalletService._(
    this.tonWalletService,
    this.jettonOnChainMetadata,
    this.jettonMasterContractAddress,
    this.jettonAddress,
    this._jettonWallet,
    TRLogger? logger,
  ) : logger = logger ?? InAppLogger();

  /// TON wallet
  final TonWalletService tonWalletService;

  /// Jetton Master Contract
  final String jettonMasterContractAddress;

  /// Metadata for jetton
  final JettonOnChainMetadata jettonOnChainMetadata;

  /// Jetton wallet address
  TonAddress? jettonAddress;

  /// Jetton wallet
  JettonWallet? _jettonWallet;

  /// Logger
  @protected
  final TRLogger logger;

  static const _name = 'TonJettonWalletService';

  bool get _needInitialization =>
      jettonAddress == null || _jettonWallet == null;

  /// Returns [TonWalletService] or throws
  static Future<TonJettonWalletService> create({
    required TonWalletService tonWalletService,
    required String jettonMasterContractAddress,
    required JettonOnChainMetadata jettonOnChainMetadata,
    String? jettonWalletAddress,
    TRLogger? logger,
  }) async {
    // Initial jettonWallet initialization
    TonAddress? jettonAddress;
    JettonWallet? jettonWallet;

    try {
      if (jettonWalletAddress != null) {
        jettonAddress = TonAddressParser.parse(jettonWalletAddress);
      }
      jettonAddress ??= await _fetchJettonAddress(
        jettonMasterContractAddress: jettonMasterContractAddress,
        tonWalletService: tonWalletService,
        logger: logger,
      );
      if (jettonAddress != null) {
        jettonWallet = await _tryCreateJettonWallet(
          jettonAddress,
          tonWalletService,
        );
      }
    } catch (e) {
      logger?.logError(_name, 'create: $e');
    }

    return TonJettonWalletService._(
      tonWalletService,
      jettonOnChainMetadata,
      jettonMasterContractAddress,
      jettonAddress,
      jettonWallet,
      logger,
    );
  }

  static Future<TonAddress?> _fetchJettonAddress({
    required String jettonMasterContractAddress,
    required TonWalletService tonWalletService,
    TRLogger? logger,
  }) async {
    try {
      final address = await tonWalletService.fetchJettonWalletAddress(
        jettonMasterContractAddress,
      );
      return address;
    } catch (e) {
      logger?.logError(_name, 'fetchJettonAddress: $e');
      return null;
    }
  }

  /// Initialize JettonWallet or throw
  static Future<JettonWallet?> _tryCreateJettonWallet(
    TonAddress jettonAddress,
    TonWalletService tonWalletService,
  ) async {
    final adr = await JettonWallet.fromAddress(
      address: jettonAddress,
      owner: tonWalletService.tonWallet,
      rpc: tonWalletService.rpc,
    );
    return adr;
  }

  /// Initialize JettonWallet or throw
  ///
  /// Async getter with build-in initialization
  ///
  /// [force] - create new wallet always
  Future<JettonWallet> tryInitJettonWallet({
    TonAddress? jettonWalletAddress,
    bool force = false,
  }) async {
    // Create new wallet if we get new TonAddress for the wallet
    if (jettonWalletAddress != null && jettonWalletAddress != jettonAddress) {
      jettonAddress = null;
      _jettonWallet = null;
    }
    if (_needInitialization || force) {
      if (force) {
        jettonAddress =
            jettonWalletAddress ??
            await _fetchJettonAddress(
              jettonMasterContractAddress: jettonMasterContractAddress,
              tonWalletService: tonWalletService,
              logger: logger,
            );
        if (jettonAddress == null) {
          throw Exception('Can not get Jetton address');
        }
        _jettonWallet = await JettonWallet.fromAddress(
          address: jettonAddress!,
          owner: tonWalletService.tonWallet,
          rpc: tonWalletService.rpc,
        );
      } else {
        jettonAddress ??=
            jettonWalletAddress ??
            await _fetchJettonAddress(
              jettonMasterContractAddress: jettonMasterContractAddress,
              tonWalletService: tonWalletService,
              logger: logger,
            );
        if (jettonAddress == null) {
          throw Exception('Can not get Jetton address');
        }
        _jettonWallet ??= await JettonWallet.fromAddress(
          address: jettonAddress!,
          owner: tonWalletService.tonWallet,
          rpc: tonWalletService.rpc,
        );
      }
    }
    if (_jettonWallet == null) {
      throw Exception('Error while activating the jettonWallet');
    }
    return _jettonWallet!;
  }

  /// FetchJettonBalance or throw
  Future<int> fetchJettonBalance() async {
    final jettonWallet = _jettonWallet ?? await tryInitJettonWallet();
    return (await jettonWallet.getBalance(tonWalletService.rpc)).toInt();
  }

  /// isActive or throw
  Future<bool> isActive() async {
    final jettonWallet = _jettonWallet ?? await tryInitJettonWallet();
    return jettonWallet.isActive(tonWalletService.rpc);
  }

  /// Returns TonAddressStateType or throws an Exception
  Future<TonAddressStateType> fetchWalletAddressState() async {
    if (jettonAddress == null) return TonAddressStateType.unknown;
    return tonWalletService.fetchWalletAddressState(
      walletAddress: jettonAddress.toString(),
    );
  }

  /// Send jetton or throw
  ///
  /// tonAmount - amount of TON to send with the transaction.
  /// default:
  /// tonWallet.chain == TonChain.mainnet
  ///           ? TonHelper.toNano('0.05')
  ///           : TonHelper.toNano("0.3"),
  Future<String> sendJettons({
    required TonPrivateKey key,
    required String amount,
    required TonAddress recipient,
    bool sendToBlockchain = true,
    String? tonAmount,
    String? message,
  }) async {
    final jettonWallet = _jettonWallet ?? await tryInitJettonWallet();
    final tx = await jettonWallet.sendOperation(
      signerParams: VersionedTransferParams(
        privateKey: key,
        // Wrong way to send message: the message will be separated from the
        // jetton transaction
        // messages: [
        //   if (message != null)
        //     OutActionSendMsg(
        //         outMessage: TonHelper.internal(
        //             destination: TonAddress(recipient.toString()),
        //             body: TonHelper.buildMessageBody(message),
        //             amount: TonHelper.toNano('0.0001'))),
        // ],
      ),
      rpc: tonWalletService.rpc,
      operation: JettonWalletTransfer(
        amount: TonHelper.toNanoGrams(amount),
        // Important! Send only to the main TON wallet address, otherwise
        // the recipient's token wallet contract will not be activated.
        destination: recipient, // jettonAddressForRecipient
        forwardTonAmount: BigInt.from(1),
        forwardPayload: _buildForwardCellWithMessage(message),
      ),
      amount: tonAmount == null
          ? tonWalletService.tonWallet.chainId == TonChainId.mainnet
                ? TonHelper.toNanoGrams('0.05')
                : TonHelper.toNanoGrams('0.3')
          : TonHelper.toNanoGrams(tonAmount),
      action: sendToBlockchain
          ? TonTransactionAction.broadcast
          : TonTransactionAction.boc,
      // onEstimateFee: (msg) async {
      //   final res = await tonWalletService.rpc.request(TonCenterEstimateFee(
      //       address: tonWalletService.tonWallet.address.toString(),
      //       body: msg.body.toBase64(),
      //       initCode: msg.init?.code?.toBase64() ?? '',
      //       initData: msg.init?.data?.toBase64() ?? ''));
      //   print('onEstimateFee: $res');
      //   return;
      // },
    ); // Mainnet
    return tx;
  }

  Cell? _buildForwardCellWithMessage(String? message) {
    if (message == null) return null;
    try {
      final builder = Builder()
        // First 32 bits as 0x0
        ..storeUint(0, 32)
        // Using UTF-8 for message and adding it to Cell
        ..storeStringTail(message);
      // Cell ready
      return builder.asCell();
    } on Exception catch (e) {
      logger.logError(_name, 'buildForwardCellWithMessage: $e');
    }
    return null;
  }
}
