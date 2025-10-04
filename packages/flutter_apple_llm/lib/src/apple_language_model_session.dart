import 'dart:async';

import 'generated/message.g.dart';

class AppleLanguageModelSession {
  AppleLanguageModelSession._(this.id);

  static final _api = FlutterAppleLlmApi();

  final String id;

  var _isDisposed = false;
  bool get isDisposed => _isDisposed;

  EventSink<String>? _sink;

  bool get isResponding => _sink != null;

  Stream<String> respond(String content) {
    if (isDisposed) {
      throw StateError('Session is already destroyed.');
    } else if (isResponding) {
      throw StateError('Already responding.');
    }

    final response = onResponse()
        .where((e) => e.modelId == id)
        .map((e) => e.content);

    final streamController = StreamController<String>();
    _sink = streamController.sink;
    final subscription = response.listen((e) {
      if (streamController.isClosed) return;
      streamController.add(e);
    });
    streamController.onCancel = () {
      subscription.cancel();
      streamController.close();
      _sink = null;
    };

    Future(() async {
      try {
        await _api.respond(id, content);
      } catch (e) {
        streamController.addError(e);
      }

      streamController.close();
      _sink = null;
    });

    return streamController.stream;
  }

  Future<void> dispose() async {
    if (isDisposed) return;
    _sink?.close();
    _sink = null;
    await _api.deleteSession(id);
    _isDisposed = true;
  }

  static Future<AppleLanguageModelSession> start([String? instructions]) async {
    final id = await _api.createSession("""
文章のみ応答してください。
日本語で応答してください。
Markdown形式で応答してください。

${instructions ?? ""}
""");
    return AppleLanguageModelSession._(id);
  }

  static Future<bool> isAvailable() {
    return _api.isAvailable();
  }
}
