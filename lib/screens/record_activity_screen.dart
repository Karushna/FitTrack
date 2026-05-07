import 'dart:async';
import 'package:flutter/material.dart';

import '../services/database_service.dart';

class RecordActivityScreen extends StatefulWidget {
  const RecordActivityScreen({super.key});

  @override
  State<RecordActivityScreen> createState() => _RecordActivityScreenState();
}

class _RecordActivityScreenState extends State<RecordActivityScreen> {
  Timer? timer;
  int seconds = 0;
  bool isRunning = false;
  bool isSaving = false;

  double get distance => seconds * 0.0022;
  int get calories => (distance * 62).round();

  void toggleTimer() {
    if (isRunning) {
      timer?.cancel();
    } else {
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => seconds++);
      });
    }
    setState(() => isRunning = !isRunning);
  }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      seconds = 0;
      isRunning = false;
    });
  }

  Future<void> saveActivity() async {
    if (seconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start the timer before saving an activity')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      await DatabaseService.addActivity(
        type: 'Recorded Run',
        distanceKm: distance,
        minutes: (seconds / 60).ceil(),
        imageUrl: 'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=1000',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity saved to Supabase')),
      );

      resetTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  String formatTime() {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pace = distance <= 0 ? '-- /km' : '${(seconds / 60 / distance).toStringAsFixed(1)} /km';

    return Scaffold(
      appBar: AppBar(title: const Text('Record Activity'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?w=1000'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: Colors.black26),
              child: const Center(child: Icon(Icons.location_on, size: 82, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 26),
          Text(formatTime(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 46, fontWeight: FontWeight.bold)),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ActivityStat(title: 'Distance', value: '${distance.toStringAsFixed(2)} km'),
              ActivityStat(title: 'Pace', value: pace),
              ActivityStat(title: 'Calories', value: '$calories kcal'),
            ],
          ),
          const SizedBox(height: 38),
          SizedBox(
            width: 170,
            height: 170,
            child: ElevatedButton(
              onPressed: toggleTimer,
              style: ElevatedButton.styleFrom(shape: const CircleBorder()),
              child: Text(isRunning ? 'PAUSE' : 'START', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: resetTimer, icon: const Icon(Icons.restart_alt), label: const Text('Reset Activity')),
          ElevatedButton.icon(
            onPressed: isSaving ? null : saveActivity,
            icon: const Icon(Icons.save),
            label: Text(isSaving ? 'Saving...' : 'Save to Supabase'),
          ),
        ],
      ),
    );
  }
}

class ActivityStat extends StatelessWidget {
  final String title;
  final String value;

  const ActivityStat({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}