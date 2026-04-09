import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shedule_item.dart';

class ScheduleService {
  static Future<ScheduleResponse> fetch() async {
    final res = await http.get(
      Uri.parse(
        'https://schedule.npi-tu.ru/api/v2/faculties/2/years/2/groups/%D0%9A%D0%9C%D0%A1%D0%B0/schedule',
      ),
    );

    final data = json.decode(res.body);

    final classes = (data['classes'] as List)
        .map((e) => ScheduleItem.fromJson(e))
        .toList();

    final startDate = DateTime.parse(data['semester']['start']);

    return ScheduleResponse(classes: classes, startDate: startDate);
  }
}

class ScheduleResponse {
  final List<ScheduleItem> classes;
  final DateTime startDate;

  ScheduleResponse({required this.classes, required this.startDate});
}
