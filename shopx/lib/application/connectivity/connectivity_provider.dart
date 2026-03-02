
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
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






















//   for flutter web
// import 'dart:async';
// import 'dart:io';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// final connectivityProvider = StreamProvider<bool>((ref) async* {
//   // 🔥 TEMP FIX FOR FLUTTER WEB
//   if (kIsWeb) {
//     yield true;
//     return;
//   }

//   final connectivity = Connectivity();

//   Future<bool> hasInternet() async {
//     try {
//       final result = await InternetAddress.lookup('google.com')
//           .timeout(const Duration(seconds: 2));
//       return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
//     } catch (_) {
//       return false;
//     }
//   }

//   // 1️⃣ Initial check
//   final connectivityResult = await connectivity.checkConnectivity();
//   if (connectivityResult == ConnectivityResult.none) {
//     yield false;
//   } else {
//     yield await hasInternet();
//   }

//   // 2️⃣ Listen for changes
//   await for (final result in connectivity.onConnectivityChanged) {
//     if (result == ConnectivityResult.none) {
//       yield false;
//     } else {
//       yield await hasInternet();
//     }
//   }
// });
