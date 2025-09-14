import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Lógica de autenticação
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _loginWithGoogle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login com o Google em desenvolvimento!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Adiciona a imagem aqui
              Image.asset(
                'assets/logos/ecoacai.png',
                height: 360, // Ajuste o tamanho conforme necessário
              ),
              // const SizedBox(height: 24.0),
              // Text(
              //   'Caroço de Açaí',
              //   style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              //         color: const Color(0xFF4C1D95),
              //         fontWeight: FontWeight.bold,
              //       ),
              // ),
              // const SizedBox(height: 8.0),
              // Text(
              //   'Gestão sustentável de resíduos',
              //   style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              //         color: const Color(0xFF374151),
              //       ),
              //   textAlign: TextAlign.center,
              // ),
              const SizedBox(height: 48.0),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _login,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4C1D95),
                  ),
                  child: const Text('Entrar'),
                ),
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loginWithGoogle,
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Entrar com Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    side: const BorderSide(color: Color(0xFF374151), width: 1.0),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: const Text('Não tem conta? Criar conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}