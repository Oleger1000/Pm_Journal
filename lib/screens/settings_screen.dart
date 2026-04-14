import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'students_screen.dart';

// 🔹 ЭКРАН НАСТРОЕК (ИЗМЕНЕНИЯ ЗДЕСЬ)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showSignatureDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final currentSignature = prefs.getString('user_signature') ?? '';
    final controller = TextEditingController(text: currentSignature);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ваша подпись"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Например, ваше ФИО или инициалы",
            helperText: "Эта подпись будет прикрепляться к каждой отметке.",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Подпись не может быть пустой")),
                );
                return;
              }
              await prefs.setString('user_signature', controller.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Подпись сохранена")),
              );
            },
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        "title": "Студенты",
        "icon": Icons.people,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentsScreen()),
          );
        },
      },
      // 🔹 НОВЫЙ ПУНКТ МЕНЮ
      {
        "title": "Подпись для отметок",
        "icon": Icons.edit,
        "onTap": _showSignatureDialog,
      },
      {"title": "Группа", "icon": Icons.group, "onTap": () {}},
      {"title": "Экспорт (потом)", "icon": Icons.file_download, "onTap": () {}},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Icon(item["icon"] as IconData),
            title: Text(item["title"] as String),
            trailing: const Icon(Icons.chevron_right),
            onTap: item["onTap"] as void Function()?,
          ),
        );
      },
    );
  }
}
