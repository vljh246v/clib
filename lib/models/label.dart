import 'package:hive/hive.dart';

part 'label.g.dart';

@HiveType(typeId: 2)
class Label extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late int colorValue; // Color.value (0xAARRGGBB)

  @HiveField(2)
  late DateTime createdAt;

  @HiveField(3, defaultValue: false)
  bool notificationEnabled = false;

  @HiveField(4, defaultValue: [])
  List<int> notificationDays = []; // 0=월 ~ 6=일

  @HiveField(5, defaultValue: '09:00')
  String notificationTime = '09:00'; // HH:mm
}
