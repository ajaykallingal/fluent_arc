abstract class SpeechToTextProvider {
  Stream<bool> get isListening;
  
  Future<void> startListening();
  
  Future<String> stopListening();
  
  Future<void> cancel();
}
