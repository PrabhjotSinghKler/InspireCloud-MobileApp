import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_performance/firebase_performance.dart';
import '../services/logging_service.dart';

class OpenAIService {
  final String _apiKey;
  final LoggingService _loggingService; // Injected
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  OpenAIService(this._apiKey, this._loggingService) {
    if (_apiKey.isEmpty) {
      throw Exception('OpenAI API key is not set in .env file');
    }
  }

  Future<String> generateQuote({
    required String prompt,
    required String category,
  }) async {
    final HttpMetric metric = FirebasePerformance.instance.newHttpMetric(
      _baseUrl,
      HttpMethod.Post,
    );

    try {
      if (category.isEmpty) {
        throw Exception('Category cannot be empty');
      }

      final sanitizedPrompt = _sanitizeInput(prompt);
      final sanitizedCategory = _sanitizeInput(category);

      if (sanitizedPrompt.length > 500) {
        throw Exception('Prompt is too long (maximum 500 characters)');
      }
      if (sanitizedCategory.length > 50) {
        throw Exception('Category is too long (maximum 50 characters)');
      }

      final forbiddenWords = ['inappropriate', 'offensive', 'harmful'];
      for (final word in forbiddenWords) {
        if (sanitizedPrompt.toLowerCase().contains(word) ||
            sanitizedCategory.toLowerCase().contains(word)) {
          throw Exception('Input contains inappropriate content');
        }
      }

      final String finalPrompt =
          sanitizedPrompt.isEmpty
              ? 'Generate an inspirational quote about $sanitizedCategory. Just return the quote text only, without attribution or commentary.'
              : 'Generate an inspirational quote about $sanitizedCategory with the following theme: $sanitizedPrompt. Just return the quote text only, without attribution or commentary.';

      await metric.start();
      final startTime = DateTime.now();

      await _loggingService.log(
        type: 'activity',
        event: 'generate_quote_started',
        metadata: {
          'category': sanitizedCategory,
          'promptLength': sanitizedPrompt.length,
          'timestamp': startTime.toIso8601String(),
        },
      );

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'gpt-3.5-turbo',
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a helpful assistant that generates inspirational quotes. Never include harmful, offensive, or inappropriate content.',
                },
                {'role': 'user', 'content': finalPrompt},
              ],
              'temperature': 0.7,
              'max_tokens': 100,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout:
                () => throw Exception('Request timed out. Please try again.'),
          );

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      metric.httpResponseCode = response.statusCode;
      metric.responseContentType = response.headers['content-type'] ?? '';
      metric.responsePayloadSize = response.bodyBytes.length;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final sanitizedResponse = _sanitizeInput(
          content.replaceAll('"', '').trim(),
        );

        if (sanitizedResponse.isEmpty) {
          throw Exception('Received empty response from API');
        }

        await _loggingService.log(
          type: 'activity',
          event: 'generate_quote_success',
          metadata: {
            'category': sanitizedCategory,
            'responseTimeMs': responseTime,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        return sanitizedResponse;
      } else {
        await _loggingService.log(
          type: 'error',
          event: 'generate_quote_failed',
          metadata: {
            'statusCode': response.statusCode,
            'responseBody': response.body,
            'category': sanitizedCategory,
          },
        );
        throw Exception('Failed to generate quote. Please try again.');
      }
    } catch (e, stackTrace) {
      await _loggingService.logError(
        e,
        stackTrace,
        reason: 'generate_quote_exception',
      );
      rethrow;
    } finally {
      await metric.stop();
    }
  }

  // Helper method to sanitize inputs
  String _sanitizeInput(String input) {
    // Remove potentially harmful characters
    return input
        .replaceAll(RegExp(r'[<>{}]'), '') // Remove HTML/script tags
        .replaceAll(
          RegExp(r'[\\/;]'),
          '',
        ); // Remove other potentially harmful chars
  }
}
