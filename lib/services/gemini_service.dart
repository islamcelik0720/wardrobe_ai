import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/ai_outfit_result.dart';
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

  Future<AiOutfitResult> _sendStructuredOutfitPrompt(String prompt) async {
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
            'generationConfig': {
              'maxOutputTokens': 900,
              'responseMimeType': 'application/json',
              'responseSchema': {
                'type': 'object',
                'properties': {
                  'suggestion': {
                    'type': 'string',
                    'description':
                        'Türkçe, maddeler hâlinde hazırlanmış kombin açıklaması.',
                  },
                  'selectedClothingIds': {
                    'type': 'array',
                    'description':
                        'Yalnızca verilen gardıroptan seçilen kıyafet belge kimlikleri.',
                    'items': {'type': 'string'},
                  },
                },
                'required': ['suggestion', 'selectedClothingIds'],
              },
            },
          }),
        )
        .timeout(const Duration(seconds: 45));

    final dynamic decodedResponse;

    try {
      decodedResponse = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Gemini geçersiz bir sunucu yanıtı döndürdü. '
        'HTTP ${response.statusCode}',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String errorMessage = 'Gemini isteği başarısız oldu.';

      if (decodedResponse is Map<String, dynamic>) {
        final error = decodedResponse['error'];

        if (error is Map<String, dynamic>) {
          errorMessage = error['message']?.toString() ?? errorMessage;
        }
      }

      throw Exception('$errorMessage (HTTP ${response.statusCode})');
    }

    if (decodedResponse is! Map<String, dynamic>) {
      throw Exception('Gemini yanıt biçimi geçersiz.');
    }

    final candidates = decodedResponse['candidates'];

    if (candidates is! List || candidates.isEmpty) {
      throw Exception('Gemini herhangi bir kombin üretmedi.');
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

    final firstPart = parts.first;

    if (firstPart is! Map<String, dynamic>) {
      throw Exception('Gemini yanıt parçası geçersiz.');
    }

    final String jsonText = firstPart['text']?.toString().trim() ?? '';

    if (jsonText.isEmpty) {
      throw Exception('Gemini boş JSON yanıtı döndürdü.');
    }

    final dynamic decodedResult;

    try {
      decodedResult = jsonDecode(jsonText);
    } catch (_) {
      throw Exception('Gemini kombin sonucunu geçerli JSON olarak döndürmedi.');
    }

    if (decodedResult is! Map<String, dynamic>) {
      throw Exception('AI kombin sonucu beklenen yapıda değil.');
    }

    final result = AiOutfitResult.fromMap(decodedResult);

    if (result.suggestion.isEmpty) {
      throw Exception('AI kombin açıklaması boş geldi.');
    }

    if (result.selectedClothingIds.isEmpty) {
      throw Exception('AI herhangi bir kıyafet seçmedi.');
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

  Future<String> generateWardrobeOutfit(List<ClothingItem> clothes) async {
    try {
      if (clothes.isEmpty) {
        throw Exception(
          'Kombin oluşturmak için gardıropta kıyafet bulunmuyor.',
        );
      }

      final wardrobeText = clothes
          .asMap()
          .entries
          .map((entry) {
            final int number = entry.key + 1;
            final ClothingItem item = entry.value;

            final String brand = item.brand?.trim().isNotEmpty == true
                ? item.brand!.trim()
                : 'Belirtilmedi';

            return '''
$number. Kategori: ${item.category}
   Renk: ${item.color}
   Kumaş: ${item.fabric}
   Mevsim: ${item.season}
   Marka: $brand
   Favori: ${item.favorite ? "Evet" : "Hayır"}
''';
          })
          .join('\n');

      final prompt =
          '''
Sen WardrobeAI isimli akıllı gardırop uygulamasında çalışan
profesyonel bir stil danışmanısın.

Kullanıcının gardırobunda aşağıdaki kıyafetler bulunuyor:

$wardrobeText

Yalnızca bu gardıropta bulunan kıyafetleri kullanarak uyumlu
bir günlük kombin oluştur.

Kurallar:
- Yalnızca Türkçe cevap ver.
- Gardıropta bulunmayan bir kıyafeti seçme.
- Mümkünse bir üst giyim, bir alt giyim, bir ayakkabı ve
  uygun olduğunda bir dış giyim seç.
- Seçtiğin her parçanın kategori ve rengini açıkça yaz.
- Parçaların neden uyumlu olduğunu kısa şekilde açıkla.
- Cevabı kısa ve uygulanabilir tut.
- En fazla 5 madde oluştur.
- Her maddeyi "•" işaretiyle başlat.
- Markdown başlığı ve numaralandırma kullanma.
''';

      return await _sendPrompt(prompt);
    } catch (e) {
      throw Exception('Gardıroptan AI kombini oluşturulamadı: $e');
    }
  }

  Future<AiOutfitResult> generateStructuredWardrobeOutfit(
    List<ClothingItem> clothes, {
    required String occasion,
  }) async {
    try {
      if (clothes.isEmpty) {
        throw Exception(
          'Kombin oluşturmak için gardıropta kıyafet bulunmuyor.',
        );
      }

      final wardrobeText = clothes
          .asMap()
          .entries
          .map((entry) {
            final int number = entry.key + 1;
            final ClothingItem item = entry.value;

            final String brand = item.brand?.trim().isNotEmpty == true
                ? item.brand!.trim()
                : 'Belirtilmedi';

            return '''
$number. Belge Kimliği: ${item.id}
   Kategori: ${item.category}
   Renk: ${item.color}
   Kumaş: ${item.fabric}
   Mevsim: ${item.season}
   Marka: $brand
   Favori: ${item.favorite ? "Evet" : "Hayır"}
''';
          })
          .join('\n');

      final allowedIds = clothes
          .map((item) => item.id)
          .where((id) => id.trim().isNotEmpty)
          .toList();

      final prompt =
          '''
Sen WardrobeAI isimli akıllı gardırop uygulamasında çalışan
profesyonel bir stil danışmanısın.

Kullanıcının gardırobundaki kıyafetler:

$wardrobeText

Kombinin kullanım amacı: $occasion

Yalnızca bu listede bulunan kıyafetlerden uyumlu bir günlük
kombin oluştur.

Kurallar:
- Yalnızca Türkçe cevap ver.
- Gardıropta bulunmayan hiçbir ürün önerme.
- Mümkünse bir üst giyim, bir alt giyim, bir ayakkabı ve
  uygun olduğunda bir dış giyim seç.
- suggestion alanında en fazla 5 kısa madde yaz.
- Her öneri maddesini "•" işaretiyle başlat.
- selectedClothingIds alanına yalnızca seçtiğin ürünlerin
  "Belge Kimliği" değerlerini ekle.
- Kimlikleri değiştirme, kısaltma veya yeniden üretme.
- Aynı kimliği birden fazla kez ekleme.
- Seçilen parçalar "$occasion" kullanım amacına uygun olmalı.

Kullanılabilecek geçerli belge kimlikleri:
${allowedIds.join(', ')}
''';

      final result = await _sendStructuredOutfitPrompt(prompt);

      final validIds = allowedIds.toSet();

      final filteredIds = result.selectedClothingIds
          .where(validIds.contains)
          .toSet()
          .toList();

      if (filteredIds.isEmpty) {
        throw Exception(
          'AI tarafından seçilen kıyafet kimlikleri '
          'gardıroptaki kayıtlarla eşleşmedi.',
        );
      }

      return AiOutfitResult(
        suggestion: result.suggestion,
        selectedClothingIds: filteredIds,
      );
    } catch (e) {
      throw Exception('Yapılandırılmış AI kombini oluşturulamadı: $e');
    }
  }
}
