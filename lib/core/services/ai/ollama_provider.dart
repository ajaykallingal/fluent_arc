import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

class OllamaProvider implements AiProvider {
  final String _baseUrl;
  final String _model;
  final http.Client _client;

  OllamaProvider({
    required String baseUrl,
    required String model,
    http.Client? client,
  })  : _baseUrl = baseUrl,
        _model = model,
        _client = client ?? http.Client();

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
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': _model,
        'prompt': prompt,
        'stream': false,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return json['response'] as String? ?? '';
    } else {
      throw Exception('Ollama error: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Future<String> generateChatResponse(List<AiChatMessage> history, String newMessage) async {
    final messages = <Map<String, String>>[];
    
    // System instruction
    messages.add({
      'role': 'system',
      'content': 'You are FluentArc, a friendly, encouraging, and professional AI English Tutor. '
                 'Your task is to engage in natural conversation with the student, correct any blatant grammar mistakes '
                 'they make within your conversation gently, and prompt them to keep talking. Keep responses relatively short.'
    });

    for (final msg in history) {
      messages.add({
        'role': msg.role == 'user' ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    messages.add({
      'role': 'user',
      'content': newMessage,
    });

    final response = await _client.post(
      Uri.parse('$_baseUrl/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'stream': false,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final message = json['message'] as Map<String, dynamic>?;
      return message?['content'] as String? ?? '';
    } else {
      throw Exception('Ollama error: ${response.statusCode} ${response.body}');
    }
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

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _model,
          'prompt': prompt,
          'format': 'json',
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        final responseText = json['response'] as String? ?? '';
        final jsonString = _cleanJsonOutput(responseText);
        final Map<String, dynamic> data = jsonDecode(jsonString);
        return AiGrammarAnalysis.fromJson(data);
      } else {
        throw Exception('Ollama status code ${response.statusCode}');
      }
    } catch (e) {
      return AiGrammarAnalysis(
        originalSentence: text,
        correctedSentence: text,
        explanation: 'Sorry, I failed to structure the analysis locally via Ollama: $e.',
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

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _model,
          'prompt': prompt,
          'format': 'json',
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        final responseText = json['response'] as String? ?? '';
        final jsonString = _cleanJsonOutput(responseText);
        final List<dynamic> data = jsonDecode(jsonString);
        return data.map((item) => AiVocabularyWord.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Ollama status code ${response.statusCode}');
      }
    } catch (e) {
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
