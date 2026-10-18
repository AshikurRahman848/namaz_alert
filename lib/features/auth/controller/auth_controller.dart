import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:namaz_alert/core/firebase/firestore_instance.dart';
import 'package:namaz_alert/core/routes/app_routes.dart';
import 'package:namaz_alert/core/services/fcm_service.dart';
import 'package:namaz_alert/features/auth/model/user_model.dart';

class AuthController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _firestore = AppFirestore.instance;
  final _storage = GetStorage();
  final _googleSignIn = GoogleSignIn();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to Firebase auth state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      currentUser.value = null;
    } else {
      // Load user profile from Firestore
      await _loadUserProfile(firebaseUser.uid);
    }
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        currentUser.value = UserModel.fromJson(doc.data()!);
        return;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Load user profile error: $e');
    }

    // If Firestore document doesn't exist or load failed, build from Firebase Auth
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      final user = UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ??
            (firebaseUser.email?.isNotEmpty == true
                ? firebaseUser.email!.split('@').first
                : 'User'),
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
        groupIds: const [],
        createdAt: DateTime.now(),
        fcmToken: FcmService.currentToken,
      );
      currentUser.value = user;
      try {
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(user.toJson(), SetOptions(merge: true));
      } catch (e) {
        // ignore: avoid_print
        print('Error saving fallback user to firestore: $e');
      }
    }
  }

  /// Ensure user is loaded, resolving from Firebase Auth if necessary
  Future<UserModel?> ensureUserLoaded() async {
    if (currentUser.value != null) return currentUser.value;
    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      await _loadUserProfile(fbUser.uid);
    }
    return currentUser.value;
  }

  bool get isLoggedIn => _auth.currentUser != null;

  /// Sign In with Google
  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the dialog
        isLoading.value = false;
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final fcmToken = FcmService.currentToken;

        // Check if user already exists in Firestore
        final userDoc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (!userDoc.exists) {
          final user = UserModel(
            uid: firebaseUser.uid,
            name: firebaseUser.displayName ??
                googleUser.displayName ??
                'User',
            email: firebaseUser.email ?? googleUser.email,
            photoUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
            groupIds: const [],
            createdAt: DateTime.now(),
            fcmToken: fcmToken,
          );
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(user.toJson());
          currentUser.value = user;
        } else {
          await _updateFcmToken();
          await _loadUserProfile(firebaseUser.uid);
        }

        Get.offAllNamed(AppRoutes.home);
      }
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _authErrorMessage(e.code);
    } catch (e) {
      errorMessage.value = 'Google sign-in failed. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Register with email & password
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      // Get FCM token
      final fcmToken = FcmService.currentToken;

      // Save user profile to Firestore
      final user = UserModel(
        uid: credential.user!.uid,
        name: name,
        email: email,
        photoUrl: null,
        groupIds: const [],
        createdAt: DateTime.now(),
        fcmToken: fcmToken,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toJson());

      currentUser.value = user;
      Get.offAllNamed(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _authErrorMessage(e.code);
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
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update FCM token on login
      await _updateFcmToken();

      Get.offAllNamed(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _authErrorMessage(e.code);
    } catch (e) {
      errorMessage.value = 'Login failed. Please check your credentials.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Update FCM token in Firestore
  Future<void> _updateFcmToken() async {
    final uid = _auth.currentUser?.uid;
    final token = FcmService.currentToken;
    if (uid != null && token != null) {
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    }
  }

  /// Send password reset email
  Future<void> forgotPassword(String email) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar(
        '📧 Email Sent',
        'Password reset link sent to $email',
        duration: const Duration(seconds: 4),
      );
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _authErrorMessage(e.code);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
    currentUser.value = null;
    _storage.erase();
    Get.offAllNamed(AppRoutes.login);
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Authentication error. Please try again.';
    }
  }
}
