import 'package:flutter/foundation.dart';
import '../models/user.dart';

/// Authentication tokens
class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}

/// Authentication response data
class AuthData {
  final User user;
  final AuthTokens tokens;
  final bool? emailSent;

  AuthData({
    required this.user,
    required this.tokens,
    this.emailSent,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('🔍 Parsing tokens...');
      final tokens = AuthTokens.fromJson(json['tokens']);
      debugPrint('✅ Tokens parsed');
      
      debugPrint('🔍 Parsing user...');
      final user = User.fromJson(json['user']);
      debugPrint('✅ User parsed');
      
      return AuthData(
        user: user,
        tokens: tokens,
        emailSent: json['emailSent'],
      );
    } catch (e) {
      debugPrint('❌ AuthData parsing error: $e');
      debugPrint('❌ Error at: ${e.toString().substring(0, 200)}');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'tokens': tokens.toJson(),
      if (emailSent != null) 'emailSent': emailSent,
    };
  }
}

/// Authentication response
class AuthResponse {
  final bool success;
  final AuthData data;
  final String? message;

  AuthResponse({
    required this.success,
    required this.data,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      data: AuthData.fromJson(json['data']),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.toJson(),
      'message': message,
    };
  }
}

/// Refresh token response
class RefreshTokenResponse {
  final String accessToken;

  RefreshTokenResponse({
    required this.accessToken,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      accessToken: json['accessToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
    };
  }
}

/// Login request
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

/// Register request
class RegisterRequest {
  final String email;
  final String password;
  final String name;
  final String? phoneNumber;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.name,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }
}

/// Password reset request
class PasswordResetRequest {
  final String email;

  PasswordResetRequest({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

/// Change password request
class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
  }
}
