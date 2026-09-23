import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/analysis_model.dart';

/// Pressure, summary and techniques produced by an analyzer engine.
class RawAnalysis {
  const RawAnalysis({required this.pressure, required this.summary, required this.techniques});

  final int pressure;
  final String summary;
  final List<TechniqueModel> techniques;

  factory RawAnalysis.fromJson(Map<String, dynamic> json) => RawAnalysis(
        pressure: ((json['pressure'] as num?)?.round() ?? 0).clamp(0, 100),
        summary: (json['summary'] ?? '').toString().trim(),
        techniques: ((json['techniques'] as List?) ?? const [])
            .whereType<Map>()
            .map((t) => TechniqueModel.fromJson(t.cast<String, dynamic>()))
            .where((t) => t.name.isNotEmpty)
            .take(4)
            .toList(),
      );
}

abstract interface class RemoteAnalyzerDataSource {
  Future<RawAnalysis> analyze({
    required String apiKey,
    required String text,
    Uint8List? image,
    String? imageMimeType,
  });
}

/// Calls the Claude Messages API (raw HTTP: there is no official Dart SDK).
class ClaudeAnalyzerDataSource implements RemoteAnalyzerDataSource {
  ClaudeAnalyzerDataSource(this._client);
  final http.Client _client;

  static const _system =
      'You are the analysis engine of Motive, an app that exposes persuasion and manipulation techniques. '
      'Analyze the social media post the user provides (as text, a screenshot, or both). '
      'pressure: an integer 0-100 for how hard the post pushes the reader. '
      'summary: one blunt sentence about what the post wants from the reader. '
      'techniques: 2 to 4 techniques, strongest first. Each has a short name (e.g. Scarcity, Us vs. Them, Fear Appeal, '
      'Social Proof, Authority, Flattery), a short exact quote from the post of at most 12 words, one plain sentence on '
      'how it works on the reader, and an intensity from 1 (light) to 3 (heavy). '
      'If the post uses no manipulation, return pressure under 15 and an empty techniques array.';

  static const _schema = {
    'type': 'object',
    'properties': {
      'pressure': {'type': 'integer'},
      'summary': {'type': 'string'},
      'techniques': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
            'quote': {'type': 'string'},
            'how': {'type': 'string'},
            'intensity': {'type': 'integer'},
          },
          'required': ['name', 'quote', 'how', 'intensity'],
          'additionalProperties': false,
        },
      },
    },
    'required': ['pressure', 'summary', 'techniques'],
    'additionalProperties': false,
  };

  @override
  Future<RawAnalysis> analyze({
    required String apiKey,
    required String text,
    Uint8List? image,
    String? imageMimeType,
  }) async {
    final hasText = text.trim().isNotEmpty;
    final content = <Map<String, dynamic>>[
      if (image != null)
        {
          'type': 'image',
          'source': {'type': 'base64', 'media_type': imageMimeType ?? 'image/png', 'data': base64Encode(image)},
        },
      {
        'type': 'text',
        'text': image != null ? 'Analyze this post${hasText ? ':\n$text' : '.'}' : 'Post:\n$text',
      },
    ];

    final body = jsonEncode({
      'model': AppConstants.claudeModel,
      'max_tokens': 16000,
      'system': _system,
      'fallbacks': 'default',
      'output_config': {
        'effort': 'low',
        'format': {'type': 'json_schema', 'schema': _schema},
      },
      'messages': [
        {'role': 'user', 'content': content},
      ],
    });

    final http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse(AppConstants.claudeEndpoint),
            headers: {
              'content-type': 'application/json',
              'x-api-key': apiKey,
              'anthropic-version': AppConstants.claudeApiVersion,
              'anthropic-beta': AppConstants.claudeFallbackBeta,
              // Required only when the app runs in a browser (Flutter web).
              if (kIsWeb) 'anthropic-dangerous-direct-browser-access': 'true',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw const NetworkException('The analyzer took too long to answer.');
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ServerException('Unexpected answer from the analyzer (HTTP ${res.statusCode}).', statusCode: res.statusCode);
    }

    if (res.statusCode != 200) {
      final apiMessage = (json['error'] as Map?)?['message']?.toString();
      throw ServerException(_friendlyError(res.statusCode, apiMessage), statusCode: res.statusCode);
    }

    if (json['stop_reason'] == 'refusal') {
      throw const ServerException('Claude declined to analyze this post.');
    }

    final blocks = (json['content'] as List? ?? const []).whereType<Map>();
    final textBlock = blocks.firstWhere((b) => b['type'] == 'text', orElse: () => const {});
    final raw = textBlock['text']?.toString();
    if (raw == null || raw.isEmpty) {
      throw const ServerException('The analyzer returned an empty answer. Try again.');
    }
    try {
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
      return RawAnalysis.fromJson(jsonDecode(match?.group(0) ?? raw) as Map<String, dynamic>);
    } catch (_) {
      throw const ServerException("The analyzer couldn't read that one. Try pasting the text of the post instead.");
    }
  }

  String _friendlyError(int status, String? apiMessage) => switch (status) {
        401 => 'Your Claude API key was rejected. Check it in Me → Analyzer engine.',
        403 => 'This API key is not allowed to use the analyzer model.',
        413 => 'That screenshot is too large. Try a smaller one.',
        429 => 'Too many requests right now. Wait a moment and try again.',
        529 || 503 => 'Claude is overloaded right now. Try again in a minute.',
        _ => apiMessage ?? 'The analyzer failed (HTTP $status).',
      };
}
