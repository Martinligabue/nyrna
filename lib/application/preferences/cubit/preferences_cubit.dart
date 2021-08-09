import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:nyrna/application/app/app.dart';
import 'package:nyrna/infrastructure/icon_manager/icon_manager.dart';
import 'package:nyrna/infrastructure/launcher/launcher.dart';
import 'package:nyrna/infrastructure/preferences/preferences.dart';
import 'package:nyrna/presentation/styles.dart';

part 'preferences_state.dart';

late PreferencesCubit preferencesCubit;

class PreferencesCubit extends Cubit<PreferencesState> {
  final Preferences _prefs;

  PreferencesCubit(Preferences prefs)
      : _prefs = prefs,
        super(
          PreferencesState(
            autoRefresh: _checkAutoRefresh(prefs),
            refreshInterval: prefs.getInt('refreshInterval') ?? 5,
            trayIconColor: Color(
              prefs.getInt('trayIconColor') ?? AppColors.defaultIconColor,
            ),
          ),
        ) {
    preferencesCubit = this;
  }

  static bool _checkAutoRefresh(Preferences prefs) {
    bool? enabled = prefs.getBool('autoRefresh');
    enabled ??= (Platform.isWindows) ? false : true;
    return enabled;
  }

  Future<void> createLauncher() async {
    await Launcher.add();
  }

  /// If user wishes to ignore this update, save to SharedPreferences.
  Future<void> ignoreUpdate(String version) async {
    await _prefs.setString(key: 'ignoredUpdate', value: version);
  }

  Future<void> setRefreshInterval(int interval) async {
    if (interval > 0) {
      await _prefs.setInt(key: 'refreshInterval', value: interval);
      emit(state.copyWith(refreshInterval: interval));
    }
  }

  Future<void> updateAutoRefresh([bool? autoEnabled]) async {
    if (autoEnabled != null) {
      await _prefs.setBool(key: 'autoRefresh', value: autoEnabled);
      appCubit.setAutoRefresh(
        autoRefresh: autoEnabled,
        refreshInterval: state.refreshInterval,
      );
      emit(state.copyWith(autoRefresh: autoEnabled));
    }
  }

  Future<Uint8List> iconBytes() async {
    final iconManager = IconManager();
    final iconBytes = await iconManager.iconBytes();
    return iconBytes;
  }

  Future<void> updateIconColor(Color newColor) async {
    final successful = await IconManager().updateIconColor(newColor);
    if (successful) {
      await _prefs.setInt(key: 'trayIconColor', value: newColor.value);
      emit(state.copyWith(trayIconColor: newColor));
    }
  }
}
