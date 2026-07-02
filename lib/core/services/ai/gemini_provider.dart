import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'ai_provider.dart';

class GeminiProvider implements AiProvider {
  final String _apiKey;
  late final GenerativeModel _model;

  GeminiProvider({required String apiKey}) : _apiKey = apiKey {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  String _cleanJsonOutput(String responseText) {
    var cleaned = responseText.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }

  @override
  Future<String> generateText(String prompt) async {
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? '';
  }

  @override
  Future<String> generateChatResponse(List<AiChatMessage> history, String newMessage) async {
    final chatContents = <Content>[];
    
    // Add system context first
    chatContents.add(Content.text(
      'System: You are FluentArc, a friendly, encouraging, and professional AI English Tutor. '
      'Your task is to engage in natural conversation with the student, correct any blatant grammar mistakes '
      'they make within your conversation gently, and prompt them to keep talking. Keep responses relatively short.'
    ));

    for (final msg in history) {
      if (msg.role == 'user') {
        chatContents.add(Content.text('Student: ${msg.text}'));
      } else {
        chatContents.add(Content.text('Tutor: ${msg.text}'));
      }
    }
    
    chatContents.add(Content.text('Student: $newMessage'));

    final response = await _model.generateContent(chatContents);
    return response.text ?? '';
  }

  @override
  Future<AiGrammarAnalysis> analyzeGrammar(String text) async {
    final prompt = '''
Analyze the following sentence for grammar and syntax mistakes.
Sentence: "$text"

Return a JSON object containing:
{
  "originalSentence": "$text",
  "correctedSentence": "<The corrected sentence, or the original if it is correct>",
  "explanation": "<Explain the mistakes and why they were corrected. If correct, provide a positive encouragement and explain any advanced nuance>",
  "grammarScore": <An integer from 0 to 100 based on grammatical correctness>
}

Provide ONLY the raw JSON string. Do not include markdown code blocks.
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final responseText = response.text ?? '';
    
    try {
      final jsonString = _cleanJsonOutput(responseText);
      final Map<String, dynamic> data = jsonDecode(jsonString);
      return AiGrammarAnalysis.fromJson(data);
    } catch (e) {
      // Graceful fallback if JSON decoding fails
      return AiGrammarAnalysis(
        originalSentence: text,
        correctedSentence: text,
        explanation: 'Sorry, I failed to structure the analysis: $e.\nRaw feedback: $responseText',
        grammarScore: 80,
      );
    }
  }

  @override
  Future<List<AiVocabularyWord>> suggestVocabulary(String topic, {String difficulty = 'Intermediate'}) async {
    final prompt = '''
Suggest exactly 3 vocabulary words at the "$difficulty" difficulty level related to the topic: "$topic".
Each word must include a definition and a realistic example sentence.

Return a JSON array of objects:
[
  {
    "word": "<word>",
    "definition": "<definition>",
    "example": "<example sentence>",
    "difficulty": "$difficulty"
  }
]

Provide ONLY the raw JSON array string. Do not include markdown code blocks.
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final responseText = response.text ?? '';

    try {
      final jsonString = _cleanJsonOutput(responseText);
      final List<dynamic> data = jsonDecode(jsonString);
      return data.map((item) => AiVocabularyWord.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      // Fallback
      return [
        AiVocabularyWord(
          word: 'Fluent',
          definition: 'Able to express oneself easily and articulately.',
          example: 'Daily practice helps you become fluent.',
          difficulty: difficulty,
        ),
      ];
    }
  }
}
