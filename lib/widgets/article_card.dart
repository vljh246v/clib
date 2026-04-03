import 'package:flutter/material.dart';
import 'package:clib/models/article.dart';
import 'package:clib/theme/app_theme.dart';

class ArticleCard extends StatelessWidget {
  final Article article;

  const ArticleCard({super.key, required this.article});

  String get _platformLabel {
    switch (article.platform) {
      case Platform.youtube:
        return 'YouTube';
      case Platform.instagram:
        return 'Instagram';
      case Platform.blog:
        return 'Blog';
      case Platform.etc:
        return 'Web';
    }
  }

  IconData get _platformIcon {
    switch (article.platform) {
      case Platform.youtube:
        return Icons.play_circle_fill;
      case Platform.instagram:
        return Icons.camera_alt;
      case Platform.blog:
        return Icons.article;
      case Platform.etc:
        return Icons.language;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 배경: 썸네일 또는 그라데이션
            if (article.thumbnailUrl != null)
              Image.network(
                article.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _defaultBackground(),
              )
            else
              _defaultBackground(),

            // 하단 그라데이션 오버레이
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),

            // 제목 + 플랫폼 뱃지
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 플랫폼 뱃지
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.deepIndigo.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_platformIcon, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          _platformLabel,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 제목
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepIndigo, Color(0xFF2D2D6B)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.article_outlined, size: 80, color: Colors.white24),
      ),
    );
  }
}
