import 'package:flutter/material.dart';
import 'package:nyrna/nyrna.dart';
import 'package:nyrna/screens/apps_screen.dart';

/// Intermediate loading screen while verifying that Nyrna's dependencies are
/// available. If they are not an error message is shown, preventing a crash.
class LoadingScreen extends StatefulWidget {
  static const id = 'loading_screen';

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<bool>(
        future: Nyrna.checkDependencies(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            bool dependenciesPresent = snapshot.data;
            if (dependenciesPresent) {
              // Slightly delay required so we don't push the main
              // screen while the build method is still executing.
              Future.microtask(() {
                Navigator.pushReplacementNamed(context, RunningAppsScreen.id);
              });
            } else {
              return Center(
                child: Card(
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('''
Dependency check failed.

Please make sure you have installed Nyrna's dependencies.

(On Linux this would be wmctrl and xdotool)
                    '''),
                  ),
                ),
              );
            }
          }

          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
