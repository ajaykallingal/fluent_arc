import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'gemini_provider.dart';
import 'mock_ai_provider.dart';
import 'ollama_provider.dart';

final aiApiKeyProvider = Provider<String>((ref) {
  const fromEnv = String.fromEnvironment('GEMINI_API_KEY');
  if (fromEnv.isNotEmpty) {
    return fromEnv;
  }
  try {
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  } catch (_) {
    return '';
  }
});

final ollamaBaseUrlProvider = Provider<String>((ref) {
  try {
    return dotenv.env['OLLAMA_BASE_URL'] ?? '';
  } catch (_) {
    return '';
  }
});

final ollamaModelProvider = Provider<String>((ref) {
  try {
    return dotenv.env['OLLAMA_MODEL'] ?? 'qwen3:4b';
  } catch (_) {
    return 'qwen3:4b';
  }
});

final aiProvider = Provider<AiProvider>((ref) {
  final ollamaBaseUrl = ref.watch(ollamaBaseUrlProvider);
  if (ollamaBaseUrl.isNotEmpty) {
    final model = ref.watch(ollamaModelProvider);
    return OllamaProvider(baseUrl: ollamaBaseUrl, model: model);
  }

  final key = ref.watch(aiApiKeyProvider);
  if (key.isEmpty) {
    return MockAiProvider();
  }
  return GeminiProvider(apiKey: key);
});

class AiChatMessage {
  final String role; // 'user' or 'model'
  final String text;

  AiChatMessage({required this.role, required this.text});

  Map<String, dynamic> toJson() => {'role': role, 'text': text};
}

class AiGrammarAnalysis {
  final String originalSentence;
  final String correctedSentence;
  final String explanation;
  final int grammarScore; // 0 to 100

  AiGrammarAnalysis({
    required this.originalSentence,
    required this.correctedSentence,
    required this.explanation,
    required this.grammarScore,
  });

  factory AiGrammarAnalysis.fromJson(Map<String, dynamic> json) {
    return AiGrammarAnalysis(
      originalSentence: json['originalSentence'] as String? ?? '',
      correctedSentence: json['correctedSentence'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      grammarScore: json['grammarScore'] as int? ?? 100,
    );
  }

  Map<String, dynamic> toJson() => {
        'originalSentence': originalSentence,
        'correctedSentence': correctedSentence,
        'explanation': explanation,
        'grammarScore': grammarScore,
      };
}

class AiVocabularyWord {
  final String word;
  final String definition;
  final String example;
  final String difficulty; // 'Beginner', 'Intermediate', 'Advanced'

  AiVocabularyWord({
    required this.word,
    required this.definition,
    required this.example,
    required this.difficulty,
  });

  factory AiVocabularyWord.fromJson(Map<String, dynamic> json) {
    return AiVocabularyWord(
      word: json['word'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      example: json['example'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'Intermediate',
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'definition': definition,
        'example': example,
        'difficulty': difficulty,
      };
}

abstract class AiProvider {
  Future<String> generateText(String prompt);
  
  Future<String> generateChatResponse(List<AiChatMessage> history, String newMessage);
  
  Future<AiGrammarAnalysis> analyzeGrammar(String text);
  
  Future<List<AiVocabularyWord>> suggestVocabulary(String topic, {String difficulty = 'Intermediate'});
}

