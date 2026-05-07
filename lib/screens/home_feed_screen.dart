import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/database_service.dart';

class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({super.key});

  void openAddActivitySheet(BuildContext context) {
    final typeController = TextEditingController();
    final distanceController = TextEditingController();
    final minutesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Feed Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(controller: typeController, decoration: const InputDecoration(labelText: 'Activity type')),
              TextField(controller: distanceController, decoration: const InputDecoration(labelText: 'Distance km'), keyboardType: TextInputType.number),
              TextField(controller: minutesController, decoration: const InputDecoration(labelText: 'Time minutes'), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await DatabaseService.addActivity(
                    type: typeController.text.trim().isEmpty ? 'New Activity' : typeController.text.trim(),
                    distanceKm: double.tryParse(distanceController.text) ?? 0,
                    minutes: int.tryParse(minutesController.text) ?? 0,
                    imageUrl: 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=900',
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Add Activity'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = Supabase.instance.client
        .from('activities')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FitTrack', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: const [Icon(Icons.notifications_outlined), SizedBox(width: 16)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openAddActivitySheet(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final activities = snapshot.data!;
          if (activities.isEmpty) return const Center(child: Text('No feed activities yet. Add one.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final distance = (activity['distance_km'] ?? 0).toDouble();
              final minutes = activity['minutes'] ?? 0;
              final pace = distance <= 0 ? '-- /km' : '${(minutes / distance).toStringAsFixed(1)} /km';

              return Card(
                margin: const EdgeInsets.only(bottom: 18),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: Color(0xFFFF5A1F), child: Icon(Icons.person, color: Colors.white)),
                      title: Text(activity['user_name'] ?? 'Athlete', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(activity['type'] ?? 'Activity'),
                      trailing: const Icon(Icons.more_horiz),
                    ),
                    Image.network(activity['image_url'], height: 165, width: double.infinity, fit: BoxFit.cover),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          stat('Distance', '${distance.toStringAsFixed(1)} km'),
                          stat('Time', '$minutes min'),
                          stat('Pace', pace),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    const Padding(
                      padding: EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.thumb_up_alt_outlined, size: 20),
                          SizedBox(width: 6),
                          Text('Kudos'),
                          SizedBox(width: 24),
                          Icon(Icons.comment_outlined, size: 20),
                          SizedBox(width: 6),
                          Text('Comment'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget stat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}