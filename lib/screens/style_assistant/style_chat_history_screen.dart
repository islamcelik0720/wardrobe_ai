import 'package:flutter/material.dart';

import '../../models/style_chat_session.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class StyleChatHistoryScreen extends StatelessWidget {
  const StyleChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text("Sohbet Geçmişi"), centerTitle: true),
      body: user == null
          ? const Center(child: Text("Kullanıcı oturumu bulunamadı."))
          : StreamBuilder<List<StyleChatSession>>(
              stream: firestoreService.getStyleChatSessions(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "Sohbet geçmişi yüklenemedi.\n"
                        "${snapshot.error}",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sessions = snapshot.data ?? [];

                if (sessions.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) {
                    return const SizedBox(height: 12);
                  },
                  itemBuilder: (context, index) {
                    final session = sessions[index];

                    return _buildSessionCard(
                      context: context,
                      firestoreService: firestoreService,
                      session: session,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildSessionCard({
    required BuildContext context,
    required FirestoreService firestoreService,
    required StyleChatSession session,
  }) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        // Bir sonraki adımda buradan
        // eski sohbeti açacağız.
        onTap: () {
          Navigator.pop(context, session);
        },

        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      "${session.messages.length} mesaj",
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _formatDate(session.updatedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: "Sohbeti sil",
                onPressed: () {
                  _confirmDelete(
                    context: context,
                    firestoreService: firestoreService,
                    session: session,
                  );
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete({
    required BuildContext context,
    required FirestoreService firestoreService,
    required StyleChatSession session,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text("Sohbeti Sil"),
          content: Text(
            "\"${session.title}\" sohbetini silmek "
            "istediğine emin misin?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Vazgeç"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text("Sil"),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await firestoreService.deleteStyleChatSession(session.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Sohbet silindi."),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Sohbet silinemedi."),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 18),
            const Text(
              "Henüz sohbet geçmişi yok",
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Stil Asistanı ile yaptığın konuşmalar "
              "burada görünecek.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, "0");

    final month = date.month.toString().padLeft(2, "0");

    final year = date.year;

    final hour = date.hour.toString().padLeft(2, "0");

    final minute = date.minute.toString().padLeft(2, "0");

    return "$day.$month.$year • $hour:$minute";
  }
}
