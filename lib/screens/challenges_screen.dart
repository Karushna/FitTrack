import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/database_service.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  void openAddChallengeSheet(BuildContext context) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Challenge', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Challenge title')),
            TextField(controller: targetController, decoration: const InputDecoration(labelText: 'Target km'), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await DatabaseService.addChallenge(
                  title: titleController.text.trim().isEmpty ? 'New Fitness Challenge' : titleController.text.trim(),
                  targetKm: double.tryParse(targetController.text) ?? 10,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add Challenge'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = Supabase.instance.client
        .from('challenges')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Challenges'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      floatingActionButton: FloatingActionButton(onPressed: () => openAddChallengeSheet(context), child: const Icon(Icons.add)),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final challenges = snapshot.data!;
          if (challenges.isEmpty) return const Center(child: Text('No challenges yet. Add one.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              final id = challenge['id'] as int;
              final target = (challenge['target_km'] ?? 1).toDouble();
              final progress = (challenge['progress_km'] ?? 0).toDouble();
              final percent = target <= 0 ? 0.0 : (progress / target).clamp(0.0, 1.0);

              return FutureBuilder<bool>(
                future: DatabaseService.hasJoinedChallenge(id),
                builder: (context, joinedSnapshot) {
                  final isJoined = joinedSnapshot.data ?? false;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(backgroundColor: Color(0xFFFF5A1F), child: Icon(Icons.emoji_events, color: Colors.white)),
                              const SizedBox(width: 12),
                              Expanded(child: Text(challenge['title'] ?? 'Challenge', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            ],
                          ),
                          const SizedBox(height: 14),
                          LinearProgressIndicator(value: percent, minHeight: 9, borderRadius: BorderRadius.circular(12)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${progress.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} km', style: const TextStyle(color: Colors.grey)),
                              ElevatedButton(
                                onPressed: isJoined
                                    ? null
                                    : () async {
                                        await DatabaseService.joinChallenge(challengeId: id);
                                      },
                                child: Text(isJoined ? 'Joined' : 'Join'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}