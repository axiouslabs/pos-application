// import 'package:shopx/domain/auth/user_model.dart';

// class AuthState {
//   final UserModel? user;
//   final String? token;
  
//   final bool isLoading;
//   final bool isInitializing; // ⭐ ADD THIS
//   final String? error;
  

//    const AuthState({
//     this.user,
//      this.token,  // ✅ NEW
//     this.isLoading = false,
//     this.isInitializing = true, // ⭐ DEFAULT TRUE
//     this.error,
//   });

//   // 1. 🆕 INITIAL STATE: App just started, no user data yet
//   const AuthState.initial()
//       : user = null,
//         token = null,  // ✅ NEW
//         isLoading = false,
//           isInitializing = true, // ✅ MUST BE TRUE
//         error = null;

//        // 2. 🔄 LOADING STATE: Login/Register operation in progress, show spinner
// const AuthState.loading({
//   UserModel? user,
//   String? token,
// })
//   : user = user,
//     token = token,
//     isLoading = true,
//     isInitializing = false,
//     error = null;


//       // 3. ✅ AUTHENTICATED STATE: User successfully logged in, store user data
//   const AuthState.authenticated(UserModel user,{String?token})
//       : user = user,
//         token = token,  // ✅ NEW
//         isLoading = false,
//          isInitializing = false, // ⭐ DONE INITIALIZING
//         error = null;


//      // 4. ❌ UNAUTHENTICATED STATE: User logged out or not logged in yet
//   const AuthState.unauthenticated()
//       : user = null,
//          token = null,  // ✅ NEW - Clear token on logout
//         isLoading = false,
//         isInitializing = false, // ⭐ DONE INITIALIZING
//         error = null;

//      // 5. ⚠️ ERROR STATE: Something went wrong, show error message to user
//   const AuthState.error(
//   String error, {
//   UserModel? user,
//   String? token,
// })
//     : user = user,
//       token = token,
//       isLoading = false,
//       isInitializing = false,
//       error = error;


              
//   // 📊 Copy with method for easy state updates
//  AuthState copyWith({
//   UserModel? user,
//   String? token,
//   bool? isLoading,
//   bool? isInitializing, // ⭐ ADD
//   String? error,
// }) {
//   return AuthState(
//     user: user ?? this.user,
//     token: token ?? this.token,
//     isLoading: isLoading ?? this.isLoading,
//     isInitializing: isInitializing ?? this.isInitializing, // ⭐
//     error: error ?? this.error,
//   );
// }


//      // 📋 Equality check for state comparison
//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is AuthState &&
//         other.user == user &&
//          other.token == token &&  // ✅ NEW
//         other.isLoading == isLoading &&
//         other.isInitializing == isInitializing && // ✅ ADD
//         other.error == error;
//   }

//   @override
//   int get hashCode => user.hashCode ^ token.hashCode ^  isLoading.hashCode ^  isInitializing.hashCode ^  error.hashCode;

//   // 🖨️ String representation for debugging
//   @override
//   String toString() => 'AuthState(user: $user, isLoading: $isLoading, error: $error)';  
  
       

// }

// extension AuthStateHelpers on AuthState {
//   bool get isAuthenticated => user != null;  // logged in if user exists
  
//   // bool get isUnauthenticated =>
//   //   user == null && !isLoading && !isInitializing;

// }



import 'package:shopx/domain/auth/user_model.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isInitializing;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isInitializing = true,
    this.error,
  });

  const AuthState.initial()
      : user = null,
        isLoading = false,
        isInitializing = true,
        error = null;

  const AuthState.loading({UserModel? user})
      : user = user,
        isLoading = true,
        isInitializing = false,
        error = null;

  const AuthState.authenticated(UserModel user)
      : user = user,
        isLoading = false,
        isInitializing = false,
        error = null;

  const AuthState.unauthenticated()
      : user = null,
        isLoading = false,
        isInitializing = false,
        error = null;

  const AuthState.error(
    String error, {
    UserModel? user,
  })  : user = user,
        isLoading = false,
        isInitializing = false,
        error = error;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isInitializing,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error ?? this.error,
    );
  }

  bool get isAuthenticated => user != null;
}
