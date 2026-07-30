/// This example provides access to the service interface for creating
/// transactions on the TON network and is intended for testing and experimentation.
///
/// The file "excluded/sensitive_data.dart" is not available in the repository
/// (it exists only locally). To run the example, you need to either remove the
/// reference to this file or create it manually. All variables used here with
/// the suffix "excluded" refer to this import file.

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:tr_ton_wallet_service/tr_ton_wallet_service.dart';

import 'excluded/sensitive_data.dart';

const bool isTestnet = true;
const selectedJetton = isTestnet ? SupportedJetton.tkab : SupportedJetton.xp;
const _toTransfer = 0.1;
const _toTransferJetton = 0.1;

enum SupportedJetton {
  @deprecated
  kaba(
    'kf86J6GshrWL3VjNWjr8z0HLRgzJ09YGL8AHMY-XHev9PE-A',
    // '0f9ieJ8l8xJ1f5kAzEhKLmOWDBLteP6HiqPv0unQUDecDuHo'
  ),
  tkab('kf-9rwnrpReBokhtdw5vJeWXveZQZRex0I23n1UTQwzAOJ9B'),
  xp(
    'EQAIK9sA6xo2mM1BybZcuBKbm1j5Ocu0jaeg__Lh7RJ_JuuG',
    // 'UQBgupknaj0qOmohTjc-QsfUTPd17TdZI2L4kZc1hZYntdqd'
  ),
  avacoin('EQAR-KBduwL4w-Lg72QFX4tWTOAJCGS72FkGHrJL9Qt7P9ln');

  const SupportedJetton(
    this.contractAddress,
    // , this.minterAddress
  );

  final String contractAddress;
  // final String minterAddress;
}

final metadataKaba = JettonOnChainMetadata.snakeFormat(
  name: "KabaCoin",
  image: "https://kabadh.github.io/ton_test_resources/testjettonicon.png",
  symbol: "KAB",
  decimals: 9,
  description: "https://kabadh.github.io/ton_test_resources/",
);

final metadataKabaNew = JettonOnChainMetadata.snakeFormat(
  name: "TestCoin",
  image: "https://kabadh.github.io/ton_test_resources/testjettonicon.png",
  symbol: "TKAB",
  decimals: 9,
  description: "https://kabadh.github.io/ton_test_resources/",
);

final metadataTest = JettonOnChainMetadata.snakeFormat(
  name: "TestCoinTT",
  image: "https://kabadh.github.io/ton_test_resources/testjettonicon.png",
  symbol: "TTTK",
  decimals: 9,
  description: "https://kabadh.github.io/ton_test_resources/",
);

final metadataTest2 = JettonOnChainMetadata.snakeFormat(
  name: "TestCoinTTT",
  image: "https://kabadh.github.io/ton_test_resources/testjettonicon.png",
  symbol: "TTKT",
  decimals: 9,
  description: "https://kabadh.github.io/ton_test_resources/",
);

/// INSERT the ApiKey
const _testApiKey = testApiKeyExcluded;
const _mainNetApiKey = mainNetApiKeyExcluded;
const _mainNetTestWallet1Seed = mainNetTestWallet1SeedExcluded;
const _mainNetTestWallet2Seed = mainNetTestWallet2SeedExcluded;

const currentMnemonic = mnemtest4excluded;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SomeScreen());
  }
}

class SomeScreen extends StatefulWidget {
  const SomeScreen({super.key});

  @override
  State<SomeScreen> createState() => _SomeScreenState();
}

class _SomeScreenState extends State<SomeScreen> {
  late Mnemonic mnemonics1;
  late final TonPrivateKey key1;
  late Mnemonic mnemonics2;
  late final TonPrivateKey key2;
  int balance1 = 0;
  int balance2 = 0;
  int jettonBalance1 = 0;
  int jettonBalance2 = 0;
  late final TonProvider rpc;

