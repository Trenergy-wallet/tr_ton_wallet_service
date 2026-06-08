import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:tr_logger/tr_logger.dart';
import 'package:tr_ton_wallet_service/src/models/models.dart';
import 'package:tr_ton_wallet_service/src/services/services.dart';

/// Main service for TON transactions
class TonWalletService {
  /// Returns [TonWalletService]
  factory TonWalletService.fromPublicKey({
    required TonChainId tonChain,
    required TonPublicKey publicKey,
    required TonProvider rpc,
    TRLogger? logger,
  }) {
    final wallet = WalletV4.create(
      chain: tonChain,
      publicKey: publicKey.toBytes(),
    );
    return TonWalletService._(tonChain, wallet, rpc, logger);
  }

  /// Returns [TonWalletService] or throws an Exception
  factory TonWalletService.fromWalletAddress({
    required TonChainId tonChain,
    required String address,
    required TonProvider rpc,
    TRLogger? logger,
  }) {
    final wallet = WalletV4(address: TonAddress(address), chain: tonChain);
    return TonWalletService._(tonChain, wallet, rpc, logger);
  }

  TonWalletService._(this.tonChain, this.tonWallet, this.rpc, TRLogger? logger)
    : _logger = logger ?? InAppLogger();

  /// Rpc for api access
  final TonProvider rpc;

  /// Current blockchain
  final TonChainId tonChain;

  /// User wallet
  final WalletV4 tonWallet;

  static const _name = 'TonWalletService';

  final TRLogger _logger;

  /// Get wallet balance
  Future<int> fetchTonBalance() async =>
      (await tonWallet.getBalance(rpc)).toInt();

  /// Transfer TON to another wallet or throw an Exception
  ///
  /// Minimum amount is 0.000001 TON
  ///
  /// Returns the hash of the transaction: [sendToBlockchain] = true
  /// Returns the signed transaction (without sending to the blockchain):
  /// [sendToBlockchain] = false
  Future<String> createTransfer({
    required TonPrivateKey accessKey,
    required String addressTo,
    required String amount,
    bool sendToBlockchain = true,
    String? message,
  }) async {
    try {
      final tx = await tonWallet.sendTransfer(
        params: VersionedTransferParams(
          messages: [
            OutActionSendMsg(
              outMessage: TonHelper.internal(
                destination: TonAddress(addressTo),
                body: message != null
                    ? TonHelper.buildMessageBody(message)
                    : null,
                amount: TonHelper.toNano(amount),
              ),
            ),
          ],
          privateKey: accessKey,
        ),
        rpc: rpc,
        action: sendToBlockchain
            ? TonTransactionAction.broadcast
            : TonTransactionAction.boc,
        // onEstimateFee: (msg) async {
        //   final res = await rpc.request(TonCenterEstimateFee(
        //       address: tonWallet.address.toString(),
        //       body: msg.body.toBase64(),
        //       initCode: msg.init?.code?.toBase64() ?? '',
        //       initData: msg.init?.data?.toBase64() ?? ''));
        //   print('onEstimateFee: $res');
        //   return;
        // },
      );
      _logger.logInfoMessage(_name, 'createTransfer: created transaction\n$tx');
      return tx;
    } catch (e) {
      _logger.logError(_name, 'createTransfer: $e');
      rethrow;
    }
  }

