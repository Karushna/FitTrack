import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/database_service.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isUploading = false;

  Future<Map<String, dynamic>> loadProfileData() async {
    final profile = await DatabaseService.getCurrentProfile();

    final activities = await Supabase.instance.client
        .from('activities')
        .select()
        .eq('user_id', DatabaseService.currentUserId)
        .order('created_at', ascending: false);

    double totalDistance = 0;

    for (final activity in activities) {
      totalDistance += (activity['distance_km'] ?? 0).toDouble();
    }

    return {
      'profile': profile,
      'activities': activities,
      'totalDistance': totalDistance,
    };
  }

  Future<void> pickAndUploadImage() async {
    try {
      final picker = ImagePicker();

      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      setState(() {
        isUploading = true;
      });

      await DatabaseService.uploadProfileImage(File(pickedFile.path));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated')),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  Future<void> logout(BuildContext context) async {
    await DatabaseService.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: loadProfileData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final profile = snapshot.data!['profile'] as Map<String, dynamic>?;
          final activities = snapshot.data!['activities'] as List<dynamic>;
          final totalDistance = snapshot.data!['totalDistance'] as double;

          final name = profile?['name'] ?? 'User Athlete';
          final location = profile?['location'] ?? 'Colombo, Sri Lanka';
          final avatarUrl = profile?['avatar_url']?.toString();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF5A1F),
                      Color(0xFFFF9D2E),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: isUploading ? null : pickAndUploadImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.white24,
                            backgroundImage:
                                avatarUrl != null && avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 54,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          if (isUploading)
                            const CircleAvatar(
                              radius: 52,
                              backgroundColor: Colors.black38,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          const Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 17,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Color(0xFFFF5A1F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      location,
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap image to update profile picture',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ProfileStat(
                    title: 'Activities',
                    value: activities.length.toString(),
                  ),
                  ProfileStat(
                    title: 'Distance',
                    value: '${totalDistance.toStringAsFixed(1)} km',
                  ),
                  const ProfileStat(
                    title: 'Followers',
                    value: '125',
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const Text(
                'Your Recent Activities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (activities.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'No activities yet. Add one from Feed or Record.',
                    ),
                  ),
                ),
              ...activities.map((activity) {
                final distance = (activity['distance_km'] ?? 0).toDouble();

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.directions_run,
                      color: Color(0xFFFF5A1F),
                    ),
                    title: Text(
                      '${activity['type']} - ${distance.toStringAsFixed(1)} km',
                    ),
                    subtitle: Text('${activity['minutes']} min'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class ProfileStat extends StatelessWidget {
  final String title;
  final String value;

  const ProfileStat({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}