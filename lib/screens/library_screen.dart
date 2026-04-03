import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '저장된 라벨이 없습니다.',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}
