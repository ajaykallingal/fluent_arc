import 'dart:async';
import '../../domain/services/speech_to_text_provider.dart';

class MockSpeechToTextProvider implements SpeechToTextProvider {
  final StreamController<bool> _listeningController =
      StreamController<bool>.broadcast();
  String _simulatedTranscript = '';

  void setSimulatedTranscript(String transcript) {
    _simulatedTranscript = transcript;
  }

  @override
  Stream<bool> get isListening => _listeningController.stream;

  @override
  Future<void> startListening() async {
    _listeningController.add(true);
  }

  @override
  Future<String> stopListening() async {
    _listeningController.add(false);
    await Future.delayed(const Duration(milliseconds: 500));
    return _simulatedTranscript;
  }

  @override
  Future<void> cancel() async {
    _listeningController.add(false);
  }
}
