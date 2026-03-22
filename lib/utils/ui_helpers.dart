import 'package:flutter/material.dart';

final Map<String, Color> coresDisponiveis = {
  'blue': Colors.blue,
  'red': Colors.red,
  'green': Colors.green,
  'orange': Colors.orange,
  'purple': Colors.purple,
};

final Map<String, IconData> iconesDisponiveis = {
  'money': Icons.attach_money,
  'food': Icons.restaurant,
  'car': Icons.directions_car,
  'movie': Icons.movie,
  'shopping': Icons.shopping_bag,
  'home': Icons.home,
  'card': Icons.credit_card,
};

Color getCategoriaCor(String? nome) {
  return coresDisponiveis[nome] ?? Colors.grey;
}

IconData getCategoriaIcone(String? nome) {
  return iconesDisponiveis[nome] ?? Icons.category;
}