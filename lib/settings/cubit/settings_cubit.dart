import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:desktop_integration/desktop_integration.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_size/window_size.dart' show PlatformWindow;

import '../../apps_list/apps_list.dart';
import '../../core/core.dart';
import '../../hotkey/hotkey_service.dart';
import '../../storage/storage_repository.dart';
import '../../window/nyrna_window.dart';
import '../settings_service.dart';

part 'settings_state.dart';

late SettingsCubit settingsCubit;

class SettingsCubit extends Cubit<SettingsState> {
  final Future<File> Function(String path) _assetToTempDir;
  final Future<PlatformWindow> Function() _getWindowInfo;
  final SettingsService _prefs;
  final HotkeyService _hotkeyService;
  final NyrnaWindow _nyrnaWindow;
  final StorageRepository _storageRepository;

  SettingsCubit._(
    this._assetToTempDir,
    this._getWindowInfo,
    this._prefs,
    this._hotkeyService,
    this._nyrnaWindow,
    this._storageRepository, {
    required SettingsState initialState,
  }) : super(initialState) {
    settingsCubit = this;
    _hotkeyService.updateHotkey(state.hotKey);
    _nyrnaWindow.preventClose(state.closeToTray);
  }

  static Future<SettingsCubit> init({
    required Future<File> Function(String path) assetToTempDir,
    required Future<PlatformWindow> Function() getWindowInfo,
    required SettingsService prefs,
    required HotkeyService hotkeyService,
    required NyrnaWindow nyrnaWindow,
    required StorageRepository storageRepository,
  }) async {
    HotKey? hotkey;
    final String? savedHotkey = prefs.getString('hotkey');
    if (savedHotkey != null) {
      hotkey = HotKey.fromJson(jsonDecode(savedHotkey));
    } else {
      hotkey = defaultHotkey;
    }

    bool? minimizeWindows = await storageRepository.getValue('minimizeWindows');
    minimizeWindows ??= true;

    return SettingsCubit._(
      assetToTempDir,
      getWindowInfo,
      prefs,
      hotkeyService,
      nyrnaWindow,
      storageRepository,
      initialState: SettingsState(
        autoStart: prefs.getBool('autoStart') ?? false,
        autoRefresh: _checkAutoRefresh(prefs),
        closeToTray: prefs.getBool('closeToTray') ?? false,
        hotKey: hotkey,
        minimizeWindows: minimizeWindows,
        refreshInterval: prefs.getInt('refreshInterval') ?? 5,
        showHiddenWindows: prefs.getBool('showHiddenWindows') ?? false,
        startHiddenInTray: prefs.getBool('startHiddenInTray') ?? false,
      ),
    );
  }

  static bool _checkAutoRefresh(SettingsService prefs) {
    return prefs.getBool('autoRefresh') ?? true;
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

  Future<void> updateAutoStart(bool shouldAutostart) async {
    File? desktopFile;
    if (Platform.isLinux) {
      desktopFile = await _assetToTempDir('packaging/linux/nyrna.desktop');
    }

    final iconFileSuffix = Platform.isWindows ? 'ico' : 'svg';
    final iconFile =
        await _assetToTempDir('assets/icons/nyrna.$iconFileSuffix');

    final desktopIntegration = DesktopIntegration(
      desktopFilePath: desktopFile?.path ?? '',
      iconPath: iconFile.path,
      packageName: 'codes.merritt.nyrna',
      linkFileName: 'Nyrna',
    );

    if (shouldAutostart) {
      await desktopIntegration.enableAutostart();
    } else {
      await desktopIntegration.disableAutostart();
    }

    await _prefs.setBool(key: 'autoStart', value: shouldAutostart);
    emit(state.copyWith(autoStart: shouldAutostart));
  }

  Future<void> updateAutoRefresh(bool? enabled) async {
    if (enabled == null) return;

    await _prefs.setBool(key: 'autoRefresh', value: enabled);
    appsListCubit.setAutoRefresh(
      autoRefresh: enabled,
      refreshInterval: state.refreshInterval,
    );

    emit(state.copyWith(autoRefresh: enabled));
  }

  Future<void> updateCloseToTray([bool? closeToTray]) async {
    if (closeToTray == null) return;

    await _nyrnaWindow.preventClose(closeToTray);
    await _prefs.setBool(key: 'closeToTray', value: closeToTray);
    emit(state.copyWith(closeToTray: closeToTray));
  }

  /// Update the preference for auto minimizing windows.
  Future<void> updateMinimizeWindows(bool value) async {
    emit(state.copyWith(minimizeWindows: value));
    await _storageRepository.saveValue(key: 'minimizeWindows', value: value);
  }

  Future<void> updateShowHiddenWindows(bool value) async {
    await _prefs.setBool(key: 'showHiddenWindows', value: value);
    emit(state.copyWith(showHiddenWindows: value));
  }

  Future<void> updateStartHiddenInTray(bool value) async {
    await _prefs.setBool(key: 'startHiddenInTray', value: value);
    emit(state.copyWith(startHiddenInTray: value));
  }

  Future<void> removeHotkey() async {
    await _hotkeyService.removeHotkey();
  }

  Future<void> resetHotkey() async {
    await _hotkeyService.updateHotkey(defaultHotkey);
    emit(state.copyWith(hotKey: defaultHotkey));
    await _prefs.remove('hotkey');
  }

  Future<void> updateHotkey(HotKey newHotKey) async {
    await _hotkeyService.updateHotkey(newHotKey);
    emit(state.copyWith(hotKey: newHotKey));
    await _prefs.setString(
      key: 'hotkey',
      value: jsonEncode(newHotKey.toJson()),
    );
  }

  /// Save the current window size & position to storage.
  ///
  /// Allows the app to remember its window size for next launch.
  Future<void> saveWindowSize() async {
    final windowInfo = await _getWindowInfo();
    final rectJson = windowInfo.frame.toJson();
    await _prefs.setString(key: 'windowSize', value: rectJson);
  }

  /// Returns if available the last window size and position.
  Future<Rect?> savedWindowSize() async {
    final rectJson = _prefs.getString('windowSize');
    if (rectJson == null) return null;
    final windowRect = RectConverter.fromJson(rectJson);
    return windowRect;
  }
}
