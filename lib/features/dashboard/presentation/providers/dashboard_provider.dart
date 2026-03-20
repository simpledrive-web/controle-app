import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final dashboardProvider = FutureProvider<Map<String, double>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('expenses')
      .select('valor, categoria');

  final data = response as List;

  Map<String, double> result = {};

  for (var item in data) {
    final category = item['categoria'] ?? 'Outros';
    final amount = (item['valor'] as num).toDouble();

    result[category] = (result[category] ?? 0) + amount;
  }

  return result;
});