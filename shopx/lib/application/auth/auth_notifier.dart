import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopx/domain/auth/user_model.dart';
import 'package:shopx/infrastructure/auth/auth_repositary.dart';
import 'auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🎯 AUTH NOTIFIER: Manages authentication state and business logic
class AuthNotifier extends Notifier<AuthState> {
  String? _tempToken;
  String? _selectedOtpMethod; // ✅ ADD: Store selected method
  String? _accessToken;
  String? _refreshToken;
  bool _hasInitialized = false;

  // @override
  // AuthState build() {
  //   _initAuth(); // async init
  //   return const AuthState(isInitializing: true); // 🔥 IMPORTANT
  // }

  @override
  AuthState build() {
    if (!_hasInitialized) {
      _hasInitialized = true;
      _initAuth();
    }

    return const AuthState(isInitializing: true);
  }

  // final storedToken = await _loadToken();

  // if (storedToken == null) {
  //   state = const AuthState.unauthenticated(); // init DONE
  //   return;
  // }

  // try {
  //   final user = await ref
  //       .read(authRepositoryProvider)
  //       .getCurrentUser(storedToken);

  //   _jwtToken = storedToken;
  //   state = AuthState.authenticated(user, token: storedToken);
  //   //  } catch (_) {
  //   //   // Internet OFF → do nothing
  //   //   // Keep state as initializing
  //   //   return;
  //   // }
  // } catch (_) {
  //   // Token expired / invalid / rejected
  //   _jwtToken = null;
  //   await _clearToken();

  //   state = const AuthState.unauthenticated(); // 🔴 EXIT SPLASH
  //   return;
  // }

  Future<void> _initAuth() async {
    try {
      await _loadTokens();

      if (_accessToken == null && _refreshToken == null) {
        state = const AuthState.unauthenticated();
        return;
      }

      // ── Fast path: restore user from local storage immediately ──────────
      // This avoids a network round-trip on every startup/hot-restart so the
      // user lands on the dashboard instantly. The token is still validated
      // in the background via getCurrentUser.
      final cachedUser = await _loadUser();
      if (cachedUser != null && _accessToken != null) {
        state = AuthState.authenticated(cachedUser);
        // Silently refresh user data in the background; don't block the UI.
        _refreshUserInBackground();
        return;
      }

      // ── Slow path: no cached user — validate token over the network ─────
      if (_accessToken != null) {
        try {
          final user = await ref
              .read(authRepositoryProvider)
              .getCurrentUser(_accessToken!)
              .timeout(const Duration(seconds: 4));

          await _saveUser(user);
          state = AuthState.authenticated(user);
          return;
        } catch (_) {
          if (_refreshToken != null) {
            await _refreshTokenAndRecover();
            return;
          }
        }
      }

      if (_refreshToken != null) {
        await _refreshTokenAndRecover();
        return;
      }

      state = const AuthState.unauthenticated();
    } finally {
      // 🔒 ABSOLUTE GUARANTEE: splash can NEVER be infinite
      if (state.isInitializing) {
        state = const AuthState.unauthenticated();
      }
    }
  }

