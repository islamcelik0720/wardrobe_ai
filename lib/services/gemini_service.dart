import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/clothing_item.dart';

class GeminiService {
  static const String _modelName = 'gemini-3.5-flash-lite';

  String get _apiKey {
    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim();

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY bulunamadı. .env dosyasını kontrol et.');
    }

    return apiKey;
  }

  Uri get _endpoint {
    return Uri.parse(
      'https://generativelanguage.googleapis.com/'
      'v1beta/models/$_modelName:generateContent',
    );
  }

  Future<String> _sendPrompt(String prompt) async {
    final response = await http
        .post(
          _endpoint,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {'maxOutputTokens': 700},
          }),
        )
        .timeout(const Duration(seconds: 45));

    final dynamic decodedBody;

    try {
      decodedBody = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Gemini geçersiz bir sunucu yanıtı döndürdü. '
        'HTTP ${response.statusCode}',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String errorMessage = 'Gemini isteği başarısız oldu.';

      if (decodedBody is Map<String, dynamic>) {
        final error = decodedBody['error'];

        if (error is Map<String, dynamic>) {
          errorMessage = error['message']?.toString() ?? errorMessage;
        }
      }

      throw Exception('$errorMessage (HTTP ${response.statusCode})');
    }

    if (decodedBody is! Map<String, dynamic>) {
      throw Exception('Gemini yanıt biçimi geçersiz.');
    }

    final candidates = decodedBody['candidates'];

    if (candidates is! List || candidates.isEmpty) {
      final promptFeedback = decodedBody['promptFeedback'];

      if (promptFeedback != null) {
        throw Exception('Gemini yanıt üretmedi: $promptFeedback');
      }

      throw Exception('Gemini herhangi bir yanıt üretmedi.');
    }

    final firstCandidate = candidates.first;

    if (firstCandidate is! Map<String, dynamic>) {
      throw Exception('Gemini aday yanıtı geçersiz.');
    }

    final content = firstCandidate['content'];

    if (content is! Map<String, dynamic>) {
      throw Exception('Gemini yanıt içeriği bulunamadı.');
    }

    final parts = content['parts'];

    if (parts is! List || parts.isEmpty) {
      throw Exception('Gemini yanıt metni bulunamadı.');
    }

    final textParts = parts
        .whereType<Map<String, dynamic>>()
        .map((part) => part['text']?.toString() ?? '')
        .where((text) => text.trim().isNotEmpty)
        .toList();

    final result = textParts.join('\n').trim();

    if (result.isEmpty) {
      throw Exception('Gemini boş yanıt döndürdü.');
    }

    return result;
  }

  Future<String> generateTestResponse() async {
    try {
      return await _sendPrompt('''
Yalnızca Türkçe cevap ver.

WardrobeAI isimli akıllı gardırop uygulaması için sıcak ve kısa
bir hoş geldin mesajı yaz. En fazla iki cümle kullan.
''');
    } catch (e) {
      throw Exception('Gemini testi başarısız oldu: $e');
    }
  }

  Future<String> generateOutfitSuggestion(ClothingItem clothing) async {
    try {
      final String brand = clothing.brand?.trim().isNotEmpty == true
          ? clothing.brand!.trim()
          : 'Belirtilmedi';

      final String notes = clothing.notes?.trim().isNotEmpty == true
          ? clothing.notes!.trim()
          : 'Not bulunmuyor';

      final prompt =
          '''
Sen WardrobeAI isimli akıllı gardırop uygulamasında çalışan
profesyonel bir stil danışmanısın.

Aşağıdaki kıyafete göre Türkçe bir kombin önerisi oluştur:

Kategori: ${clothing.category}
Renk: ${clothing.color}
Kumaş: ${clothing.fabric}
Mevsim: ${clothing.season}
Marka: $brand
Kullanıcı notu: $notes

Kurallar:
- Yalnızca Türkçe cevap ver.
- Kıyafetin kategorisini dikkate al.
- Uyumlu üst, alt, ayakkabı ve gerekiyorsa dış giyim öner.
- Uyumlu renkleri açıkça belirt.
- Kısa, anlaşılır ve uygulanabilir öneriler yaz.
- En fazla 5 madde oluştur.
- Başlık ve numaralandırma kullanma.
- Her maddeyi "•" işaretiyle başlat.
''';

      return await _sendPrompt(prompt);
    } catch (e) {
      throw Exception('AI kombin önerisi oluşturulamadı: $e');
    }
  }
}
