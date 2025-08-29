/// Support class for JettonOnChainMetadata.snakeFormat
class JettonContent {
  /// Support class for JettonOnChainMetadata.snakeFormat
  const JettonContent({
    required this.decimals,
    required this.description,
    required this.image,
    required this.name,
    required this.symbol,
  });

  /// Returns [JettonContent] or throws
  factory JettonContent.fromJson(Map<String, dynamic> json) {
    return JettonContent(
      decimals: int.tryParse(json['decimals'].toString()) ?? 0,
      description: (json['description'] ?? '') as String,
      image: (json['image'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      symbol: (json['symbol'] ?? '') as String,
    );
  }

  /// Decimals
  final int decimals;

  /// Description
  final String description;

  /// Image for coin
  final String image;

  /// Coin name
  final String name;

  /// Coin symbol
  final String symbol;

  /// Correct model
  bool get isValid =>
      image.isNotEmpty && name.isNotEmpty && symbol.isNotEmpty && decimals > 0;

  @override
  String toString() =>
      'decimals: $decimals, description: $description, image: $image,'
      ' name: $name, symbol: $symbol';
}
