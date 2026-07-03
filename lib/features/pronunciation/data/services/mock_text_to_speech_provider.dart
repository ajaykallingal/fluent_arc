import 'dart:async';
import '../../domain/services/text_to_speech_provider.dart';

class MockTextToSpeechProvider implements TextToSpeechProvider {
  final StreamController<bool> _playbackController =
      StreamController<bool>.broadcast();
  Timer? _playbackTimer;

  @override
  Stream<bool> get isPlaying => _playbackController.stream;

  @override
  Future<void> speak(String text) async {
    _playbackTimer?.cancel();
    _playbackController.add(true);

    // Simulate duration proportional to phrase length
    final durationMs = (text.split(' ').length * 400).clamp(1000, 5000);
    _playbackTimer = Timer(Duration(milliseconds: durationMs), () {
      _playbackController.add(false);
    });
  }

  @override
  Future<void> stop() async {
    _playbackTimer?.cancel();
    _playbackController.add(false);
  }
}
