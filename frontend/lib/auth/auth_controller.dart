import 'package:flutter/widgets.dart';

import 'auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository repository;

  bool initializing = true;
  bool loading = false;

  bool get authenticated => repository.user != null;

  AuthController({
    required this.repository,
  }) {
    repository.onSessionInvalidated = notifyListeners;
  }

  Future<void> initialize() async {
    await repository.restore();
    initializing = false;
    notifyListeners();
  }

  Future<void> login(
    String email,
    String password,
  ) {
    return _run(
      () => repository.login(
        email,
        password,
      ),
    );
  }

  Future<void> register(
    Map<String, dynamic> data,
  ) {
    return _run(
      () => repository.register(
        data,
      ),
    );
  }

  Future<void> logout() {
    return _run(
      repository.logout,
    );
  }

  Future<void> _run(
    Future<void> Function() operation,
  ) async {
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
  }) : super(
          notifier: controller,
        );

  static AuthController of(
    BuildContext context,
  ) {
    return context
        .dependOnInheritedWidgetOfExactType<AuthScope>()!
        .notifier!;
  }
}