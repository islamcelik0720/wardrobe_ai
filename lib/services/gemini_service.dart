import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/ai_outfit_result.dart';
import '../models/clothing_item.dart';
import '../models/weather_info.dart';
import '../models/clothing_analysis_result.dart';
import '../models/style_chat_message.dart';
import '../models/style_assistant_result.dart';

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

  String _getImageMimeType(String filePath) {
    final extension = filePath.toLowerCase();

    if (extension.endsWith('.png')) {
      return 'image/png';
    }

    if (extension.endsWith('.webp')) {
      return 'image/webp';
    }

    if (extension.endsWith('.heic') || extension.endsWith('.heif')) {
      return 'image/heic';
    }

    return 'image/jpeg';
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
    WeatherInfo? weather,
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

      final String weatherText;

      if (weather == null) {
        weatherText = "Hava durumu bilgisi alınamadı.";
      } else {
        weatherText =
            '''
Anlık hava durumu:
- Sıcaklık: ${weather.temperature.toStringAsFixed(0)}°C
- Hissedilen sıcaklık: ${weather.apparentTemperature.toStringAsFixed(0)}°C
- Durum: ${weather.description}
- Yağış: ${weather.precipitation.toStringAsFixed(1)} mm
- Rüzgâr: ${weather.windSpeed.toStringAsFixed(0)} km/sa
''';
      }

      final prompt =
          '''
Sen WardrobeAI isimli akıllı gardırop uygulamasında çalışan
profesyonel bir stil danışmanısın.

Kullanıcının gardırobundaki kıyafetler:

$wardrobeText

Kombinin kullanım amacı: $occasion

$weatherText

Yalnızca bu listede bulunan kıyafetlerden uyumlu bir günlük
kombin oluştur.

Kurallar:
- Kombini sıcaklık, hissedilen sıcaklık, yağış ve rüzgâra göre oluştur.
- Hava sıcaksa ince ve nefes alan kumaşları önceliklendir.
- Hava soğuksa katmanlı ve sıcak tutan parçaları önceliklendir.
- Yağış varsa uygun dış giyim ve ayakkabı tercih et.
- suggestion içinde hava durumunu kısa şekilde belirt.
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

  Future<http.Response> _sendImageAnalysisRequestWithRetry({
    required Map<String, dynamic> requestBody,
  }) async {
    const int maxAttempts = 3;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await http
            .post(
              _endpoint,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': _apiKey,
              },
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 45));

        final bool shouldRetry =
            response.statusCode == 408 ||
            response.statusCode == 429 ||
            response.statusCode >= 500;

        if (!shouldRetry || attempt == maxAttempts) {
          return response;
        }

        final delaySeconds = 1 << (attempt - 1);

        await Future.delayed(Duration(seconds: delaySeconds));
      } on TimeoutException {
        if (attempt == maxAttempts) {
          rethrow;
        }

        final delaySeconds = 1 << (attempt - 1);

        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    throw Exception('AI servisine bağlanılamadı.');
  }

  Future<ClothingAnalysisResult> analyzeClothingImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('Analiz edilecek fotoğraf bulunamadı.');
      }

      final imageBytes = await imageFile.readAsBytes();

      if (imageBytes.isEmpty) {
        throw Exception('Seçilen fotoğraf boş.');
      }

      final String base64Image = base64Encode(imageBytes);
      final String mimeType = _getImageMimeType(imageFile.path);

      const prompt = '''
Bu fotoğraftaki ana kıyafeti analiz et.

Yalnızca fotoğrafta açıkça görülen ana kıyafeti değerlendir.
Arka planı, insanı, askıyı veya diğer nesneleri kıyafet olarak
yorumlama.

Aşağıdaki alanları Türkçe olarak tahmin et:

- category
- color
- fabric
- season
- brand
- description

Kurallar:
- category yalnızca şu değerlerden biri olmalı:
  Pantolon, Tişört, Gömlek, Kazak, Sweatshirt, Ceket,
  Mont, Şort, Etek, Elbise, Ayakkabı
- color yalnızca şu değerlerden biri olmalı:
  Siyah, Beyaz, Krem, Bej, Gri, Mavi, Lacivert, Yeşil,
  Kırmızı, Pembe, Mor, Sarı, Kahverengi, Turuncu
- fabric yalnızca şu değerlerden biri olmalı:
  Pamuk, Denim, Keten, Yün, Polyester, Deri,
  Kadife, Viskon, İpek, Triko
- season yalnızca şu değerlerden biri olmalı:
  İlkbahar, Yaz, Sonbahar, Kış
- Marka kesin biçimde görünmüyorsa brand alanını boş string yap.
- Kumaş yalnızca görselden tahmindir; emin değilsen düşük güven ver.
- Mevsimi kıyafetin kalınlığına ve kullanım biçimine göre tahmin et.
- description alanında en fazla iki kısa Türkçe cümle kullan.
- Güven oranlarını 0 ile 100 arasında tam sayı olarak ver.
- Kullanıcı daha sonra bütün alanları değiştirebilir.
- selectedClothingReasons alanında, seçtiğin her kıyafet için kısa bir seçim nedeni yaz.
- Her açıklama yalnızca gardıroptaki gerçek clothingId ile eşleşsin.
- Uydurma clothingId üretme.
- Seçim nedenleri kısa, doğal ve Türkçe olsun.
- Nedenlerde hava, renk uyumu, etkinlik, kumaş, favori durumu veya kullanım sıklığı gibi gerçek bilgileri kullan.
- selectedClothingIds içinde olmayan bir kıyafet için neden üretme.
- shouldShowScore false olduğunda selectedClothingReasons boş liste olsun.
''';

      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
              {
                'inline_data': {'mime_type': mimeType, 'data': base64Image},
              },
            ],
          },
        ],
        'generationConfig': {
          'maxOutputTokens': 700,
          'temperature': 0.2,
          'responseMimeType': 'application/json',
          'responseSchema': {
            'type': 'object',
            'properties': {
              'category': {
                'type': 'string',
                'enum': [
                  'Pantolon',
                  'Tişört',
                  'Gömlek',
                  'Kazak',
                  'Sweatshirt',
                  'Ceket',
                  'Mont',
                  'Şort',
                  'Etek',
                  'Elbise',
                  'Ayakkabı',
                ],
              },
              'color': {
                'type': 'string',
                'enum': [
                  'Siyah',
                  'Beyaz',
                  'Krem',
                  'Bej',
                  'Gri',
                  'Mavi',
                  'Lacivert',
                  'Yeşil',
                  'Kırmızı',
                  'Pembe',
                  'Mor',
                  'Sarı',
                  'Kahverengi',
                  'Turuncu',
                ],
              },
              'fabric': {
                'type': 'string',
                'enum': [
                  'Pamuk',
                  'Denim',
                  'Keten',
                  'Yün',
                  'Polyester',
                  'Deri',
                  'Kadife',
                  'Viskon',
                  'İpek',
                  'Triko',
                ],
              },
              'season': {
                'type': 'string',
                'enum': ['İlkbahar', 'Yaz', 'Sonbahar', 'Kış'],
              },
              'brand': {'type': 'string'},
              'description': {'type': 'string'},
              'categoryConfidence': {
                'type': 'integer',
                'minimum': 0,
                'maximum': 100,
              },
              'colorConfidence': {
                'type': 'integer',
                'minimum': 0,
                'maximum': 100,
              },
              'fabricConfidence': {
                'type': 'integer',
                'minimum': 0,
                'maximum': 100,
              },
              'seasonConfidence': {
                'type': 'integer',
                'minimum': 0,
                'maximum': 100,
              },
              'brandConfidence': {
                'type': 'integer',
                'minimum': 0,
                'maximum': 100,
              },
            },
            'required': [
              'category',
              'color',
              'fabric',
              'season',
              'brand',
              'description',
              'categoryConfidence',
              'colorConfidence',
              'fabricConfidence',
              'seasonConfidence',
              'brandConfidence',
            ],
          },
        },
      };

      final response = await _sendImageAnalysisRequestWithRetry(
        requestBody: requestBody,
      );
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
        String errorMessage = 'Fotoğraf analizi başarısız oldu.';

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
        throw Exception('Gemini fotoğraf için analiz üretmedi.');
      }

      final firstCandidate = candidates.first;

      if (firstCandidate is! Map<String, dynamic>) {
        throw Exception('Gemini aday yanıtı geçersiz.');
      }

      final content = firstCandidate['content'];

      if (content is! Map<String, dynamic>) {
        throw Exception('Gemini analiz içeriği bulunamadı.');
      }

      final parts = content['parts'];

      if (parts is! List || parts.isEmpty) {
        throw Exception('Gemini analiz metni bulunamadı.');
      }

      final firstPart = parts.first;

      if (firstPart is! Map<String, dynamic>) {
        throw Exception('Gemini analiz parçası geçersiz.');
      }

      final String jsonText = firstPart['text']?.toString().trim() ?? '';

      if (jsonText.isEmpty) {
        throw Exception('Gemini boş analiz sonucu döndürdü.');
      }

      final dynamic decodedAnalysis;

      try {
        decodedAnalysis = jsonDecode(jsonText);
      } catch (_) {
        throw Exception(
          'Gemini analiz sonucunu geçerli JSON olarak döndürmedi.',
        );
      }

      if (decodedAnalysis is! Map<String, dynamic>) {
        throw Exception('Fotoğraf analiz sonucu beklenen yapıda değil.');
      }

      final result = ClothingAnalysisResult.fromMap(decodedAnalysis);

      if (result.category.isEmpty ||
          result.color.isEmpty ||
          result.fabric.isEmpty ||
          result.season.isEmpty) {
        throw Exception('AI bazı zorunlu kıyafet alanlarını belirleyemedi.');
      }

      return result;
    } catch (e) {
      throw Exception('Kıyafet fotoğrafı analiz edilemedi: $e');
    }
  }

  Future<StyleAssistantResult> generateStyleAssistantResponse({
    required List<ClothingItem> clothes,
    required List<StyleChatMessage> messages,
    String? weatherSummary,
  }) async {
    if (clothes.isEmpty) {
      throw Exception(
        'Stil önerisi oluşturmak için gardıropta kıyafet bulunmuyor.',
      );
    }

    if (messages.isEmpty) {
      throw Exception('Sohbet mesajı bulunamadı.');
    }

    final wardrobeText = clothes
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key + 1;
          final item = entry.value;

          return '''
$index.
- ID: ${item.id}
- Kategori: ${item.category}
- Renk: ${item.color}
- Kumaş: ${item.fabric}
- Mevsim: ${item.season}
- Marka: ${item.brand?.trim().isNotEmpty == true ? item.brand : 'Belirtilmedi'}
- Favori: ${item.favorite ? 'Evet' : 'Hayır'}
- Kullanım sayısı: ${item.timesUsed}
- Not: ${item.notes?.trim().isNotEmpty == true ? item.notes : 'Yok'}
''';
        })
        .join('\n');

    final systemPrompt =
        '''
Sen WardrobeAI uygulamasında çalışan Türkçe bir kişisel stil danışmanısın.

Kullanıcının gerçek gardırobu:

$wardrobeText

Hava durumu:
${weatherSummary?.trim().isNotEmpty == true ? weatherSummary : 'Hava durumu bilgisi bulunmuyor.'}

Kurallar:
- Daima Türkçe cevap ver.
- Öncelikle yalnızca kullanıcının gardırobunda bulunan kıyafetleri öner.
- Gardıropta olmayan bir ürün gerekiyorsa bunun bir alışveriş önerisi olduğunu açıkça belirt.
- Önceki sohbet mesajlarını dikkate al.
- Kullanıcının son sorusuna doğrudan cevap ver.
- Önerdiğin kıyafetleri kategori, renk ve kumaş bilgileriyle açıkça belirt.
- Hava durumunu, kullanım amacını, mevsimi, favorileri ve kullanım sayılarını değerlendir.
- Aynı kıyafet çok sık kullanılmışsa mümkün olduğunda alternatif öner.
- Fotoğraftan tahmin edilen kumaş veya marka bilgilerini kesin gerçekmiş gibi sunma.
- Cevabı doğal, yardımcı ve kısa paragraflarla yaz.
- Çok uzun cevap verme.
- Önerdiğin kombini 0 ile 100 arasında puanla.
- outfitScore genel kombin uyumunu temsil etsin.
- colorScore renklerin birbirine uyumunu temsil etsin.
- weatherScore kombinin hava şartlarına uygunluğunu temsil etsin.
- occasionScore kombinin kullanıcının etkinliğine uygunluğunu temsil etsin.
- strengths alanında en fazla 3 kısa olumlu değerlendirme ver.
- warnings alanında en fazla 3 kısa uyarı ver.
- Uyarı bulunmuyorsa warnings alanını boş liste olarak döndür.
- Gardıropta uygun kombin oluşturulamıyorsa bunu response alanında açıkça belirt ve düşük puan ver.
- Kullanıcı yalnızca teşekkür, selamlaşma, vedalaşma veya kısa sohbet yapıyorsa shouldShowScore false olsun.
- Kullanıcı bir kombin, kıyafet, renk, hava veya etkinlik önerisi istiyorsa shouldShowScore true olsun.
- shouldShowScore false olduğunda puanları 0, strengths ve warnings alanlarını boş liste olarak döndür.
- Gerçek bir kombin öneriyorsan selectedClothingIds alanına yalnızca gardırop listesindeki gerçek ID değerlerini yaz.
- Gardıropta bulunmayan veya uydurma bir ID üretme.
- Aynı ID'yi birden fazla kez ekleme.
- Kombin için mümkünse üst giyim, alt giyim ve ayakkabı seç.
- Kullanıcı belirli bir parça soruyorsa yalnızca gerekli parçaları seçebilirsin.
- shouldShowScore false olduğunda selectedClothingIds boş liste olsun.
- Gardıropta uygun parça bulunmuyorsa selectedClothingIds içine uygun olmayan bir ürün ekleme; eksik parçayı response alanında alışveriş önerisi olarak belirt.
''';

    final List<Map<String, dynamic>> contents = [];

    contents.add({
      'role': 'user',
      'parts': [
        {'text': systemPrompt},
      ],
    });

    contents.add({
      'role': 'model',
      'parts': [
        {
          'text':
              'Anladım. Kullanıcının gardırobunu, hava durumunu ve sohbet geçmişini dikkate alarak Türkçe stil önerileri vereceğim.',
        },
      ],
    });

    for (final message in messages) {
      contents.add({
        'role': message.isUser ? 'user' : 'model',
        'parts': [
          {'text': message.text},
        ],
      });
    }

    final response = await http
        .post(
          _endpoint,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
          body: jsonEncode({
            'contents': contents,
            'generationConfig': {
              'temperature': 0.5,
              'maxOutputTokens': 1100,
              'responseMimeType': 'application/json',
              'responseSchema': {
                'type': 'object',
                'properties': {
                  'response': {
                    'type': 'string',
                    'description':
                        'Kullanıcıya verilecek kısa ve doğal Türkçe stil cevabı.',
                  },

                  'shouldShowScore': {
                    'type': 'boolean',
                    'description':
                        'Gerçek bir kombin önerisi veya kombin değerlendirmesi varsa true; '
                        'selamlaşma, teşekkür, vedalaşma veya normal sohbet varsa false.',
                  },

                  'outfitScore': {
                    'type': 'integer',
                    'minimum': 0,
                    'maximum': 100,
                    'description': 'Kombinin genel uyum puanı.',
                  },

                  'colorScore': {
                    'type': 'integer',
                    'minimum': 0,
                    'maximum': 100,
                    'description': 'Kombindeki renk uyumu puanı.',
                  },

                  'weatherScore': {
                    'type': 'integer',
                    'minimum': 0,
                    'maximum': 100,
                    'description':
                        'Kombinin güncel hava şartlarına uygunluk puanı.',
                  },

                  'occasionScore': {
                    'type': 'integer',
                    'minimum': 0,
                    'maximum': 100,
                    'description':
                        'Kombinin belirtilen etkinliğe uygunluk puanı.',
                  },

                  'strengths': {
                    'type': 'array',
                    'description': 'Kombinin güçlü yönleri.',
                    'items': {'type': 'string'},
                    'maxItems': 3,
                  },

                  'warnings': {
                    'type': 'array',
                    'description':
                        'Kombinle ilgili dikkat edilmesi gerekenler.',
                    'items': {'type': 'string'},
                    'maxItems': 3,
                  },
                  'selectedClothingIds': {
                    'type': 'array',
                    'description':
                        'Önerilen kombinde kullanılacak ve gardırop listesinde gerçekten bulunan kıyafet ID değerleri.',
                    'items': {'type': 'string'},
                    'maxItems': 6,
                  },
                  'selectedClothingReasons': {
                    'type': 'array',
                    'description':
                        'Seçilen her gerçek kıyafet için kısa Türkçe seçim nedeni.',
                    'items': {
                      'type': 'object',
                      'properties': {
                        'clothingId': {
                          'type': 'string',
                          'description':
                              'selectedClothingIds listesindeki gerçek kıyafet ID değeri.',
                        },
                        'reason': {
                          'type': 'string',
                          'description':
                              'Kıyafetin neden seçildiğini açıklayan kısa Türkçe cümle.',
                        },
                      },
                      'required': ['clothingId', 'reason'],
                    },
                    'maxItems': 6,
                  },
                },

                'required': [
                  'response',
                  'shouldShowScore',
                  'outfitScore',
                  'colorScore',
                  'weatherScore',
                  'occasionScore',
                  'strengths',
                  'warnings',
                  'selectedClothingIds',
                  'selectedClothingReasons',
                ],
              },
            },
          }),
        )
        .timeout(const Duration(seconds: 45));

    final dynamic decodedBody;

    try {
      decodedBody = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Stil asistanı geçersiz bir sunucu yanıtı döndürdü.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String errorMessage = 'Stil asistanı yanıt oluşturamadı.';

      if (decodedBody is Map<String, dynamic>) {
        final error = decodedBody['error'];

        if (error is Map<String, dynamic>) {
          errorMessage = error['message']?.toString() ?? errorMessage;
        }
      }

      throw Exception('$errorMessage HTTP ${response.statusCode}');
    }

    if (decodedBody is! Map<String, dynamic>) {
      throw Exception('Stil asistanı yanıt biçimi geçersiz.');
    }

    final candidates = decodedBody['candidates'];

    if (candidates is! List || candidates.isEmpty) {
      throw Exception('Stil asistanı cevap üretmedi.');
    }

    final firstCandidate = candidates.first;

    if (firstCandidate is! Map<String, dynamic>) {
      throw Exception('Stil asistanı aday yanıtı geçersiz.');
    }

    final content = firstCandidate['content'];

    if (content is! Map<String, dynamic>) {
      throw Exception('Stil asistanı içerik döndürmedi.');
    }

    final parts = content['parts'];

    if (parts is! List || parts.isEmpty) {
      throw Exception('Stil asistanı metin döndürmedi.');
    }

    final jsonText = parts
        .whereType<Map<String, dynamic>>()
        .map((part) => part['text']?.toString() ?? '')
        .join('\n')
        .trim();

    if (jsonText.isEmpty) {
      throw Exception('Stil asistanı boş cevap döndürdü.');
    }

    final dynamic decodedResult;

    try {
      decodedResult = jsonDecode(jsonText);
    } catch (_) {
      throw Exception('Stil asistanı sonucunu geçerli JSON olarak döndürmedi.');
    }

    if (decodedResult is! Map<String, dynamic>) {
      throw Exception('Stil asistanı sonucu beklenen yapıda değil.');
    }

    final result = StyleAssistantResult.fromMap(decodedResult);
    final validClothingIds = clothes
        .map((item) => item.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    final filteredSelectedIds = result.selectedClothingIds
        .where(validClothingIds.contains)
        .toSet()
        .toList();

    final filteredReasons = result.selectedClothingReasons.where((item) {
      return validClothingIds.contains(item.clothingId) &&
          filteredSelectedIds.contains(item.clothingId);
    }).toList();

    if (result.response.isEmpty) {
      throw Exception('Stil asistanı cevap metni oluşturmadı.');
    }

    return StyleAssistantResult(
      response: result.response,
      shouldShowScore: result.shouldShowScore,
      outfitScore: result.outfitScore,
      colorScore: result.colorScore,
      weatherScore: result.weatherScore,
      occasionScore: result.occasionScore,
      strengths: result.strengths,
      warnings: result.warnings,
      selectedClothingIds: result.shouldShowScore
          ? filteredSelectedIds
          : const [],
      selectedClothingReasons: result.shouldShowScore
          ? filteredReasons
          : const [],
    );
  }
}
