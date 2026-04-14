import 'package:flutter/material.dart';
import '../services/shedule_service.dart';
import '../models/shedule_item.dart';

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
