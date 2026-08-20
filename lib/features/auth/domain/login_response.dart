import 'app_user.dart';

class LoginResponse {
  const LoginResponse({
    required this.message,
    required this.user,
    required this.token,
  });

  final String message;
  final AppUser user;
  final String token;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final message = json['message'];
    final data = json['data'];
    if (message is! String || data is! Map<String, dynamic>) {
      throw const FormatException('Invalid login payload.');
    }

    final userJson = data['user'];
    final token = data['token'];
    if (userJson is! Map<String, dynamic> ||
        token is! String ||
        token.trim().isEmpty) {
      throw const FormatException('Invalid login data.');
    }

    return LoginResponse(
      message: message,
      user: AppUser.fromJson(userJson),
      token: token,
    );
  }
}
