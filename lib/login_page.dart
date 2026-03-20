import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final senha = TextEditingController();

  bool loading = false;

  /// 🔐 LOGIN
  Future<void> login() async {
    if (email.text.isEmpty || senha.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha email e senha")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await supabase.auth.signInWithPassword(
        email: email.text.trim(),
        password: senha.text.trim(),
      );

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: ${e.toString()}")),
      );
    }

    setState(() => loading = false);
  }

  /// 🔁 RECUPERAR SENHA
  Future<void> recuperarSenha() async {
    if (email.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Digite seu email primeiro")),
      );
      return;
    }

    try {
      await supabase.auth.resetPasswordForEmail(email.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email de recuperação enviado")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Center(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// 🔥 TÍTULO
                const Text(
                  "Controle 💰",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 25),

                /// 📧 EMAIL
                TextField(
                  controller: email,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// 🔒 SENHA
                TextField(
                  controller: senha,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Senha",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                /// 🔘 BOTÃO LOGIN
                ElevatedButton(
                  onPressed: loading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Entrar"),
                ),

                const SizedBox(height: 10),

                /// 🔁 RECUPERAR SENHA
                TextButton(
                  onPressed: recuperarSenha,
                  child: const Text(
                    "Recuperar acesso",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),

                /// 🆕 CRIAR CONTA
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text(
                    "Criar conta",
                    style: TextStyle(color: Colors.tealAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}