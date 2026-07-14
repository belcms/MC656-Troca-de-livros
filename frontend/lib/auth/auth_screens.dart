import 'package:flutter/material.dart';
import 'auth_controller.dart';
import 'auth_repository.dart';

InputDecoration _decoration(String label) =>
    InputDecoration(labelText: label, border: const OutlineInputBorder());

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  Future<void> _submit(Future<void> Function() action) async {
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Text(
                    'Troca de Livros',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _decoration('E-mail'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: _decoration('Senha'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: auth.loading
                        ? null
                        : () => _submit(
                            () => auth.login(email.text.trim(), password.text),
                          ),
                    child: const Text('Entrar'),
                  ),
                  TextButton(
                    onPressed: auth.loading
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                    child: const Text('Criar conta'),
                  ),
                  if (auth.loading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      nick = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      birth = TextEditingController(),
      cep = TextEditingController();
  String? required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;
  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    if (password.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A senha deve ter ao menos 8 caracteres.'),
        ),
      );
      return;
    }
    try {
      await AuthScope.of(context).register({
        'full_name': name.text.trim(),
        'nickname': nick.text.trim(),
        'email': email.text.trim(),
        'password': password.text,
        'birth_date': birth.text.trim(),
        'cep': cep.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Criar conta')),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final item in [
            (name, 'Nome'),
            (nick, 'Nickname'),
            (email, 'E-mail'),
            (password, 'Senha'),
            (birth, 'Nascimento (AAAA-MM-DD)'),
            (cep, 'CEP'),
          ]) ...[
            TextFormField(
              controller: item.$1,
              validator: required,
              obscureText: item.$2 == 'Senha',
              decoration: _decoration(item.$2),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: AuthScope.of(context).loading ? null : submit,
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    ),
  );
}