  /// Silently fetches fresh user data after restoring from cache.
  /// Updates state if successful; ignores network errors.
  Future<void> _refreshUserInBackground() async {
    if (_accessToken == null) return;
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .getCurrentUser(_accessToken!)
          .timeout(const Duration(seconds: 6));
      await _saveUser(user);
      if (state.isAuthenticated) {
        state = AuthState.authenticated(user);
      }
    } catch (_) {
      // Network error — keep using cached user, user stays logged in.
    }
  }

  // 🔥 LOCAL TOKEN + USER STORAGE (SharedPreferences)
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("access_token", accessToken);
    await prefs.setString("refresh_token", refreshToken);
  }

  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("user_id", user.id);
    await prefs.setString("user_username", user.username);
    await prefs.setString("user_email", user.email);
    await prefs.setString("user_type", user.userType);
    await prefs.setString("user_phone", user.phone);
  }

  Future<UserModel?> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt("user_id");
    final username = prefs.getString("user_username");
    final userType = prefs.getString("user_type");
    if (id == null || username == null || userType == null) return null;
    return UserModel(
      id: id,
      username: username,
      email: prefs.getString("user_email") ?? "",
      userType: userType,
      phone: prefs.getString("user_phone") ?? "",
      token: "",
    );
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString("access_token");
    _refreshToken = prefs.getString("refresh_token");
  }

  Future<void> _clearAllTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("access_token");
    await prefs.remove("refresh_token");
    await prefs.remove("user_id");
    await prefs.remove("user_username");
    await prefs.remove("user_email");
    await prefs.remove("user_type");
    await prefs.remove("user_phone");
  }

  // 🔐 LOGIN: Authenticate user with username and password

  Future<void> loginUser(String username, String password) async {
    // state = const AuthState.loading();
    state = AuthState.loading(user: state.user);

    try {
      final result = await ref
          .read(authRepositoryProvider)
          .loginUser(username, password);

      final user = result['user'] as UserModel;

      final accessToken = result['accessToken'] as String;
      final refreshToken = result['refreshToken'] as String;

      _accessToken = accessToken;
      _refreshToken = refreshToken;

      await _saveTokens(accessToken, refreshToken);
      await _saveUser(user);

      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> loginAdmin(String username, String password) async {
    // state = const AuthState.loading();
    state = AuthState.loading(user: state.user);

    try {
      final result = await ref
          .read(authRepositoryProvider)
          .loginAdmin(username, password);

      final user = result['user'] as UserModel;

      final accessToken = result['accessToken'] as String;
      final refreshToken = result['refreshToken'] as String;

      _accessToken = accessToken;
      _refreshToken = refreshToken;

      await _saveTokens(accessToken, refreshToken);
      await _saveUser(user);

      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // 👤 REGISTER: Create new admin user (admin-only)
  Future<void> register(
    String username,
    String email,
    String password,
    String phone,
    String adminToken,
  ) async {
    // state = const AuthState.loading();
    state = AuthState.loading(user: state.user);

    try {
      // ✅ UPDATED: Get result with both user and token
      final result = await ref
          .read(authRepositoryProvider)
          .register(username, email, password, phone, adminToken);

      final user = result['user'] as UserModel;
      final accessToken = result['accessToken'] as String;
      final refreshToken = result['refreshToken'] as String;

      _accessToken = accessToken;
      _refreshToken = refreshToken;

      await _saveTokens(accessToken, refreshToken);
      await _saveUser(user);

      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> getCurrentUser() async {
    if (_accessToken == null) {
      state = const AuthState.unauthenticated();
      return;
    }

    state = AuthState.loading(user: state.user);

    try {
      final user = await ref
          .read(authRepositoryProvider)
          .getCurrentUser(_accessToken!);

      state = AuthState.authenticated(user);
    } catch (_) {
      // Do NOT logout on network error
      if (_refreshToken != null) {
        await _refreshTokenAndRecover();
      }
      // else: do nothing, keep current state
    }
  }

  // 🚪 LOGOUT: Clear user data and return to unauthenticated state
  Future<void> logout() async {
    try {
      if (_refreshToken != null) {
        await ref.read(authRepositoryProvider).logout(_refreshToken!);
      }
    } catch (_) {
      // ignore backend failure
    }

    _accessToken = null;
    _refreshToken = null;
    _tempToken = null;
    _selectedOtpMethod = null;

    await _clearAllTokens();
    state = const AuthState.unauthenticated();
  }

  Future<void> updateProfile(
    Map<String, dynamic> userData, // ✅ REMOVED token parameter
  ) async {
    if (_accessToken == null) {
      state = AuthState.error("Not authenticated");
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final updatedUser = await ref
          .read(authRepositoryProvider)
          .updateUser(_accessToken!, userData); // ✅ Use stored token
      await _saveUser(updatedUser);
      state = AuthState.authenticated(updatedUser); // ✅ Keep token
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteAccount() async {
    // ✅ REMOVED token parameter
    if (_accessToken == null) {
      state = AuthState.error("Not authenticated");
      return;
    }

    // state = const AuthState.loading();
    state = AuthState.loading(user: state.user);

    try {
      await ref
          .read(authRepositoryProvider)
          .deleteUser(_accessToken!); // ✅ Use stored token
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // 🔑 STEP 1: Login owner and get TEMP token
  Future<void> loginOwner(String username, String password) async {
    // state = const AuthState.loading();
    state = AuthState.loading(user: state.user);

    try {
      _tempToken = await ref
          .read(authRepositoryProvider)
          .loginOwner(username, password);
      state = const AuthState.unauthenticated(); // Not authenticated yet
      // state = const AuthState.initial();
    } catch (e) {
      state = AuthState.error(e.toString());
      throw e; // ✅ THIS LINE IS MANDATORY
    }
  }

  // 📱 STEP 2: Send OTP via any method (Email, WhatsApp, SMS, Missed Call)
  Future<void> sendOTP(String method) async {
    if (_tempToken == null) {
      state = AuthState.error("Please login first");
      return;
    }

    _selectedOtpMethod = method; // ✅ Store the method being used
    // state = state.copyWith(isLoading: true);
    state = state.copyWith(isLoading: true, isInitializing: false);

    try {
      await ref.read(authRepositoryProvider).sendOTP(_tempToken!, method);
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ✅ STEP 3: Verify OTP (works for ALL methods)
  // Future<void> verifyOTP(String otp) async {
  //   if (_tempToken == null) {
  //     state = AuthState.error("Session expired. Please login again");
  //     return;
  //   }

  //   state = const AuthState.loading();

  //   try {
  //     // ✅ FIX: Get BOTH user AND token
  //     final result = await ref
  //         .read(authRepositoryProvider)
  //         .verifyOTP(_tempToken!, otp);

  //     // ✅ Extract both values from result
  //     final user = result['user'] as UserModel;
  //     final permanentToken = result['token'] as String;

  //     // ✅ Store the permanent token
  //     _jwtToken = permanentToken;
  //     _tempToken = null; // Clear temp token after success
  //     _selectedOtpMethod = null; // Clear method after success
  //     await _saveToken(permanentToken); // 🔥 save token
  //     state = AuthState.authenticated(user, token: permanentToken);
  //   } catch (e) {
  //     state = AuthState.error(e.toString());
  //   }
  // }

  Future<bool> verifyOTP(String otp) async {
    if (_tempToken == null) {
      state = AuthState.error("Session expired. Please login again");
      return false;
    }

    // state = const AuthState.loading();
    state = AuthState.loading(user: state.user);

    try {
      final result = await ref
          .read(authRepositoryProvider)
          .verifyOTP(_tempToken!, otp);

      // ✅ CORRECT OTP
      final user = result['user'] as UserModel;

      final accessToken = result['accessToken'] as String;
      final refreshToken = result['refreshToken'] as String;

      _accessToken = accessToken;
      _refreshToken = refreshToken;

      _tempToken = null;
      _selectedOtpMethod = null;

      await _saveTokens(accessToken, refreshToken);
      await _saveUser(user);

      state = AuthState.authenticated(user);

      return true;
    } catch (e) {
      // ❌ WRONG OTP or server error
      state = AuthState.error("Incorrect OTP");
      return false;
    }
  }

  // 🧹 CLEAR ERROR: Clear any error message
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  // 🔁 Re-run auth initialization (used when internet comes back)
 // 🔁 Re-run auth initialization (used when internet comes back)
void retryAuth() {
  // Don't retry if already initializing
  if (state.isInitializing) return;
  
  // Don't retry if we don't have any stored tokens
  if (_accessToken == null && _refreshToken == null) {
    state = const AuthState.unauthenticated();
    return;
  }
  
  // Reset to initializing state and retry
  state = state.copyWith(isInitializing: true);
  _initAuth();
}

  Future<void> _refreshTokenAndRecover() async {
    if (_refreshToken == null) {
      await _clearAllTokens();
      state = const AuthState.unauthenticated();
      return;
    }

    try {
      final result = await ref
          .read(authRepositoryProvider)
          .refreshToken(_refreshToken!);

      _accessToken = result['accessToken'];
      _refreshToken = result['refreshToken'];

      await _saveTokens(_accessToken!, _refreshToken!);

      final user = await ref
          .read(authRepositoryProvider)
          .getCurrentUser(_accessToken!)
          .timeout(const Duration(seconds: 4));

      await _saveUser(user);
      state = AuthState.authenticated(user);
    } catch (e) {
      await _clearAllTokens();
      state = const AuthState.unauthenticated();
    }
  }

  bool get hasLocalSession => _accessToken != null || _refreshToken != null;
  String? get accessToken => _accessToken;

}

// 🎯 PROVIDER: Makes AuthNotifier available throughout the app
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
