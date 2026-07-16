import 'package:firebase_auth/firebase_auth.dart';

import '../firebase/analytics_tracking_service.dart';
import '../firebase/auth_service.dart';

class AuthenticationViewModel {
  AuthenticationViewModel({AuthService? authService})
    : _authService = authService ?? AuthService.instance;

  final AuthService _authService;

  User? get currentUser => _authService.currentUser;
  Stream<User?> authStateChanges() => _authService.authStateChanges();

  Future<void> signInWithGoogle() async {
    await _authService.signInWithGoogle();
    await AnalyticsTrackingService.instance.logLogin();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    await AnalyticsTrackingService.instance.logLogout();
  }
}
