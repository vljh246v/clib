import 'package:hive/hive.dart';

part 'article.g.dart';

@HiveType(typeId: 1)
enum Platform {
  @HiveField(0)
  youtube,
  @HiveField(1)
  instagram,
  @HiveField(2)
  blog,
  @HiveField(3)
  etc,
}

@HiveType(typeId: 0)
class Article extends HiveObject {
  @HiveField(0)
  late String url;

  @HiveField(1)
  late String title;

  @HiveField(2)
  String? thumbnailUrl;

  @HiveField(3)
  late Platform platform;

  @HiveField(4)
  late List<String> topicLabels;

  @HiveField(5)
  late bool isRead;

  @HiveField(6)
  late DateTime createdAt;
}

Platform classifyPlatform(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return Platform.etc;

  final host = uri.host.toLowerCase();
  if (host.contains('youtube.com') || host.contains('youtu.be')) {
    return Platform.youtube;
  } else if (host.contains('instagram.com')) {
    return Platform.instagram;
  } else if (host.contains('tistory.com') ||
      host.contains('velog.io') ||
      host.contains('medium.com') ||
      host.contains('brunch.co.kr') ||
      host.contains('naver.com')) {
    return Platform.blog;
  }
  return Platform.etc;
}
