import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:tr_logger/tr_logger.dart';

/// HTTPProvider class implements TonServiceProvider interface
/// for handling HTTP requests to TonApi and TonCenter.
///
/// Meant to be long-lived: create it once and share it, so that the http client
/// keeps its connections alive between requests. The `Authorization` header
/// is not stored in the instance - `getAuthorization` is called on every
/// request.
/// The provider never closes the http client, that is up to its owner.
class TonHTTPProvider with TonServiceProvider {
  /// HTTPProvider class implements TonServiceProvider interface
  /// for handling HTTP requests to TonApi and TonCenter.
  TonHTTPProvider({
    required this.tonApiUrl,
    required this.tonCenterUrl,
    this.api = TonApiType.tonApi,
    http.Client? client,
    String? tonApiKey,
    String? Function()? getAuthorization,
    this.defaultRequestTimeout = const Duration(seconds: 10),
    TRLogger? logger,
  }) : client = client ?? http.Client(),
       logger = logger ?? InAppLogger(),
       _tonApiKey = tonApiKey,
       _getAuthorization = getAuthorization;

  /// API for REST
  final String? tonApiUrl;

  /// API for gRPC
  final String? tonCenterUrl;

  /// http.Client
  @protected
  final http.Client client;

  /// Request timeout
  final Duration defaultRequestTimeout;

  /// Logger
  @protected
  final TRLogger logger;

  final String? _tonApiKey;

  /// Current `Authorization` header value with its scheme (`Bearer …`,
  /// `DPoP …`): null or empty - no Authorization header
  final String? Function()? _getAuthorization;

  static const String _name = 'TonHTTPProvider';

  @override
  final TonApiType api;

  @override
  Future<TonServiceResponse> doRequest(
    TonRequestDetails params, {
    Duration? timeout,
  }) async {
    final uri = params.api == TonApiType.tonApi
        ? params.encodeUrl(tonApiUrl!)
        : params.encodeUrl(tonCenterUrl!);
    final authorization = _getAuthorization?.call();
    final headers = <String, String>{
      'Accept': 'application/json',
      if (_tonApiKey != null) 'api_key': _tonApiKey,
      if (authorization != null && authorization.isNotEmpty)
        'Authorization': authorization,
      'Content-Type': 'application/json',
      ...params.headers,
    };
    if (params.requestMethod.isPost) {
      final response = await client
          .post(uri, headers: headers, body: params.encodeBody())
          .timeout(timeout ?? defaultRequestTimeout);
      logger.logInfoMessage(
        _name,
        'POST: request: ${response.request}, response: ${response.body}',
      );
      return params.toResponse(
        response.bodyBytes,
        statusCode: response.statusCode,
      );
    }
    final response = await client
        .get(uri, headers: headers)
        .timeout(timeout ?? defaultRequestTimeout);
    logger.logInfoMessage(
      _name,
      'GET: request: ${response.request}, response: ${response.body}',
    );
    return params.toResponse(
      response.bodyBytes,
      statusCode: response.statusCode,
    );
  }
}
