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
}
