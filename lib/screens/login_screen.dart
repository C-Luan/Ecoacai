import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  // Função para verificar o perfil do usuário e navegar
  Future<void> _navigateToAppropriateScreen(User? user) async {
    if (user != null) {
      final docSnapshot = await _firestore.collection('cidadaos').doc(user.uid).get();
      if (mounted) {
        if (docSnapshot.exists) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/profile');
        }
      }
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Por favor, preencha todos os campos.');
      return;
    }

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await _navigateToAppropriateScreen(userCredential.user);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      log(e.code);
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Nenhum usuário encontrado para esse e-mail.';
          break;
        case 'wrong-password':
          errorMessage = 'Senha incorreta.';
          break;
        case 'invalid-email':
          errorMessage = 'E-mail inválido.';
          break;
        default:
          errorMessage = 'Ocorreu um erro. Tente novamente.';
          break;
      }
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar('Ocorreu um erro desconhecido.');
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return; // O usuário cancelou o login
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      _showSnackBar('Login com o Google realizado com sucesso!', color: Colors.blue);
      await _navigateToAppropriateScreen(userCredential.user);
    } on FirebaseAuthException catch (e) {
      _showSnackBar('Erro ao fazer login com o Google: ${e.message}');
    } catch (e) {
      log(e.toString());
      _showSnackBar('Ocorreu um erro desconhecido.');
    }
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSnackBar('Um e-mail de redefinição de senha foi enviado para $email.', color: Colors.green);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Nenhum usuário encontrado com este e-mail.';
          break;
        case 'invalid-email':
          errorMessage = 'O endereço de e-mail é inválido.';
          break;
        default:
          errorMessage = 'Ocorreu um erro ao enviar o e-mail: ${e.message}';
          break;
      }
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar('Ocorreu um erro desconhecido ao tentar redefinir a senha.');
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Redefinir Senha'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              hintText: 'Digite seu e-mail',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              onPressed: () {
                if (emailController.text.isNotEmpty) {
                  _sendPasswordResetEmail(emailController.text.trim());
                  Navigator.of(context).pop();
                } else {
                  _showSnackBar('Por favor, digite seu e-mail.', color: Colors.orange);
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
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
              // A imagem pode ser um placeholder se você não tiver uma
              Image.asset(
                'assets/logos/ecoacai.png',
                height: 360,
              ),
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
              const SizedBox(height: 8.0),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Esqueceu a senha?'),
                ),
              ),
              const SizedBox(height: 16.0),
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
