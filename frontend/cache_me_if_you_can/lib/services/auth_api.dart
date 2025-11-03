import 'package:cloud_functions/cloud_functions.dart';

class CreateUserRequest {
  final String name;
  final int age;
  final String gender; // e.g., 'male' | 'female' | 'other'
  final String email;
  final String password;
  final double height; // cm or inches depending on backend
  final double weight; // kg or lbs depending on backend
  final String? allergies; // comma-separated or free text
  final double activityLevel; // numeric as required by backend

  CreateUserRequest({
    required this.name,
    required this.age,
    required this.gender,
    required this.email,
    required this.password,
    required this.height,
    required this.weight,
    this.allergies,
    required this.activityLevel,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'gender': gender,
    'email': email,
    'password': password,
    'height': height,
    'weight': weight,
    'allergies': allergies ?? '',
    'activity_level': activityLevel,
  };
}

class CreateUserResponse {
  final String message;
  final String uid;
  final Map<String, dynamic>? user;

  CreateUserResponse({required this.message, required this.uid, this.user});
}

class AuthApi {
  final FirebaseFunctions _functions;
  AuthApi({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  /// Calls the HTTPS Callable function named 'createUser'. Ensure your backend
  /// exports this function and your emulator/production settings are configured
  /// (see main.dart for emulator wiring).
  Future<CreateUserResponse> createUser(CreateUserRequest req) async {
    final callable = _functions.httpsCallable('createUser');
    final result = await callable.call(req.toJson());
    final data = (result.data as Map).cast<String, dynamic>();
    return CreateUserResponse(
      message: data['message']?.toString() ?? 'User created',
      uid: data['uid']?.toString() ?? '',
      user: data['user'] is Map
          ? (data['user'] as Map).cast<String, dynamic>()
          : null,
    );
  }
}
