import 'package:flutter/material.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/platform_meta.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/theme/app_theme.dart';
import 'package:clib/theme/design_tokens.dart';

class ArticleCard extends StatelessWidget {
  final Article article;

  const ArticleCard({super.key, required this.article});

  String get _platformLabel => platformMeta(article.platform).label;
  IconData get _platformIcon => platformMeta(article.platform).icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: Radii.borderXl,
        boxShadow: AppShadows.swipeCard(isDark),
      ),
      child: ClipRRect(
        borderRadius: Radii.borderXl,
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
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  stops: const [0.35, 0.95],
                ),
              ),
            ),

            // 북마크 아이콘
            if (article.isBookmarked)
              Positioned(
                top: Spacing.lg,
                right: Spacing.lg,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: Radii.borderSm,
                  ),
                  child: const Icon(Icons.bookmark, size: 16, color: Colors.white70),
                ),
              ),

            // 제목 + 플랫폼 뱃지
            Positioned(
              left: Spacing.xl,
              right: Spacing.xl,
              bottom: Spacing.xxl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 플랫폼 뱃지 + 라벨 칩
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // 플랫폼 뱃지 (frosted-glass 스타일)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: Radii.borderMd,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_platformIcon,
                                size: 14, color: Colors.white70),
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
                      // 라벨 칩
                      ...article.topicLabels.map((name) {
                        final label = DatabaseService.getLabelByName(name);
                        final color = label != null
                            ? Color(label.colorValue)
                            : Colors.grey;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.3),
                            borderRadius: Radii.borderSm,
                            border: Border.all(
                              color: color.withValues(alpha: 0.6),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }),
                    ],
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
                      shadows: [
                        Shadow(blurRadius: 8, color: Colors.black26),
                      ],
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
          colors: [AppColors.warmCharcoal, Color(0xFF3D3D4A)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.article_outlined, size: 80, color: Colors.white24),
      ),
    );
  }
}
