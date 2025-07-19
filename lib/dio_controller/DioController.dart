import 'package:dio/dio.dart';

class DioController {
  // Singleton instance
  static final DioController _instance = DioController._internal();
  factory DioController() => _instance;
  DioController._internal() {
    _initDios();
  }

  late Dio modelServer;
  late Dio authServer;

  final String _modelBaseUrl = 'https://6qp6wdgn-8000.inc1.devtunnels.ms';
  final String _authBaseUrl = 'https://zhmx7x9x-5000.inc1.devtunnels.ms';

  void _initDios() {
    modelServer = Dio(
      BaseOptions(
        baseUrl: _modelBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
      ),
    );

    authServer = Dio(
      BaseOptions(
        baseUrl: _authBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
      ),
    );

    final retryInterceptor = InterceptorsWrapper(
      onError: (DioException e, ErrorInterceptorHandler handler) async {
        final requestOptions = e.requestOptions;

        // Retry only for GET/POST requests (you can customize)
        if (requestOptions.extra["retries"] == null) {
          requestOptions.extra["retries"] = 0;
        }

        if (requestOptions.extra["retries"] < 2) {
          requestOptions.extra["retries"] += 1;
          try {
            final clone = await Dio().fetch(requestOptions);
            return handler.resolve(clone);
          } catch (err) {
            return handler.next(err as DioException);
          }
        }

        return handler.next(e);
      },
    );

    modelServer.interceptors.addAll([
      LogInterceptor(responseBody: true),
      retryInterceptor,
    ]);

    authServer.interceptors.addAll([
      LogInterceptor(responseBody: true),
      retryInterceptor,
    ]);
  }
}
