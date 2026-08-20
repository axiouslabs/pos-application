import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopx/application/auth/auth_notifier.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
     
      baseUrl: "http://sellops.cloud:5000/api/", // Aws production
    // baseUrl: "http://10.114.76.32:5050/api/",
    
    // baseUrl: "http://10.0.2.2:5050/api/", // Local backend via Android emulator


      connectTimeout: Duration(seconds: 20),
      receiveTimeout: Duration(seconds: 20),
      headers: {
        "Content-Type": "application/json",
        //  "ngrok-skip-browser-warning": "true",
      },
    ),
  );
dio.interceptors.add(
  InterceptorsWrapper( 
    onRequest: (options, handler) {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final token = authNotifier.accessToken;

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      return handler.next(options);
    },
    onError: (error, handler) {
      // Optional: helpful debug
      // print('Dio error: ${error.response?.statusCode}');
      return handler.next(error);
    },
  ),
);



  return dio;
});