  late final TonWalletService wallet1service;
  TonJettonWalletService? wallet1serviceJetton;
  late final TonWalletService wallet2service;
  TonJettonWalletService? wallet2serviceJetton;
  final TextEditingController _addressTextController = TextEditingController();
  final TextEditingController _amountTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final service = isTestnet
        ? TonHTTPProvider(
            tonApiUrl: 'https://testnet.tonapi.io',
            tonCenterUrl: 'https://testnet.toncenter.com',
            tonApiKey: _testApiKey,
          )
        : TonHTTPProvider(
            tonApiUrl: 'https://tonapi.io',
            tonCenterUrl: 'https://toncenter.com',
            authToken: _mainNetApiKey,
          );
    rpc = TonProvider(service, service.api);
    _initWallets();
  }

  void _initWallets() {
    mnemonics1 = Mnemonic.fromList(
      isTestnet
          ? kaMinterTrxWalletMnemonicExcluded
          : _mainNetTestWallet1Seed.split(' '),
    );
    // Generate seed from mnemonic
    final seed1 = TonSeedGenerator(
      mnemonics1,
    ).generate(validateTonMnemonic: false);
    key1 = TonPrivateKey.fromBytes(seed1);
    // We can use here
    // TonMnemonicGenerator().fromWordsNumber(12, password: _password2)
    mnemonics2 = isTestnet
        ?
          // kaMnemonics2.isNotEmpty
          Mnemonic.fromList(currentMnemonic.split(' '))
        //         // ? Mnemonic.fromList(kaMnemonics2.skip(12).take(12).toList())
        //         :
        // TonMnemonicGenerator().fromWordsNumber(12)
        : Mnemonic.fromList(_mainNetTestWallet2Seed.split(' '));
    // Generate seed from mnemonic
    final seed2 = TonSeedGenerator(
      mnemonics2,
    ).generate(validateTonMnemonic: false);
    key2 = TonPrivateKey.fromBytes(seed2);
    print('mnem1: ${mnemonics1.toStr()}');
    print('mnem2: ${mnemonics2.toStr()}');

    // wallet1 = WalletV4(
    //     address: TonAddress('0f9ieJ8l8xJ1f5kAzEhKLmOWDBLteP6HiqPv0unQUDecDuHo'),
    //     chain: TonChain.testnet);
    // service1 ??= TonWalletService.fromWalletAddress(
    //     tonChain: TonChain.testnet,
    //     address: wallet1.address.toFriendlyAddress(),
    //     rpc: rpc);
    /// New contract MUST be deployed (cost appx 0.15 TON testnet)
    /// The deployment occurs automatically when funds are sent.
    wallet1service = TonWalletService.fromPublicKey(
      tonChain: isTestnet ? TonChainId.testnet : TonChainId.mainnet,
      publicKey: key1.toPublicKey(),
      rpc: rpc,
    );
    wallet2service = TonWalletService.fromPublicKey(
      tonChain: isTestnet ? TonChainId.testnet : TonChainId.mainnet,
      publicKey: key2.toPublicKey(),
      rpc: rpc,
    );
    printAllAddressesForWallet(wallet1service.tonWallet);
    printAllAddressesForWallet(wallet2service.tonWallet);
    fetchBalances();
    initJettonWallets(selectedJetton);
  }

  // Future<void> _mint() async {
  //   final keyToUse = key2;
  //   final wallet = WalletV4.create(
  //       chain: TonChain.testnet, publicKey: keyToUse.toPublicKey().toBytes());
  //
  //   final jetton = JettonMinter.create(
  //       owner: wallet,
  //       state: MinterWalletState(
  //         owner: wallet.address,
  //         chain: TonChain.testnet,
  //         metadata: metadataTest2,
  //         // totalSupply: BigInt.from(100000),
  //       ));
  //   //
  //   // /// check if contract is initialized.
  //   // Future<bool> isActive(TonProvider rpc) async {
  //   //   try {
  //   //     final state = await getState(rpc: rpc);
  //   //     return state.state.isActive;
  //   //   } catch  (_) {
  //   //     return false;
  //   //   }
  //   // }
  //   await jetton.sendOperation(
  //       signerParams: VersionedTransferParams(privateKey: keyToUse),
  //       rpc: rpc,
  //       amount: TonHelper.toNano("0.9"),
  //       operation: JettonMinterMint(
  //           totalTonAmount: TonHelper.toNano("0.5"),
  //           to: wallet.address,
  //           transfer: JettonMinterInternalTransfer(
  //               jettonAmount: TonHelper.toNano("1000000"),
  //               forwardTonAmount: TonHelper.toNano("0.01")),
  //           jettonAmount: TonHelper.toNano("1000000")));
  // }

  Future<void> fetchBalances() async {
    // Way 1
    // balance1 = (await wallet1.getBalance(rpc)).toInt();
    // balance2 = (await wallet2.getBalance(rpc)).toInt();
    // Way 2
    // balance1 = (await rpc.request(TonCenterGetAddressBalance(wallet1.address
    //         .toFriendlyAddress(
    //             testOnly: _isTestOnly, bounceable: _isBounceableWallet))))
    //     .toInt();
    // balance2 = (await rpc.request(TonCenterGetAddressBalance(wallet2.address
    //         .toFriendlyAddress(
    //             testOnly: _isTestOnly, bounceable: _isBounceableWallet))))
    //     .toInt();
    balance1 = await wallet1service.fetchTonBalance();
    balance2 = await wallet2service.fetchTonBalance();
    setState(() {});
  }

  Future<void> initJettonWallets(SupportedJetton jetton) async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      wallet1serviceJetton = await wallet1service.openJettonWallet(
        jettonContractAddress: jetton.contractAddress,
      );
      await Future.delayed(const Duration(seconds: 2));
      wallet2serviceJetton = await wallet2service.openJettonWallet(
        jettonContractAddress: jetton.contractAddress,
      );
    } catch (e) {
      debugPrint('💡initJettonWallets :: exception: $e');
    }
  }

  void printAllAddressesForWallet(WalletV4 wallet) {
    print(
      'address toString: ${wallet.address.toString()}, raw: ${wallet.address.toRawAddress()}',
    );
    // print(
    //     'address testOnly: false, bounceable:false: ${wallet.address.toFriendlyAddress(bounceable: false, testOnly: false)}');
  }

  Future<void> onPushFloatBtn() async {
    print('address to check: ${wallet1serviceJetton?.jettonAddress}');
    final res = await wallet1service.fetchWalletAddressState();
    debugPrint('💡_SomeScreenState.onPushFloatBtn :: res: $res');
  }

  @override
  void dispose() {
    _addressTextController.dispose();
    _amountTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet1 = wallet1service.tonWallet;
    final wallet2 = wallet2service.tonWallet;
    return Scaffold(
      floatingActionButton: ElevatedButton(
        onPressed: onPushFloatBtn,
        child: const Text('fetchBalances'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('mnem1: $mnemonics1'),
                Text('address1: ${wallet1.address.toFriendly()}'),
                Text('Balance: ${balance1.prettyBalance}'),
                Text(
                  'JettonBalance: ${jettonBalance1.prettyBalance} ${wallet1serviceJetton?.jettonOnChainMetadata.symbol ?? ''}',
                ),
                Wrap(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        // balance1 = await getBalance(wallet1);
                        balance1 = await wallet1service.fetchTonBalance();
                        setState(() {});
                      },
                      child: const Text('Update balance'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        wallet1service.createTransfer(
                          accessKey: key1,
                          message: 'Hello',
                          sendToBlockchain: true,
                          addressTo: wallet2service.tonWallet.address
                              .toString(),
                          amount: _toTransfer.toString(),
                        );
                      },
                      child: const Text('Transfer $_toTransfer ton'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          jettonBalance1 =
                              await wallet1serviceJetton
                                  ?.fetchJettonBalance() ??
                              0;
                          setState(() {});
                        } catch (e) {
                          debugPrint(
                            '💡wallet1serviceJetton.fetchJettonBalance :!: $e',
                          );
                        }
                      },
                      child: const Text('Update jetton balance'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          wallet1serviceJetton?.sendJettons(
                            key: key1,
                            message: 'Hello jetton',
                            amount: _toTransferJetton.toString(),
                            sendToBlockchain: true,
                            recipient: wallet2service.tonWallet.address,
                          );
                        } catch (e) {
                          debugPrint(
                            '💡wallet1serviceJetton.sendJettons :!: $e',
                          );
                        }
                      },
                      child: const Text('Transfer $_toTransferJetton jetton'),
                    ),
                  ],
                ),
                TextField(
                  controller: _addressTextController,
                  decoration: InputDecoration(label: Text('Address to send')),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountTextController,
                        decoration: InputDecoration(label: Text('Amount')),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          wallet1serviceJetton?.sendJettons(
                            key: key1,
                            amount:
                                (double.tryParse(_amountTextController.text) ??
                                        '0.01')
                                    .toString(),
                            recipient: TonAddress(_addressTextController.text),
                          );
                        } catch (e) {
                          debugPrint(
                            '💡wallet1serviceJetton.sendJettons :!: $e',
                          );
                        }
                      },
                      child: const Text('Send jetton'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          wallet1service.createTransfer(
                            accessKey: key1,
                            sendToBlockchain: true,
                            addressTo: _addressTextController.text,
                            amount:
                                (double.tryParse(_amountTextController.text) ??
                                        '0.01')
                                    .toString(),
                          );
                        } catch (e) {
                          debugPrint('💡send ton : $e');
                        }
                      },
                      child: const Text('Send TON'),
                    ),
                  ],
                ),
                // ElevatedButton(
                //     onPressed: () async {
                //       _mint();
                //     },
                //     child: const Text('Mint')),
                const Divider(),
                Text('mnem2: $mnemonics2'),
                Text('address2: ${wallet2.address.toFriendly()}'),
                Text('Balance: ${balance2.prettyBalance}'),
                Text(
                  'JettonBalance: ${jettonBalance2.prettyBalance} ${wallet2serviceJetton?.jettonOnChainMetadata.symbol ?? ''}',
                ),
                Wrap(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        balance2 = await wallet2service.fetchTonBalance();
                        setState(() {});
                        // wallet2service.tonWallet.deploy(
                        //     params: VersionedTransferParams(privateKey: key2),
                        //     rpc: rpc);
                      },
                      child: const Text('Update balance'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        wallet2service.createTransfer(
                          accessKey: key2,
                          addressTo: wallet1service.tonWallet.address
                              .toString(),
                          amount: _toTransfer.toString(),
                        );
                      },
                      child: const Text('Transfer $_toTransfer ton'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          jettonBalance2 =
                              await wallet2serviceJetton
                                  ?.fetchJettonBalance() ??
                              0;
                          setState(() {});
                        } catch (e) {
                          debugPrint(
                            '💡wallet2serviceJetton.fetchJettonBalance :!: $e',
                          );
                        }
                      },
                      child: const Text('Update jetton balance'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          wallet2serviceJetton?.sendJettons(
                            key: key2,
                            amount: _toTransferJetton.toString(),
                            recipient: wallet1service.tonWallet.address,
                          );
                        } catch (e) {
                          debugPrint(
                            '💡wallet2serviceJetton.sendJettons :!: $e',
                          );
                        }
                      },
                      child: const Text('Transfer $_toTransferJetton jetton'),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    final res = await wallet1service.fetchJettonMetadata(
                      selectedJetton.contractAddress,
                    ); // kabaCoinContractAddress
                    debugPrint('💡: res: $res');
                  },
                  child: const Text('Check master contract'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension IntTON on int {
  double get prettyBalance => this / 1000000000;
}
