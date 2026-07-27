import 'dart:math';

import '../models/clothing_item.dart';

class OutfitSuggestionService {
  final Random _random = Random();

  String generateSuggestion(ClothingItem clothing) {
    final category = clothing.category.toLowerCase();
    final color = clothing.color.toLowerCase();
    final season = clothing.season.toLowerCase();

    final List<String> suggestions = [];

    suggestions.addAll(_getCategorySuggestions(category));
    suggestions.add(_getColorSuggestion(color));
    suggestions.add(_getSeasonSuggestion(season));

    return suggestions
        .where((item) => item.trim().isNotEmpty)
        .map((item) => '• $item')
        .join('\n');
  }

  List<String> _getCategorySuggestions(String category) {
    if (category.contains('ceket')) {
      return [
        _pickRandom([
          'Beyaz sade bir tişört',
          'Siyah basic tişört',
          'İnce boğazlı kazak',
        ]),
        _pickRandom([
          'Koyu renk jean pantolon',
          'Siyah kumaş pantolon',
          'Bej chino pantolon',
        ]),
        _pickRandom([
          'Beyaz spor ayakkabı',
          'Siyah deri ayakkabı',
          'Minimal sneaker',
        ]),
      ];
    }

    if (category.contains('tişört')) {
      return [
        _pickRandom([
          'Açık mavi jean pantolon',
          'Bej chino pantolon',
          'Siyah jogger pantolon',
        ]),
        _pickRandom([
          'Beyaz spor ayakkabı',
          'Minimal sneaker',
          'Günlük loafer',
        ]),
        _pickRandom([
          'Hafif bir overshirt',
          'İnce denim ceket',
          'Sade bir hırka',
        ]),
      ];
    }

    if (category.contains('gömlek')) {
      return [
        _pickRandom([
          'Koyu renk kumaş pantolon',
          'Lacivert chino pantolon',
          'Düz kesim jean',
        ]),
        _pickRandom([
          'Kahverengi deri ayakkabı',
          'Siyah klasik ayakkabı',
          'Minimal loafer',
        ]),
        _pickRandom(['Metal kordonlu saat', 'Deri kayışlı saat', 'Sade kemer']),
      ];
    }

    if (category.contains('pantolon')) {
      return [
        _pickRandom([
          'Beyaz düz renk tişört',
          'Açık renk gömlek',
          'Sade sweatshirt',
        ]),
        _pickRandom([
          'Renkle uyumlu sneaker',
          'Günlük deri ayakkabı',
          'Minimal spor ayakkabı',
        ]),
        _pickRandom(['Sade saat', 'Minimal bileklik', 'Düz renk kemer']),
      ];
    }

    if (category.contains('ayakkabı')) {
      return [
        _pickRandom([
          'Ayakkabıyla uyumlu chino pantolon',
          'Düz kesim jean pantolon',
          'Kumaş pantolon',
        ]),
        _pickRandom([
          'Nötr renkli tişört',
          'Sade gömlek',
          'Minimal sweatshirt',
        ]),
        _pickRandom(['Aynı tonlarda kemer', 'Sade saat', 'Minimal aksesuar']),
      ];
    }

    return [
      'Nötr renkli tamamlayıcı parçalar',
      'Sade ayakkabı',
      'Minimal aksesuar',
    ];
  }

  String _getColorSuggestion(String color) {
    if (color.contains('kırmızı')) {
      return _pickRandom([
        'Siyah, beyaz veya gri parçalarla dengele',
        'Kırmızıyı nötr tonlarla ön plana çıkar',
        'Aksesuarları sade tut',
      ]);
    }

    if (color.contains('mavi')) {
      return _pickRandom([
        'Beyaz, bej veya gri tonlarla eşleştir',
        'Lacivert ve açık tonları birlikte kullan',
        'Kahverengi aksesuarlarla tamamla',
      ]);
    }

    if (color.contains('siyah')) {
      return _pickRandom([
        'Beyaz veya gri bir parça ekleyebilirsin',
        'Canlı renkli küçük bir aksesuar kullan',
        'Monokrom bir kombin deneyebilirsin',
      ]);
    }

    if (color.contains('beyaz')) {
      return _pickRandom([
        'Hemen hemen her renkle rahatça kombinlenebilir',
        'Pastel tonlarla yumuşak bir görünüm oluştur',
        'Siyah parçalarla güçlü kontrast yarat',
      ]);
    }

    return 'Nötr tonlarla dengeli bir kombin oluştur';
  }

  String _getSeasonSuggestion(String season) {
    if (season.contains('kış')) {
      return _pickRandom([
        'Kalın mont, bot ve atkıyla tamamla',
        'Katmanlı giyim tercih et',
        'Koyu tonlarla kış görünümünü güçlendir',
      ]);
    }

    if (season.contains('sonbahar')) {
      return _pickRandom([
        'Hafif ceket ve katmanlı giyim tercih et',
        'Toprak tonlarıyla tamamla',
        'İnce kazak veya overshirt ekle',
      ]);
    }

    if (season.contains('yaz')) {
      return _pickRandom([
        'İnce kumaşlı ve açık renkli parçalar kullan',
        'Nefes alan kumaşları tercih et',
        'Aksesuarları hafif ve sade tut',
      ]);
    }

    if (season.contains('ilkbahar')) {
      return _pickRandom([
        'Hafif mont veya ince hırka ekleyebilirsin',
        'Pastel tonlarla kombin oluştur',
        'Değişken hava için katmanlı giyin',
      ]);
    }

    return 'Mevsime uygun tamamlayıcı parçalar kullan';
  }

  String _pickRandom(List<String> options) {
    return options[_random.nextInt(options.length)];
  }
}
