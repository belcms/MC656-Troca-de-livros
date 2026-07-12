import 'package:flutter/widgets.dart';
import 'auth_repository.dart';

class AuthController extends ChangeNotifier {
  final repository = AuthRepository.instance;
  bool initializing = true;
  bool loading = false;
  GoogleOnboarding? onboarding;
  bool get authenticated => repository.user != null;

  AuthController() {
    repository.onSessionInvalidated = notifyListeners;
  }

  Future<void> initialize() async {
    await repository.restore();
    onboarding = repository.pendingOnboarding;
    initializing = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) =>
      _run(() => repository.login(email, password));
  Future<void> register(Map<String, dynamic> data) =>
      _run(() => repository.register(data));
  Future<void> googleLogin() => _run(() async {
    onboarding = await repository.loginWithGoogle();
  });
  Future<void> completeGoogle(String nickname, String birthDate, String cep) =>
      _run(() async {
        await repository.completeGoogle(onboarding!, nickname, birthDate, cep);
        onboarding = null;
      });
  Future<void> logout() => _run(repository.logout);

  Future<void> _run(Future<void> Function() operation) async {
    loading = true;
    notifyListeners();
    try {
      await operation();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);
  static AuthController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()!.notifier!;
}
