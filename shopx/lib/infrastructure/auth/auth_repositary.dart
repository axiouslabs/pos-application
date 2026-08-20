import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopx/domain/auth/user_model.dart';
import 'package:shopx/infrastructure/auth/auth_api.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(authApiProvider));
});

class AuthRepository {
  final AuthApi _api;

  AuthRepository(this._api);

  // 🔐 LOGIN: Authenticate user and get user data AND token
  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    try {
      final response = await _api.loginUser(username, password);

      final user = UserModel.fromJson(response["user"]);

      final accessToken = response["accessToken"];
      final refreshToken = response["refreshToken"];

      if (accessToken == null || refreshToken == null) {
        throw Exception("Tokens missing after user login");
      }

      return {
        'user': user,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };
    } catch (e) {
      rethrow; // 🔥 DO NOT WRAP
    }
  }

  Future<Map<String, dynamic>> loginAdmin(
    String username,
    String password,
  ) async {
    try {
      final response = await _api.loginAdmin(username, password);

      final user = UserModel.fromJson(response["user"]);

      final accessToken = response["accessToken"];
      final refreshToken = response["refreshToken"];

      if (accessToken == null || refreshToken == null) {
        throw Exception("Tokens missing after admin login");
      }

      return {
        'user': user,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };
    } catch (e) {
      rethrow; // 🔥 DO NOT WRAP
    }
  }

  // 👤 REGISTER: Create new admin user (admin-only operation)
  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
    String phone,
    String adminToken,
  ) async {
    final response = await _api.register(
      username,
      email,
      password,
      phone,
      adminToken,
    );

    // Extract user data
    final userJson = response["user"];
    final user = UserModel.fromJson(userJson);

    final accessToken = response["accessToken"];
    final refreshToken = response["refreshToken"];

    if (accessToken == null || refreshToken == null) {
      throw 'INVALID_AUTH_RESPONSE';
    }

    return {
      'user': user,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  // 🔍 GET CURRENT USER: Fetch logged-in user's profile
  Future<UserModel> getCurrentUser(String token) async {
    try {
      final response = await _api.current(token);
      return UserModel.fromJson(response);
    } catch (e) {
      rethrow; // IMPORTANT: let notifier decide
    }
  }

  // ✏️ UPDATE USER: Update user profile information
  Future<UserModel> updateUser(
    String token,
    Map<String, dynamic> userData,
  ) async {
    final response = await _api.updateUser(token, userData);
    // Response: { "message": "...", "user": { ... } } or direct user object
    final userJson = response["user"] ?? response;
    return UserModel.fromJson(userJson);
  }

  // 🗑️ DELETE USER: Delete current user's account
  Future<void> deleteUser(String token) async {
    await _api.deleteUser(token);
    // No return needed - just confirmation it succeeded
  }

  // 📱 SEND OTP: Send OTP for verification (SMS/Email)
  Future<void> sendOTP(String token, String method) async {
    await _api.sendOTP(token, method);
    // No return needed - just confirmation it succeeded
  }

  // ✅ VERIFY OTP: Verify OTP code and get user data AND token
  // Future<Map<String, dynamic>> verifyOTP(String token, String otp) async {
  //   final response = await _api.verifyOTP(token, otp);

  //   // Extract user data
  //   final userJson = response["user"] ?? response;
  //   final user = UserModel.fromJson(userJson);

  //   // Extract token from response- LOOK FOR accessToken
  //   final permanentToken = response["accessToken"] as String?;

  //   if (permanentToken == null) {
  //     throw Exception('No token received after OTP verification');
  //   }

  //   // ✅ Return BOTH user and token
  //   return {'user': user, 'token': permanentToken};
  // }

  Future<Map<String, dynamic>> verifyOTP(String token, String otp) async {
    final response = await _api.verifyOTP(token, otp);

    final userJson = response["user"];
    final user = UserModel.fromJson(userJson);

    final accessToken = response["accessToken"];
    final refreshToken = response["refreshToken"];

    if (accessToken == null || refreshToken == null) {
      throw 'INVALID_AUTH_RESPONSE';
    }

    return {
      'user': user,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  // 👥 GET ALL USERS: Admin-only - get list of all users
  Future<List<UserModel>> getAllUsers(String token) async {
    final response = await _api.getAllUsers(token);
    // Response: { "message": "...", "users": [...] }
    final usersList = response["users"] as List;
    return usersList.map((userJson) => UserModel.fromJson(userJson)).toList();
  }

  // 🔑 LOGIN OWNER: Special login for admin/owner
  Future<String> loginOwner(String username, String password) async {
    final response = await _api.loginOwner(username, password);
    // Response: { "tempToken": "..." } - we need to return just the token

    return response["tempToken"] as String;
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _api.refreshToken(refreshToken);

    final accessToken = response["accessToken"];
    final newRefreshToken = response["refreshToken"];

    if (accessToken == null || newRefreshToken == null) {
      throw 'SESSION_EXPIRED';
    }

    return {'accessToken': accessToken, 'refreshToken': newRefreshToken};
  }


    // 🚪 LOGOUT: Invalidate refresh token on backend
  Future<void> logout(String refreshToken) async {
    await _api.logout(refreshToken);
  }

  // ================= FORGOT PASSWORD =================

  Future<String> forgotPassword(String username) async {
    final response = await _api.forgotPassword(username);
    return response["tempToken"] as String;
  }

  Future<String> verifyResetOTP(String token, String otp) async {
    final response = await _api.verifyResetOTP(token, otp);
    return response["resetToken"] as String;
  }

  Future<void> resetPassword(String token, String newPassword) async {
    await _api.resetPassword(token, newPassword);
  }
}
