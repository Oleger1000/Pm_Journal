import 'package:flutter/material.dart';
import 'models/shedule_item.dart';
import 'services/shedule_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/student_service.dart';
import 'services/attendance_service.dart';
import 'firebase_options.dart';
import 'screens/absences_screen.dart';
import 'services/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late Future<ScheduleResponse> future;
  late TabController tabController;

  final days = ["Пн", "Вт", "Ср", "Чт", "Пт"];

  final intervals = {
    1: "09:00-10:30",
    2: "10:45-12:15",
    3: "13:15-14:45",
    4: "15:00-16:30",
    5: "16:45-18:15",
    6: "18:30-20:00",
    7: "20:15-21:45",
  };

  @override
  void initState() {
    super.initState();

    future = ScheduleService.fetch();
    tabController = TabController(length: 5, vsync: this);

    final today = DateTime.now().weekday;

    if (today >= 1 && today <= 5) {
      tabController.index = today - 1;
    } else {
      tabController.index = 0;
    }
  }

  int getCurrentWeek(DateTime startDate) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    final diff = today.difference(start).inDays ~/ 7;

    final week = diff % 2 == 0 ? 1 : 2;

    return week == 1 ? 2 : 1; // 🔥 фикс
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// 🔹 ВКЛАДКИ (вместо AppBar)
        TabBar(
          controller: tabController,
          tabs: days.map((d) => Tab(text: d)).toList(),
        ),

        /// 🔹 КОНТЕНТ
        Expanded(
          child: FutureBuilder<ScheduleResponse>(
            future: future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final response = snapshot.data!;
              final data = response.classes;

              final currentWeek = getCurrentWeek(response.startDate);

              return TabBarView(
                controller: tabController,
                children: List.generate(5, (dayIndex) {
                  final day = dayIndex + 1;

                  final filtered =
                      data
                          .where((e) => e.day == day && e.week == currentWeek)
                          .toList()
                        ..sort((a, b) => a.lesson.compareTo(b.lesson));

                  if (filtered.isEmpty) {
                    return const Center(child: Text("Выходной 😴"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final item = filtered[i];

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          title: Text(item.discipline),
                          subtitle: Text(
                            "${item.type} • ${item.lecturer}\n"
                            "${item.auditorium} • ${intervals[item.lesson]}",
                          ),
                          leading: CircleAvatar(
                            child: Text(item.lesson.toString()),
                          ),
                        ),
                      );
                    },
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}

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

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final studentService = StudentService();
  final attendanceService = AttendanceService();

  DateTime selectedDate = DateTime.now();
  ScheduleItem? selectedLesson;
  ScheduleResponse? scheduleData;

  List students = [];
  List records = [];
  Map<String, AttendanceStatus> statuses = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    students = await studentService.getStudents();
    records = await attendanceService.loadAttendance();
    scheduleData = await ScheduleService.fetch();
    _updateStatuses();
    if (mounted) setState(() {});
  }

  int getCurrentWeek(DateTime targetDate, DateTime startDate) {
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final diff = target.difference(start).inDays ~/ 7;
    final week = diff % 2 == 0 ? 1 : 2;
    return week == 1 ? 2 : 1;
  }

  List<ScheduleItem> getLessonsForDate() {
    if (scheduleData == null) return [];
    final currentWeek = getCurrentWeek(selectedDate, scheduleData!.startDate);
    final weekday = selectedDate.weekday;
    return scheduleData!.classes
        .where((e) => e.day == weekday && e.week == currentWeek)
        .toList()
      ..sort((a, b) => a.lesson.compareTo(b.lesson));
  }

  void _updateStatuses() {
    statuses.clear();
    if (selectedLesson == null) return;
    for (var student in students) {
      final existingRecord = records.where((r) {
        final d = DateTime.parse(r['date']);
        return d.year == selectedDate.year &&
            d.month == selectedDate.month &&
            d.day == selectedDate.day &&
            r['lesson'] == selectedLesson!.lesson &&
            r['studentId'] == student['id'];
      }).toList();
      if (existingRecord.isNotEmpty) {
        final statusStr = existingRecord.first['status'];
        if (statusStr == 'present') {
          statuses[student['id']] = AttendanceStatus.present;
        } else if (statusStr == 'absent') {
          statuses[student['id']] = AttendanceStatus.absent;
        } else if (statusStr == 'excused') {
          statuses[student['id']] = AttendanceStatus.excused;
        }
      } else {
        statuses[student['id']] = AttendanceStatus.present;
      }
    }
  }

  void save() async {
    if (selectedLesson == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Сначала выберите пару!")));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final signature = prefs.getString('user_signature');

    if (signature == null || signature.trim().isEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Необходима подпись"),
          content: const Text(
            "Чтобы сохранить изменения, необходимо указать вашу подпись.\n\nПерейдите в Настройки -> Подпись для отметок.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Понятно"),
            ),
          ],
        ),
      );
      return; // Прерываем сохранение
    }

    // Показываем индикатор загрузки для наглядности
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Сохранение..."),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      // Вызываем новый оптимизированный метод, передавая все данные разом
      await attendanceService.updateAttendanceBatch(
        statuses: statuses,
        date: selectedDate,
        lesson: selectedLesson!.lesson,
        markedBy: signature,
      );

      // Обновляем локальные данные после успешного сохранения
      records = await attendanceService.loadAttendance();

      if (mounted) {
        // Убираем старый SnackBar и показываем новый
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Отметки сохранены ✅")));
      }
    } catch (e) {
      // Обработка ошибок
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Ошибка сохранения: $e")));
      }
    }

    for (var student in students) {
      final status = statuses[student['id']] ?? AttendanceStatus.present;
      await attendanceService.markAttendance(
        studentId: student['id'],
        date: selectedDate,
        lesson: selectedLesson!.lesson,
        status: status,
        markedBy: signature,
      );
    }

    records = await attendanceService.loadAttendance();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Отметки сохранены ✅")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (scheduleData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final todayLessons = getLessonsForDate();

    if (selectedLesson != null &&
        !todayLessons.any((l) => l.lesson == selectedLesson!.lesson)) {
      selectedLesson = null;
      _updateStatuses();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  "${selectedDate.day}.${selectedDate.month}.${selectedDate.year}",
                ),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() {
                      selectedDate = date;
                      selectedLesson = null;
                      _updateStatuses();
                    });
                  }
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<ScheduleItem>(
                  isExpanded: true,
                  value: selectedLesson,
                  hint: const Text("Выбери пару"),
                  items: todayLessons.map((lesson) {
                    return DropdownMenuItem(
                      value: lesson,
                      child: Text(
                        "${lesson.lesson}. ${lesson.discipline}",
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (lesson) {
                    setState(() {
                      selectedLesson = lesson;
                      _updateStatuses();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: selectedLesson == null
              ? const Center(
                  child: Text(
                    "Выберите пару для выставления отметок",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (_, i) {
                    final student = students[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(student['name']),
                        trailing: DropdownButton<AttendanceStatus>(
                          value:
                              statuses[student['id']] ??
                              AttendanceStatus.present,
                          items: AttendanceStatus.values.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(
                                s == AttendanceStatus.present
                                    ? "✅ Есть"
                                    : s == AttendanceStatus.absent
                                    ? "❌ Нет"
                                    : "📄 Уваж",
                              ),
                            );
                          }).toList(),
                          onChanged: (s) {
                            setState(() {
                              statuses[student['id']] = s!;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: selectedLesson == null ? null : save,
              icon: const Icon(Icons.save),
              label: const Text("Сохранить изменения"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFFD0BCFF),
                foregroundColor: const Color(0xFF381E72),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ... (StudentsScreen остается без изменений)

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final service = StudentService();
  List students = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    students = await service.getStudents();
    setState(() {});
  }

  void _addStudent() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Добавить студента"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () async {
              await service.addStudent(controller.text);
              Navigator.pop(context);
              load();
            },
            child: const Text("Добавить"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Студенты")),
      floatingActionButton: FloatingActionButton(
        onPressed: _addStudent,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: students.length,
        itemBuilder: (_, i) {
          return Card(child: ListTile(title: Text(students[i]['name'])));
        },
      ),
    );
  }
}

/*
TODO:
- Экспорт в Excel для удобства работы с данными вне приложения
*/
