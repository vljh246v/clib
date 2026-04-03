import 'package:flutter/material.dart';
import 'package:clib/models/article.dart';

/// 플랫폼별 표시 정보 (라벨 + 아이콘)
({String label, IconData icon}) platformMeta(Platform p) {
  return switch (p) {
    Platform.youtube   => (label: 'YouTube',   icon: Icons.play_circle_fill),
    Platform.instagram => (label: 'Instagram', icon: Icons.camera_alt),
    Platform.x         => (label: 'X',         icon: Icons.tag),
    Platform.tiktok    => (label: 'TikTok',    icon: Icons.music_note),
    Platform.facebook  => (label: 'Facebook',  icon: Icons.facebook),
    Platform.linkedin  => (label: 'LinkedIn',  icon: Icons.work_outline),
    Platform.github    => (label: 'GitHub',    icon: Icons.code),
    Platform.reddit    => (label: 'Reddit',    icon: Icons.forum),
    Platform.threads   => (label: 'Threads',   icon: Icons.alternate_email),
    Platform.naverBlog => (label: 'Naver',     icon: Icons.rss_feed),
    Platform.blog      => (label: 'Blog',      icon: Icons.article),
    Platform.etc       => (label: 'Web',       icon: Icons.language),
  };
}
