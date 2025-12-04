import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:viam_pixel4a_sensors/providers/ai_settings_provider.dart';

/// Minimal, generic AI client that assumes an OpenAI-compatible
/// chat-completions endpoint. You can point this at any compatible
/// API (local or cloud) by changing the base URL and model in the UI.
class AiClient {
  final AiSettingsProvider settingsProvider;

  AiClient({required this.settingsProvider});

  Future<String> sendChat({
    required String message,
    List<Map<String, String>> history = const [],
  }) async {
    final settings = settingsProvider.settings;

    if (settings.baseUrl.isEmpty || settings.apiKey.isEmpty) {
      throw StateError('AI API not configured');
    }

    final uri = Uri.parse(settings.baseUrl);

    final payload = <String, dynamic>{
      'model': settings.model,
      'messages': [
        for (final h in history)
          {
            'role': h['role'] ?? 'user',
            'content': h['content'] ?? '',
          },
        {
          'role': 'user',
          'content': message,
        },
      ],
      // You can read this flag server-side to allow adult behavior.
      'metadata': {
        'adultMode': settings.adultMode,
      },
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${settings.apiKey}',
    };

    final response =
    await http.post(uri, headers: headers, body: jsonEncode(payload));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'AI request failed: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    // This assumes OpenAI-style response; adjust if your backend differs.
    final choices = decoded['choices'] as List<dynamic>?;

    if (choices == null || choices.isEmpty) {
      throw StateError('AI response missing choices');
    }

    final messageMap = choices.first['message'] as Map<String, dynamic>?;
    final content = messageMap?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw StateError('AI response missing content');
    }
    return content;
  }
}
