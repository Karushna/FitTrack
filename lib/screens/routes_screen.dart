import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/database_service.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  void openAddRouteSheet(BuildContext context) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final distanceController = TextEditingController();
    final difficultyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Route', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Route name')),
            TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
            TextField(controller: distanceController, decoration: const InputDecoration(labelText: 'Distance km'), keyboardType: TextInputType.number),
            TextField(controller: difficultyController, decoration: const InputDecoration(labelText: 'Difficulty')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await DatabaseService.addRoute(
                  name: nameController.text.trim().isEmpty ? 'New Route' : nameController.text.trim(),
                  location: locationController.text.trim().isEmpty ? 'Sri Lanka' : locationController.text.trim(),
                  distanceKm: double.tryParse(distanceController.text) ?? 0,
                  difficulty: difficultyController.text.trim().isEmpty ? 'Easy' : difficultyController.text.trim(),
                  imageUrl: 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=900',
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add Route'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = Supabase.instance.client
        .from('routes')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Routes'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      floatingActionButton: FloatingActionButton(onPressed: () => openAddRouteSheet(context), child: const Icon(Icons.add)),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final routes = snapshot.data!;
          if (routes.isEmpty) return const Center(child: Text('No routes yet. Add one.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              final distance = (route['distance_km'] ?? 0).toDouble();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                child: Column(
                  children: [
                    Image.network(route['image_url'], height: 150, width: double.infinity, fit: BoxFit.cover),
                    ListTile(
                      title: Text(route['name'] ?? 'Route', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${route['location']} • ${distance.toStringAsFixed(1)} km • ${route['difficulty']}'),
                      leading: const CircleAvatar(backgroundColor: Color(0xFFFFE4D8), child: Icon(Icons.route, color: Color(0xFFFF5A1F))),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
}