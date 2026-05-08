import 'package:flutter/material.dart';

class RouteDetailScreen extends StatelessWidget {
  final Map<String, dynamic> route;

  const RouteDetailScreen({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final distance = (route['distance_km'] ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(title: Text(route['name'] ?? 'Route')),
      body: ListView(
        children: [
          Image.network(
            route['image_url'],
            height: 240,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route['name'] ?? 'Route',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(route['location'] ?? ''),
                const SizedBox(height: 16),
                Text('Distance: ${distance.toStringAsFixed(1)} km'),
                Text('Difficulty: ${route['difficulty'] ?? 'Easy'}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}