// ignore: depend_on_referenced_packages
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'flutter_apple_llm',
    dartOut: "lib/src/generated/message.g.dart",
    dartOptions: DartOptions(),
    swiftOut: "ios/Classes/Message.swift",
    swiftOptions: SwiftOptions(),
  ),
)
@HostApi()
abstract class FlutterAppleLlmApi {
  bool isAvailable();
  String createSession([String? instructions]);
  @async
  void respond(String modelId, String content);
  void deleteSession(String sessionId);
}

@EventChannelApi()
abstract class FlutterAppleLlmEvents {
  Message onResponse();
}

class Message {
  Message(this.modelId, this.content);

  String modelId;
  String content;
}
