abstract class TextToSpeechProvider {
  Stream<bool> get isPlaying;

  Future<void> speak(String text);

  Future<void> stop();
}
