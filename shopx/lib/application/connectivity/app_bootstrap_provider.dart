import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shopx/application/auth/auth_notifier.dart';
import 'package:shopx/application/connectivity/connectivity_provider.dart';

enum AppBootstrapState {
  offline,
  ready,
}



final appBootstrapProvider = Provider<AppBootstrapState>((ref) {
  final connectivity = ref.watch(connectivityProvider);

  return connectivity.when(
    loading: () => AppBootstrapState.ready, // ⛔ NEVER splash here
    error: (_, __) => AppBootstrapState.offline,
    data: (isOnline) {
      return isOnline
          ? AppBootstrapState.ready
          : AppBootstrapState.offline;
    },
  );
});

// 🔥 CRITICAL FIX: ADD THIS PROVIDER
final authRetryOnConnectivityProvider = Provider((ref) {
  ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
    next.whenData((isOnline) {
      if (isOnline && previous?.value == false) {
        // Only when internet comes BACK online (was offline)
        final authNotifier = ref.read(authNotifierProvider.notifier);
        final authState = ref.read(authNotifierProvider);
        
        // Check if we have tokens but aren't authenticated
        if (authNotifier.hasLocalSession && !authState.isAuthenticated) {
          // Give a small delay for network stabilization
          Future.delayed(const Duration(milliseconds: 300), () {
            authNotifier.retryAuth();
          });
        }
      }
    });
  });
});