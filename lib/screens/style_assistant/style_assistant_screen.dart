import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/clothing_item.dart';
import '../../models/style_chat_message.dart';
import '../../models/style_assistant_result.dart';
import '../../models/saved_outfit.dart';

import '../wardrobe/clothing_detail_screen.dart';

import '../../services/gemini_service.dart';
import '../../services/location_service.dart';
import '../../services/weather_service.dart';
import '../../services/firestore_service.dart';

class StyleAssistantScreen extends StatefulWidget {
  final List<ClothingItem> clothes;

  const StyleAssistantScreen({super.key, required this.clothes});

  @override
  State<StyleAssistantScreen> createState() => _StyleAssistantScreenState();
}

class _StyleAssistantScreenState extends State<StyleAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final FirestoreService _firestoreService = FirestoreService();
  final GeminiService _geminiService = GeminiService();
  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();
  String? _weatherSummary;

  final List<StyleChatMessage> _messages = [];

  final Set<String> _savingOutfitMessageIds = {};

  final Set<String> _savedOutfitMessageIds = {};

  bool _isLoading = false;
  int _messageCounter = 0;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _createMessageId() {
    _messageCounter++;

    return '${DateTime.now().millisecondsSinceEpoch}_$_messageCounter';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  Future<String?> _getWeatherSummary() async {
    if (_weatherSummary != null && _weatherSummary!.trim().isNotEmpty) {
      return _weatherSummary;
    }

    try {
      final position = await _locationService.getCurrentPosition().timeout(
        const Duration(seconds: 20),
      );

      final weather = await _weatherService
          .getCurrentWeather(
            latitude: position.latitude,
            longitude: position.longitude,
          )
          .timeout(const Duration(seconds: 20));

      final summary =
          '''
Sıcaklık: ${weather.temperature.toStringAsFixed(0)}°C
Hissedilen: ${weather.apparentTemperature.toStringAsFixed(0)}°C
Durum: ${weather.description}
Yağış: ${weather.precipitation.toStringAsFixed(1)} mm
Rüzgâr: ${weather.windSpeed.toStringAsFixed(0)} km/sa
'''
              .trim();

      _weatherSummary = summary;

      return summary;
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();

    if (messageText.isEmpty || _isLoading) {
      return;
    }

    final userMessage = StyleChatMessage.user(
      id: _createMessageId(),
      text: messageText,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Gemini bağlantısını sonraki adımda ekleyeceğiz.
    try {
      final weatherSummary = await _getWeatherSummary();

      final StyleAssistantResult result = await _geminiService
          .generateStyleAssistantResponse(
            clothes: widget.clothes,
            messages: List<StyleChatMessage>.from(_messages),
            weatherSummary: weatherSummary,
          );

      if (!mounted) return;

      final assistantMessage = StyleChatMessage.assistant(
        id: _createMessageId(),
        text: result.response,
        result: result,
      );

      setState(() {
        _messages.add(assistantMessage);
      });
    } catch (e) {
      if (!mounted) return;

      final assistantMessage = StyleChatMessage.assistant(
        id: _createMessageId(),
        text: _getFriendlyChatError(e),
      );

      setState(() {
        _messages.add(assistantMessage);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _scrollToBottom();
      }
    }
  }

  Future<void> _saveSuggestedOutfit({
    required StyleChatMessage message,
    required StyleAssistantResult result,
  }) async {
    if (_savingOutfitMessageIds.contains(message.id) ||
        _savedOutfitMessageIds.contains(message.id)) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kombini kaydetmek için oturum açmalısın."),
        ),
      );
      return;
    }

    if (result.selectedClothingIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kaydedilecek kıyafet seçimi bulunamadı."),
        ),
      );
      return;
    }

    setState(() {
      _savingOutfitMessageIds.add(message.id);
    });

    try {
      final outfit = SavedOutfit(
        id: "",
        uid: user.uid,
        clothingIds: result.selectedClothingIds,
        description: result.response,
        outfitScore: result.outfitScore,
        createdAt: DateTime.now(),
      );

      await _firestoreService.saveOutfit(outfit);

      if (!mounted) return;

      setState(() {
        _savedOutfitMessageIds.add(message.id);
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Kombin başarıyla kaydedildi.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Kombin kaydedilemedi. Lütfen tekrar dene.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _savingOutfitMessageIds.remove(message.id);
        });
      }
    }
  }

  String _getFriendlyChatError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('503') ||
        message.contains('high demand') ||
        message.contains('unavailable') ||
        message.contains('overloaded')) {
      return 'AI stil asistanı şu anda yoğun. '
          'Lütfen birkaç saniye sonra tekrar dene.';
    }

    if (message.contains('429') ||
        message.contains('quota') ||
        message.contains('rate limit')) {
      return 'AI kullanım sınırına ulaşıldı. '
          'Bir süre sonra tekrar deneyebilirsin.';
    }

    if (message.contains('timeout') || message.contains('timed out')) {
      return 'Stil asistanının cevabı gecikti. '
          'Lütfen tekrar dene.';
    }

    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('connection')) {
      return 'İnternet bağlantısı kurulamadı. '
          'Bağlantını kontrol edip tekrar dene.';
    }

    return 'Stil asistanı şu anda cevap oluşturamadı. '
        'Lütfen tekrar dene.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Stil Asistanı'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Bugün ne giymek istiyorsun?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Gideceğin yeri, etkinliği veya kullanmak '
                          'istediğin bir kıyafeti yaz.',
                          style: TextStyle(color: Colors.white70, height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${widget.clothes.length} kıyafet stil asistanı '
                          'tarafından incelenecek.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildExampleChip('İş görüşmesine gideceğim'),
                      _buildExampleChip('Arkadaşlarımla kahve içeceğim'),
                      _buildExampleChip('Akşam düğüne gideceğim'),
                      _buildExampleChip('Siyah pantolonla ne giyebilirim?'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  if (_messages.isEmpty)
                    _buildEmptyChat(context)
                  else
                    ..._messages.map((message) {
                      return _buildMessageBubble(context, message);
                    }),

                  if (_isLoading) _buildTypingIndicator(context),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Örneğin: Yarın okul için ne giyebilirim?',
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: IconButton.filled(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, StyleChatMessage message) {
    final bool isUser = message.isUser;
    final selectedClothes = message.assistantResult == null
        ? <ClothingItem>[]
        : widget.clothes.where((item) {
            return message.assistantResult!.selectedClothingIds.contains(
              item.id,
            );
          }).toList();

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),

            if (!isUser && selectedClothes.isNotEmpty) ...[
              const SizedBox(height: 14),

              _buildSelectedOutfitCard(
                context,
                selectedClothes,
                message,
                message.assistantResult!,
              ),
            ],
            if (!isUser &&
                message.assistantResult != null &&
                message.assistantResult!.shouldShowScore) ...[
              const SizedBox(height: 14),

              _buildOutfitScoreCard(context, message.assistantResult!),
            ],
            const SizedBox(height: 5),
            Text(
              _formatMessageTime(message.createdAt),
              style: TextStyle(
                color: isUser
                    ? Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.7)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _findSelectionReason(StyleAssistantResult result, String clothingId) {
    for (final item in result.selectedClothingReasons) {
      if (item.clothingId == clothingId) {
        final reason = item.reason.trim();

        if (reason.isNotEmpty) {
          return reason;
        }
      }
    }

    return null;
  }

  Widget _buildSelectedOutfitCard(
    BuildContext context,
    List<ClothingItem> selectedClothes,
    StyleChatMessage message,
    StyleAssistantResult result,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.checkroom_rounded, color: Color(0xFF6A11CB)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "AI'nin Seçtiği Kombin",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 235,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selectedClothes.length,
              separatorBuilder: (_, __) {
                return const SizedBox(width: 10);
              },
              itemBuilder: (context, index) {
                final item = selectedClothes[index];

                final selectionReason = _findSelectionReason(result, item.id);

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClothingDetailScreen(clothing: item),
                      ),
                    );
                  },
                  child: Container(
                    width: 170,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: item.imageUrl.trim().isNotEmpty
                                ? Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }

                                          return const Center(
                                            child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.3,
                                              ),
                                            ),
                                          );
                                        },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.broken_image_outlined,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      );
                                    },
                                  )
                                : Icon(
                                    Icons.checkroom_rounded,
                                    size: 38,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          item.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          item.color,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),

                        if (selectionReason != null) ...[
                          const SizedBox(height: 7),

                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    selectionReason,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 10,
                                      height: 1.3,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed:
                  _savedOutfitMessageIds.contains(message.id) ||
                      _savingOutfitMessageIds.contains(message.id)
                  ? null
                  : () {
                      _saveSuggestedOutfit(message: message, result: result);
                    },
              icon: _savingOutfitMessageIds.contains(message.id)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _savedOutfitMessageIds.contains(message.id)
                          ? Icons.check_circle_rounded
                          : Icons.favorite_border_rounded,
                    ),
              label: Text(
                _savingOutfitMessageIds.contains(message.id)
                    ? "Kaydediliyor..."
                    : _savedOutfitMessageIds.contains(message.id)
                    ? "Kombin Kaydedildi"
                    : "Kombini Kaydet",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitScoreCard(
    BuildContext context,
    StyleAssistantResult result,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    "${result.outfitScore}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Kombin Puanı",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Renk, hava ve etkinlik uyumu",
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildScoreRow(
            context: context,
            title: "Renk uyumu",
            score: result.colorScore,
          ),

          const SizedBox(height: 9),

          _buildScoreRow(
            context: context,
            title: "Hava uygunluğu",
            score: result.weatherScore,
          ),

          const SizedBox(height: 9),

          _buildScoreRow(
            context: context,
            title: "Etkinlik uygunluğu",
            score: result.occasionScore,
          ),

          if (result.strengths.isNotEmpty) ...[
            const SizedBox(height: 14),

            ...result.strengths.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 12, height: 1.35),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          if (result.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),

            ...result.warnings.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 12, height: 1.35),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreRow({
    required BuildContext context,
    required String title,
    required int score,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              "%$score",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 7,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            SizedBox(width: 10),
            Text(
              'Stil asistanı düşünüyor...',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChat(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.chat_bubble_outline_rounded),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bir etkinlik, kıyafet veya stil sorusu yazarak '
              'sohbeti başlatabilirsin.',
              style: TextStyle(height: 1.4, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final String hour = dateTime.hour.toString().padLeft(2, '0');

    final String minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Widget _buildExampleChip(String text) {
    return ActionChip(
      avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
      label: Text(text),
      onPressed: () {
        _messageController.text = text;
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
      },
    );
  }
}
