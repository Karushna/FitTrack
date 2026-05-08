import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
    final activities =
        await DatabaseService.getUserActivities(DatabaseService.currentUserId);
    final joinedChallenges = await DatabaseService.getJoinedChallenges();
    final followersCount =
        await DatabaseService.getFollowersCount(DatabaseService.currentUserId);

    double totalDistance = 0;

    for (final activity in activities) {
      totalDistance += (activity['distance_km'] ?? 0).toDouble();
    }

    return {
      'profile': profile,
      'activities': activities,
      'joinedChallenges': joinedChallenges,
      'totalDistance': totalDistance,
      'followersCount': followersCount,
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

      setState(() => isUploading = true);

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
      if (mounted) setState(() => isUploading = false);
    }
  }

  Future<void> updateLocation(String currentLocation) async {
    final locationController = TextEditingController(text: currentLocation);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Update Location',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Your location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  await DatabaseService.updateLocation(
                    locationController.text.trim(),
                  );

                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.save),
                label: const Text('Save Location'),
              ),
            ],
          ),
        );
      },
    );

    locationController.dispose();

    if (mounted) setState(() {});
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
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data!['profile'] as Map<String, dynamic>?;
          final activities = snapshot.data!['activities'] as List<dynamic>;
          final joinedChallenges =
              snapshot.data!['joinedChallenges'] as List<dynamic>;
          final totalDistance = snapshot.data!['totalDistance'] as double;
          final followersCount = snapshot.data!['followersCount'] as int;

          final name = profile?['name'] ?? 'User Athlete';
          final location = profile?['location']?.toString() ?? '';
          final avatarUrl = profile?['avatar_url']?.toString();

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
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
                      const SizedBox(height: 4),
                      Text(
                        location.isEmpty ? 'No location added' : location,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => updateLocation(location),
                        icon: const Icon(Icons.edit_location_alt),
                        label: const Text('Edit Location'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
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
                    ProfileStat(
                      title: 'Followers',
                      value: followersCount.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const Text(
                  'Your Recent Activities',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (activities.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('No activities yet. Add one from Feed or Record.'),
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
                const SizedBox(height: 26),
                const Text(
                  'Joined Challenges',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (joinedChallenges.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('No joined challenges yet.'),
                    ),
                  ),
                ...joinedChallenges.map((item) {
                  final challenge = item['challenges'];

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.emoji_events,
                        color: Color(0xFFFF5A1F),
                      ),
                      title: Text(challenge?['title'] ?? 'Challenge'),
                      subtitle: Text(
                        '${challenge?['target_km'] ?? 0} km target',
                      ),
                    ),
                  );
                }),
              ],
            ),
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
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 8,
          ),
          child: Column(
            children: [
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}