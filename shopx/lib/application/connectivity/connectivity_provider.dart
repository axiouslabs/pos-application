import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The base URL of your server — used to verify actual reachability
// const _serverUrl = "http://10.114.76.32:5050/api/";
const _serverUrl = "http://sellops.cloud:5000/api/";
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  Future<bool> hasInternet() async {
    try {
      final dio = Dio();
      // Just ping the server root — we only care about getting a response, any status is fine
      await dio.get(
        _serverUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
          validateStatus: (_) => true, // Accept any HTTP status as "reachable"
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // 1️⃣ Initial check
  final connectivityResult = await connectivity.checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    yield false;
  } else {
    yield await hasInternet();
  }

  // 2️⃣ Listen for changes
  await for (final result in connectivity.onConnectivityChanged) {
    if (result == ConnectivityResult.none) {
      yield false;
    } else {
      yield await hasInternet();
    }
  }
});
