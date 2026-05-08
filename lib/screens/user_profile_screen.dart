import 'package:flutter/material.dart';

import '../services/database_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool isLoading = true;
  bool isFollowing = false;
  bool isUpdatingFollow = false;

  Map<String, dynamic>? profile;
  List<dynamic> activities = [];

  int followersCount = 0;
  int followingCount = 0;
  double totalDistance = 0;

  bool get isMyProfile => widget.userId == DatabaseService.currentUserId;

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    setState(() => isLoading = true);

    try {
      final userProfile = await DatabaseService.getProfileById(widget.userId);
      final userActivities = await DatabaseService.getUserActivities(widget.userId);
      final followers = await DatabaseService.getFollowersCount(widget.userId);
      final following = await DatabaseService.getFollowingCount(widget.userId);

      bool followingStatus = false;
      if (!isMyProfile) {
        followingStatus = await DatabaseService.isFollowing(widget.userId);
      }

      double distance = 0;
      for (final activity in userActivities) {
        distance += (activity['distance_km'] ?? 0).toDouble();
      }

      if (!mounted) return;

      setState(() {
        profile = userProfile;
        activities = userActivities;
        followersCount = followers;
        followingCount = following;
        isFollowing = followingStatus;
        totalDistance = distance;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> toggleFollow() async {
    if (isMyProfile || isUpdatingFollow) return;

    setState(() => isUpdatingFollow = true);

    try {
      if (isFollowing) {
        await DatabaseService.unfollowUser(widget.userId);
      } else {
        await DatabaseService.followUser(widget.userId);
      }

      await loadUserProfile();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => isUpdatingFollow = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Profile')),
        body: const Center(child: Text('User profile not found')),
      );
    }

    final name = profile?['name'] ?? 'Athlete';
    final location = profile?['location'] ?? '';
    final avatarUrl = profile?['avatar_url'];

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: loadUserProfile,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5A1F), Color(0xFFFF9D2E)],
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white,
                    backgroundImage: avatarUrl != null && avatarUrl.toString().isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.toString().isEmpty
                        ? const Icon(Icons.person, size: 54, color: Color(0xFFFF5A1F))
                        : null,
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
                  if (location.toString().isNotEmpty)
                    Text(
                      location,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  const SizedBox(height: 16),
                  if (!isMyProfile)
                    ElevatedButton.icon(
                      onPressed: isUpdatingFollow ? null : toggleFollow,
                      icon: Icon(isFollowing ? Icons.check : Icons.person_add),
                      label: Text(
                        isUpdatingFollow
                            ? 'Updating...'
                            : isFollowing
                                ? 'Following'
                                : 'Follow',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF5A1F),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                UserStat(title: 'Activities', value: '${activities.length}'),
                UserStat(title: 'Distance', value: '${totalDistance.toStringAsFixed(1)} km'),
                UserStat(title: 'Followers', value: '$followersCount'),
                UserStat(title: 'Following', value: '$followingCount'),
              ],
            ),
            const SizedBox(height: 26),
            const Text(
              'Recent Activities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (activities.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('No activities yet.'),
                ),
              ),
            ...activities.map((activity) {
              final distance = (activity['distance_km'] ?? 0).toDouble();
              final minutes = activity['minutes'] ?? 0;
              final type = activity['type'] ?? 'Activity';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFE4D8),
                    child: Icon(Icons.directions_run, color: Color(0xFFFF5A1F)),
                  ),
                  title: Text('$type - ${distance.toStringAsFixed(1)} km'),
                  subtitle: Text('$minutes min'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class UserStat extends StatelessWidget {
  final String title;
  final String value;

  const UserStat({
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}