import 'ai_provider.dart';

class MockAiProvider implements AiProvider {
  @override
  Future<String> generateText(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return 'This is a mock response from MockAiProvider to the prompt: "$prompt"';
  }

  @override
  Future<String> generateChatResponse(
    List<AiChatMessage> history,
    String newMessage,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    final lowerMessage = newMessage.toLowerCase();
    if (lowerMessage.contains('hello') || lowerMessage.contains('hi')) {
      return 'Hello there! I am your AI language tutor. How can I help you practice today? We can talk about your day, practice grammar, or learn new vocabulary.';
    } else if (lowerMessage.contains('help') || lowerMessage.contains('how')) {
      return 'I can assist you with accent coaching, pronunciation feedback, grammar checking, and vocabulary enhancement. Just ask me to analyze any phrase!';
    } else if (lowerMessage.contains('thank')) {
      return 'You are very welcome! Keep practicing, consistency is the key to fluency.';
    }

    return 'That is interesting! Could you tell me more about that? Practicing longer sentences helps improve your overall flow and rhythm.';
  }

  @override
  Future<AiGrammarAnalysis> analyzeGrammar(String text) async {
    await Future.delayed(const Duration(seconds: 1));

    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return AiGrammarAnalysis(
        originalSentence: '',
        correctedSentence: '',
        explanation: 'Please provide some text to analyze.',
        grammarScore: 100,
      );
    }

    // Standard hardcoded mock rules for common grammar issues
    final lowerText = trimmedText.toLowerCase();
    if (lowerText.contains('i is') || lowerText.contains('i are')) {
      return AiGrammarAnalysis(
        originalSentence: trimmedText,
        correctedSentence: trimmedText
            .replaceAll(RegExp('i is', caseSensitive: false), 'I am')
            .replaceAll(RegExp('i are', caseSensitive: false), 'I am'),
        explanation:
            'In English, the first-person singular pronoun "I" always takes the verb form "am" in the present tense, not "is" or "are".',
        grammarScore: 75,
      );
    }

    if (lowerText.contains('he go ') ||
        lowerText.contains('she go ') ||
        lowerText.contains('it go ')) {
      return AiGrammarAnalysis(
        originalSentence: trimmedText,
        correctedSentence: trimmedText.replaceAll(
          RegExp(' go ', caseSensitive: false),
          ' goes ',
        ),
        explanation:
            'Third-person singular subjects (he, she, it) require the verb to have an "-es" or "-s" ending in the simple present tense (e.g., "goes").',
        grammarScore: 80,
      );
    }

    if (lowerText.contains('she don\'t') || lowerText.contains('he don\'t')) {
      return AiGrammarAnalysis(
        originalSentence: trimmedText,
        correctedSentence: trimmedText.replaceAll(
          RegExp('don\'t', caseSensitive: false),
          'doesn\'t',
        ),
        explanation:
            'Use "doesn\'t" (does not) for third-person singular subjects (he, she, it). "Don\'t" is used for I, you, we, and they.',
        grammarScore: 85,
      );
    }

    // Default: text looks fine
    return AiGrammarAnalysis(
      originalSentence: trimmedText,
      correctedSentence: trimmedText,
      explanation:
          'Your sentence is grammatically correct! Good job structuring the sentence.',
      grammarScore: 100,
    );
  }

  @override
  Future<List<AiVocabularyWord>> suggestVocabulary(
    String topic, {
    String difficulty = 'Intermediate',
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final lowerTopic = topic.toLowerCase();
    if (lowerTopic.contains('travel')) {
      return [
        AiVocabularyWord(
          word: 'Itinerary',
          definition:
              'A planned route or journey, including dates and places to visit.',
          example:
              'We formulated a strict itinerary for our two-week vacation in Europe.',
          difficulty: difficulty,
        ),
        AiVocabularyWord(
          word: 'Wanderlust',
          definition: 'A strong desire to travel and explore the world.',
          example:
              'Her wanderlust led her to abandon her desk job and travel Asia.',
          difficulty: difficulty,
        ),
        AiVocabularyWord(
          word: 'Souvenir',
          definition:
              'A thing that is kept as a reminder of a person, place, or event.',
          example: 'I bought a tiny model of the Eiffel Tower as a souvenir.',
          difficulty: difficulty,
        ),
      ];
    } else if (lowerTopic.contains('food') || lowerTopic.contains('cooking')) {
      return [
        AiVocabularyWord(
          word: 'Gourmet',
          definition:
              'High-quality or exotic food, or a person who appreciates fine dining.',
          example:
              'He opened a gourmet restaurant serving locally sourced ingredients.',
          difficulty: difficulty,
        ),
        AiVocabularyWord(
          word: 'Cuisine',
          definition:
              'A style or method of cooking, especially as characteristic of a particular country or region.',
          example:
              'Italian cuisine is famous for its simple but delicious pasta dishes.',
          difficulty: difficulty,
        ),
        AiVocabularyWord(
          word: 'Delectable',
          definition: 'Delicious, highly pleasing to the taste.',
          example: 'The bakery was filled with delectable cakes and pastries.',
          difficulty: difficulty,
        ),
      ];
    }

    // Default suggestions
    return [
      AiVocabularyWord(
        word: 'Acquire',
        definition:
            'To buy or obtain an asset or object, or to learn a new skill.',
        example:
            'It takes time to acquire a native-like accent in a foreign tongue.',
        difficulty: difficulty,
      ),
      AiVocabularyWord(
        word: 'Fluency',
        definition: 'The ability to express oneself easily and articulately.',
        example:
            'Practice speaking daily is the fastest way to achieve fluency.',
        difficulty: difficulty,
      ),
      AiVocabularyWord(
        word: 'Accentuate',
        definition: 'Make more noticeable or prominent.',
        example:
            'Try not to accentuate your errors; focus on speaking smoothly.',
        difficulty: difficulty,
      ),
    ];
  }
}
