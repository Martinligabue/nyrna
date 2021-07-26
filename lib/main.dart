import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nyrna/infrastructure/logger/app_logger.dart';
import 'package:nyrna/presentation/app_widget.dart';
import 'package:nyrna/infrastructure/preferences/preferences.dart';
import 'package:nyrna/application/active_window/active_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'application/app/app.dart';
import 'application/preferences/cubit/preferences_cubit.dart';
import 'application/theme/cubit/theme_cubit.dart';
import 'domain/arguments/argument_parser.dart';

Future<void> main(List<String> args) async {
  // Parse command-line arguments.
  final parser = ArgumentParser(args);
  await parser.parse();

  final sharedPreferences = await SharedPreferences.getInstance();
  final prefs = Preferences(sharedPreferences);

  AppLogger().initialize();

  // `-t` or `--toggle` flag detected.
  if (parser.toggleFlagged) await ActiveWindow().toggle();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AppCubit(prefs),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => PreferencesCubit(prefs),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => ThemeCubit(prefs),
        ),
      ],
      child: AppWidget(),
    ),
  );
}
