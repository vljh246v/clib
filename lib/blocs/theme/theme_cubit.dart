import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clib/services/database_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(DatabaseService.savedThemeMode);

  Future<void> setTheme(ThemeMode mode) async {
    if (mode == state) return;
    await DatabaseService.saveThemeMode(mode);
    emit(mode);
  }
}
