import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  // 🔥 INIT USER (ESSENCIAL)
  Future<void> initUser() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    final existing = await supabase
        .from('user_data')
        .select()
        .eq('user_id', user.id);

    if (existing.isEmpty) {
      await supabase.from('user_data').insert({
        'user_id': user.id,
        'saldo': 0,
      });
    }
  }

  // 💰 GET SALDO
  Future<double> getSaldo() async {
    final user = supabase.auth.currentUser;

    final data = await supabase
        .from('user_data')
        .select('saldo')
        .eq('user_id', user!.id)
        .single();

    return (data['saldo'] ?? 0).toDouble();
  }

  // ➕ UPDATE SALDO
  Future<void> updateSaldo(double valor) async {
    final user = supabase.auth.currentUser;

    await supabase
        .from('user_data')
        .update({'saldo': valor})
        .eq('user_id', user!.id);
  }

  // 📂 GET CATEGORIES
  Future<List<dynamic>> getCategories() async {
    final user = supabase.auth.currentUser;

    final data = await supabase
        .from('categories')
        .select()
        .eq('user_id', user!.id);

    return data;
  }

  // ➕ CREATE CATEGORY
  Future<void> createCategory(String name) async {
    final user = supabase.auth.currentUser;

    await supabase.from('categories').insert({
      'name': name,
      'user_id': user!.id,
    });
  }
}