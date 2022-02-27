import 'package:native_platform/src/process.dart';
import 'package:native_platform/src/window.dart';
import 'package:test/test.dart';

void main() {
  const fakeId = 8172363;
  const fakeExecutable = 'firefox';
  const fakePid = 1723128;
  final fakeProcess = Process(executable: fakeExecutable, pid: fakePid);
  final fakeTitle = 'Google -- Mozilla Firefox';

  final window = Window(id: fakeId, process: fakeProcess, title: fakeTitle);

  group('Window', () {
    test('can instantiate', () {
      expect(window.runtimeType, Window);
    });

    test('can be copied', () {
      final copiedWindow = window.copyWith();
      expect(copiedWindow, window);
    });

    test('can be copied with changes', () {
      final alteredWindow = window.copyWith(
        title: 'Amazing Burritos -- Mozilla Firefox',
      );
      expect(alteredWindow == window, false);
    });
  });
}
