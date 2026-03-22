import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';

final supabase = Supabase.instance.client;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final senha = TextEditingController();

  bool carregando = false;
  bool mostrarSenha = false;

  Future login() async {
    setState(() => carregando = true);

    try {
      await supabase.auth.signInWithPassword(
        email: email.text.trim(),
        password: senha.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erro: $e")));
    }

    setState(() => carregando = false);
  }

  Future recuperarSenha() async {
    if (email.text.isEmpty) return;

    await supabase.auth.resetPasswordForEmail(email.text.trim());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Email enviado")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Login", style: TextStyle(fontSize: 24)),

              TextField(controller: email, decoration: const InputDecoration(labelText: "Email")),

              TextField(
                controller: senha,
                obscureText: !mostrarSenha,
                decoration: InputDecoration(
                  labelText: "Senha",
                  suffixIcon: IconButton(
                    icon: Icon(mostrarSenha ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => mostrarSenha = !mostrarSenha),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: recuperarSenha,
                  child: const Text("Esqueci minha senha"),
                ),
              ),

              ElevatedButton(
                onPressed: login,
                child: const Text("Entrar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}