// lib/data/models/auth/login_response.dart
import 'user_model.dart';

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel? user; // ✅ nullable

  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null, // ✅ don't crash if missing
    );
  }
}