  /// Returns JettonOnChainMetadata or throws an Exception
  Future<JettonOnChainMetadata> fetchJettonMetadata(
    String contractAddress,
  ) async {
    if (contractAddress.isEmpty) {
      throw ArgumentException.invalidOperationArguments(
        'fetchJettonMetadata',
        reason: 'contractAddress is empty',
      );
    }

    // We expect:
    // final resp = {
    //   "jetton_masters": [
    //     {
    //    "address":
    //    "-1:3A27A1AC86B58BDD58CD5A3AFCCF41CB460CC9D3D6062FC007318F971DEBFD3C",
    //      "total_supply": "100000000000000",
    //      "mintable": true,
    //     "admin_address":
    //    "-1:62789F25F312757F9900CC484A2E63960C12ED78FE878AA3EFD2E9D050379C0E",
    //       "jetton_content": {
    //         "decimals": "9",
    //         "description": "https://kabadh.github.io/ton_test_resources/",
    //         "image":
    //             "https://kabadh.github.io/ton_test_resources/testjettonicon.png",
    //         "name": "KabaCoin",
    //         "symbol": "KAB"
    //       },
    //       "jetton_wallet_code_hash":
    //           "JGoAI2ogvz36fzx32XwtkXPArLe1xp1GeBm/Drg2ydw=",
    //       "code_hash": "/OzfYPq/ARj0Wy3+Ph8pJiUaqNNXmIEeUcaZQl0B8oI=",
    //       "data_hash": "xMlP6YEnTGonQkkzGsisO6m0M16J1udahdeITAs/9J8=",
    //       "last_transaction_lt": "29443638000003"
    //     }
    //   ],
    //   "address_book": {
    // "-1:3A27A1AC86B58BDD58CD5A3AFCCF41CB460CC9D3D6062FC007318F971DEBFD3C": {
    //    "user_friendly": "kf86J6GshrWL3VjNWjr8z0HLRgzJ09YGL8AHMY-XHev9PE-A",
    //       "domain": null
    //     },
    // "-1:62789F25F312757F9900CC484A2E63960C12ED78FE878AA3EFD2E9D050379C0E": {
    //    "user_friendly": "0f9ieJ8l8xJ1f5kAzEhKLmOWDBLteP6HiqPv0unQUDecDuHo",
    //       "domain": null
    //     }
    //   },
    //   "metadata": {
    // "-1:3A27A1AC86B58BDD58CD5A3AFCCF41CB460CC9D3D6062FC007318F971DEBFD3C": {
    //       "is_indexed": true,
    //       "token_info": [
    //         {
    //           "type": "jetton_masters",
    //           "name": "KabaCoin",
    //           "symbol": "KAB",
    //           "description": "https://kabadh.github.io/ton_test_resources/",
    //           "image":
    //               "https://kabadh.github.io/ton_test_resources/testjettonicon.png",
    //           "extra": {"decimals": "9"}
    //         }
    //       ]
    //     }
    //   }
    // };
    final res = await rpc.request(
      TonCenterV3GetJettonMasters(address: contractAddress),
    );
    final data = JettonContent.fromJson(
      List<Map<String, dynamic>>.from(
            res['jetton_masters'] as List,
          ).first['jetton_content']
          as Map<String, dynamic>,
    );
    if (data.isValid) {
      return JettonOnChainMetadata.snakeFormat(
        name: data.name,
        decimals: data.decimals,
        description: data.description,
        image: data.image,
        symbol: data.symbol,
      );
    }
    throw Exception('Unable to get jetton metadata');
  }

  /// Returns JettonWalletsResponse or throws an Exception
  Future<TonAddress> fetchJettonWalletAddress(
    String contractJettonAddress,
  ) async {
    if (contractJettonAddress.isEmpty) {
      throw ArgumentException.invalidOperationArguments(
        'fetchJettonWalletAddress',
        reason: 'contractJettonAddress is empty',
      );
    }

    // GetJettonWalletResponse
    final res = await rpc.request(
      TonCenterV3GetJettonWallets(
        jettonAddress: contractJettonAddress,
        ownerAddress: tonWallet.address.toString(),
      ),
    );
    if (res.jettonWallets.isEmpty) {
      throw ArgumentException.invalidOperationArguments(
        'fetchJettonWalletAddress',
        reason:
            'No jetton wallets found for ${tonWallet.address} on jetton '
            'contract $contractJettonAddress',
      );
    }
    return TonAddress(
      res.jettonWallets.first.address.toFriendlyAddress(),
    );
  }

  /// Returns TonAddressStateType or throws an Exception
  ///
  /// If no walletAddress provided, we use tonWallet.address to check wallet`s
  /// self status
  ///
  /// Check it for given jettonWalletAddress before call openJettonWallet to
  /// ensure the jetton wallet is not frozen
  Future<TonAddressStateType> fetchWalletAddressState({
    String? walletAddress,
  }) async {
    final res = await rpc.request(
      TonCenterGetWalletInformation(
        walletAddress ?? tonWallet.address.toString(),
      ),
    );
    return TonAddressStateType.fromJson(res['account_state']);
  }

  /// Opens jetton wallet for specified contract or throws
  Future<TonJettonWalletService> openJettonWallet({
    required String jettonContractAddress,
    String? jettonWalletAddress,
    JettonOnChainMetadata? jettonOnChainMetadata,
  }) async {
    final jettonMetadata =
        jettonOnChainMetadata ??
        await fetchJettonMetadata(jettonContractAddress);
    return TonJettonWalletService.create(
      tonWalletService: this,
      jettonMasterContractAddress: jettonContractAddress,
      jettonWalletAddress: jettonWalletAddress,
      jettonOnChainMetadata: jettonMetadata,
    );
  }
}
