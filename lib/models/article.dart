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
  @HiveField(4)
  x,
  @HiveField(5)
  tiktok,
  @HiveField(6)
  facebook,
  @HiveField(7)
  linkedin,
  @HiveField(8)
  github,
  @HiveField(9)
  reddit,
  @HiveField(10)
  naverBlog,
  @HiveField(11)
  threads,
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

  @HiveField(7, defaultValue: false)
  bool isBookmarked = false;

  @HiveField(8)
  String? memo;
}

Platform classifyPlatform(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return Platform.etc;

  final host = uri.host.toLowerCase();
  if (host.contains('youtube.com') || host.contains('youtu.be')) {
    return Platform.youtube;
  } else if (host.contains('instagram.com')) {
    return Platform.instagram;
  } else if (host.contains('x.com') || host.contains('twitter.com')) {
    return Platform.x;
  } else if (host.contains('tiktok.com')) {
    return Platform.tiktok;
  } else if (host.contains('facebook.com') || host.contains('fb.com')) {
    return Platform.facebook;
  } else if (host.contains('linkedin.com')) {
    return Platform.linkedin;
  } else if (host.contains('github.com') || host.contains('github.io')) {
    return Platform.github;
  } else if (host.contains('reddit.com')) {
    return Platform.reddit;
  } else if (host.contains('threads.net')) {
    return Platform.threads;
  } else if (host.contains('blog.naver.com') || host.contains('m.blog.naver.com')) {
    return Platform.naverBlog;
  } else if (host.contains('tistory.com') ||
      host.contains('velog.io') ||
      host.contains('medium.com') ||
      host.contains('brunch.co.kr')) {
    return Platform.blog;
  }
  return Platform.etc;
}
