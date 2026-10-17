import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:namaz_alert/core/constants/app_constants.dart';
import 'package:namaz_alert/core/routes/app_routes.dart';
import 'package:namaz_alert/features/auth/model/user_model.dart';

class AuthController extends GetxController {
  final _storage = GetStorage();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserFromStorage();
  }

  void _loadUserFromStorage() {
    final userData = _storage.read<Map<String, dynamic>>(AppConstants.keyUser);
    if (userData != null) {
      currentUser.value = UserModel.fromJson(userData);
    }
  }

  bool get isLoggedIn => currentUser.value != null;

  /// Register with email & password (Firebase will be wired here later)
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // TODO: Replace with Firebase Auth
      await Future.delayed(const Duration(seconds: 1)); // simulate network

      final user = UserModel(
        uid: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );

      _saveUser(user);
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      errorMessage.value = 'Registration failed. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Login with email & password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // TODO: Replace with Firebase Auth
      await Future.delayed(const Duration(seconds: 1));

      final user = UserModel(
        uid: 'user_${email.hashCode}',
        name: email.split('@').first,
        email: email,
        createdAt: DateTime.now(),
      );

      _saveUser(user);
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      errorMessage.value = 'Login failed. Check your credentials.';
    } finally {
      isLoading.value = false;
    }
  }

  void _saveUser(UserModel user) {
    currentUser.value = user;
    _storage.write(AppConstants.keyUser, user.toJson());
  }

  void logout() {
    currentUser.value = null;
    _storage.remove(AppConstants.keyUser);
    Get.offAllNamed(AppRoutes.login);
  }
}
