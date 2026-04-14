import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/absences_screen.dart';
import 'services/update_service.dart';
import 'screens/students_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PM.Journal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF141218),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0BCFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const JournalScreen(),
    );
  }
}

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  // 2. Добавляем initState
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService().checkForUpdates(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              const Text(
                'PM.Journal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),

              const Spacer(),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                  );
                },
                icon: const Icon(Icons.add, color: Color(0xFF381E72)),
                label: const Text(
                  'Создать группу',
                  style: TextStyle(
                    color: Color(0xFF381E72),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD0BCFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  elevation: 0,
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExistingTable(),
                    ),
                  );
                },
                icon: const Icon(Icons.stars, color: Color(0xFFCAC4D0)),
                label: const Text(
                  'Использовать существующую',
                  style: TextStyle(
                    color: Color(0xFFE6E1E5),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF49454F)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class ExistingTable extends StatelessWidget {
  const ExistingTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Существующая группа")),
      body: const Center(child: Text("В разработке...")),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          ["Отметки", "Расписание", "Пропуски", "Настройки"][currentIndex],
        ),
        centerTitle: true,
        actions: [],
      ),
      body: _buildScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => setState(() => currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.check_box), label: "Отметки"),
          NavigationDestination(
            icon: Icon(Icons.access_time),
            label: "Расписание",
          ),
          NavigationDestination(icon: Icon(Icons.star), label: "Пропуски"),
          NavigationDestination(icon: Icon(Icons.settings), label: "Настройки"),
        ],
      ),
    );
  }

  Widget _buildScreen() {
    if (currentIndex == 0) {
      return const AttendanceScreen();
    }

    if (currentIndex == 1) {
      return const ScheduleScreen();
    }

    if (currentIndex == 2) {
      return const AbsencesScreen();
    }

    if (currentIndex == 3) {
      return const SettingsScreen();
    }

    return Center(
      child: Text(
        ["Отметки", "Расписание", "Пропуски", "Настройки"][currentIndex],
        style: const TextStyle(fontSize: 20),
      ),
    );
  }
}

/*
TODO:
- Экспорт в Excel для удобства работы с данными вне приложения
- Создать пользовательский доступ
- Починить UpdateService 
- Открепить базу от конкретной группы 
*/
