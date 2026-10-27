import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum LaunchActionType { share, newTask, search }

/// Something the OS asked the app to do: text shared from another app,
/// or a launcher shortcut.
class LaunchAction {
  const LaunchAction(this.type, {this.text = '', this.subject});

  static LaunchAction? fromRaw(Object? raw) {
    if (raw is! Map) return null;
    final text = (raw['text'] as String?) ?? '';
    final subject = raw['subject'] as String?;
    return switch (raw['type']) {
      'share' => LaunchAction(LaunchActionType.share, text: text, subject: subject),
      'new_task' => const LaunchAction(LaunchActionType.newTask),
      'search' => const LaunchAction(LaunchActionType.search),
      _ => null,
    };
  }

  final LaunchActionType type;
  final String text;
  final String? subject;
}

/// Dart side of the `minddrop/platform` channel implemented in MainActivity.kt.
class PlatformBridge {
  PlatformBridge._();

  static const MethodChannel _channel = MethodChannel('minddrop/platform');

  /// Called for actions that arrive while the app is already running.
  static ValueChanged<LaunchAction>? onAction;

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAction') {
        final action = LaunchAction.fromRaw(call.arguments);
        if (action != null) onAction?.call(action);
      }
      return null;
    });
  }

  static Future<T?> _safe<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint('PlatformBridge.$method failed: $e');
      return null;
    }
  }

  /// The action the app was launched with, if any. Consumed on read.
  static Future<LaunchAction?> takeLaunchAction() async =>
      LaunchAction.fromRaw(await _safe<Object?>('takeLaunchAction'));

  static Future<String?> timeZone() => _safe<String>('getTimeZone');

  static Future<String?> appVersion() => _safe<String>('getAppVersion');

  /// Lets the user pick where to save [content].
  /// Returns true when saved, null when cancelled; throws [PlatformException] on failure.
  static Future<bool?> saveFile(String name, String content) =>
      _channel.invokeMethod<bool>('saveFile', {'name': name, 'content': content});

  /// Lets the user pick a file and returns its text, or null when cancelled.
  /// Throws [PlatformException] on failure.
  static Future<String?> openFile() => _channel.invokeMethod<String>('openFile');

  /// Opens the system share sheet with [content] attached as a file.
  static Future<void> shareFile(String name, String content, {String? subject}) =>
      _channel.invokeMethod<bool>(
        'shareFile',
        {'name': name, 'content': content, 'subject': subject},
      );
}
