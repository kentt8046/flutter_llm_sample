import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_apple_llm_method_channel.dart';

abstract class FlutterAppleLlmPlatform extends PlatformInterface {
  /// Constructs a FlutterAppleLlmPlatform.
  FlutterAppleLlmPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterAppleLlmPlatform _instance = MethodChannelFlutterAppleLlm();

  /// The default instance of [FlutterAppleLlmPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterAppleLlm].
  static FlutterAppleLlmPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterAppleLlmPlatform] when
  /// they register themselves.
  static set instance(FlutterAppleLlmPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
