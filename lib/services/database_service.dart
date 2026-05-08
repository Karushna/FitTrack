import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  DatabaseService._();

  static final SupabaseClient client = Supabase.instance.client;

  static String get currentUserId => client.auth.currentUser!.id;
  static String get currentUserEmail => client.auth.currentUser!.email ?? '';

  // AUTH
  static Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception('Signup failed. Please check Supabase email settings.');
    }

    await client.from('profiles').upsert({
      'id': user.id,
      'name': name,
      'email': email,
      'location': '',
      'avatar_url': null,
    });
  }

  static Future<void> signIn({
  required String email,
  required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Invalid email or password');
    }
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // PROFILE
  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    return await client
        .from('profiles')
        .select()
        .eq('id', currentUserId)
        .maybeSingle();
  }

  static Future<Map<String, dynamic>?> getProfileById(String userId) async {
    return await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  static Future<void> updateLocation(String location) async {
    await client.from('profiles').update({
      'location': location,
    }).eq('id', currentUserId);
  }

  static Future<String> uploadProfileImage(File file) async {
    final userId = currentUserId;
    final filePath = '$userId/profile.jpg';

    await client.storage.from('avatars').upload(
          filePath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    final imageUrl = client.storage.from('avatars').getPublicUrl(filePath);

    await client.from('profiles').update({
      'avatar_url': imageUrl,
    }).eq('id', userId);

    return imageUrl;
  }

  static Future<void> removeProfileImage() async {
    final userId = currentUserId;
    final filePath = '$userId/profile.jpg';

    await client.storage.from('avatars').remove([filePath]);

    await client.from('profiles').update({
      'avatar_url': null,
    }).eq('id', userId);
  }

  // ACTIVITIES
  static Future<void> addActivity({
    required String type,
    required double distanceKm,
    required int minutes,
    required String imageUrl,
  }) async {
    final profile = await getCurrentProfile();

    await client.from('activities').insert({
      'user_id': currentUserId,
      'user_name': profile?['name'] ?? currentUserEmail,
      'avatar_url': profile?['avatar_url'],
      'type': type,
      'distance_km': distanceKm,
      'minutes': minutes,
      'image_url': imageUrl,
    });
  }

  static Future<List<dynamic>> getUserActivities(String userId) async {
    return await client
        .from('activities')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  // ROUTES
  static Future<void> addRoute({
    required String name,
    required String location,
    required double distanceKm,
    required String difficulty,
    required String imageUrl,
  }) async {
    await client.from('routes').insert({
      'user_id': currentUserId,
      'name': name,
      'location': location,
      'distance_km': distanceKm,
      'difficulty': difficulty,
      'image_url': imageUrl,
    });
  }

  // CHALLENGES
  static Future<void> addChallenge({
    required String title,
    required double targetKm,
  }) async {
    await client.from('challenges').insert({
      'user_id': currentUserId,
      'title': title,
      'target_km': targetKm,
      'progress_km': 0,
    });
  }

  static Future<void> joinChallenge({
    required int challengeId,
  }) async {
    await client.from('challenge_members').upsert({
      'challenge_id': challengeId,
      'user_id': currentUserId,
    });
  }

  static Future<bool> hasJoinedChallenge(int challengeId) async {
    final row = await client
        .from('challenge_members')
        .select()
        .eq('challenge_id', challengeId)
        .eq('user_id', currentUserId)
        .maybeSingle();

    return row != null;
  }

  static Future<List<dynamic>> getJoinedChallenges() async {
    return await client
        .from('challenge_members')
        .select('*, challenges(*)')
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false);
  }

  // FOLLOW SYSTEM
  static Future<int> getFollowersCount(String userId) async {
    final rows = await client
        .from('follows')
        .select()
        .eq('following_id', userId);

    return rows.length;
  }

  static Future<int> getFollowingCount(String userId) async {
    final rows = await client
        .from('follows')
        .select()
        .eq('follower_id', userId);

    return rows.length;
  }

  static Future<bool> isFollowing(String userId) async {
    final row = await client
        .from('follows')
        .select()
        .eq('follower_id', currentUserId)
        .eq('following_id', userId)
        .maybeSingle();

    return row != null;
  }

  static Future<void> followUser(String userId) async {
    if (userId == currentUserId) return;

    await client.from('follows').upsert({
      'follower_id': currentUserId,
      'following_id': userId,
    });
  }

  static Future<void> unfollowUser(String userId) async {
    await client
        .from('follows')
        .delete()
        .eq('follower_id', currentUserId)
        .eq('following_id', userId);
  }

  // KUDOS
  static Future<void> toggleKudos(int activityId) async {
    final existing = await client
        .from('kudos')
        .select()
        .eq('activity_id', activityId)
        .eq('user_id', currentUserId)
        .maybeSingle();

    if (existing == null) {
      await client.from('kudos').insert({
        'activity_id': activityId,
        'user_id': currentUserId,
      });
    } else {
      await client
          .from('kudos')
          .delete()
          .eq('activity_id', activityId)
          .eq('user_id', currentUserId);
    }
  }

  static Future<bool> hasGivenKudos(int activityId) async {
    final row = await client
        .from('kudos')
        .select()
        .eq('activity_id', activityId)
        .eq('user_id', currentUserId)
        .maybeSingle();

    return row != null;
  }

  static Future<int> getKudosCount(int activityId) async {
    final rows = await client
        .from('kudos')
        .select()
        .eq('activity_id', activityId);

    return rows.length;
  }

  // COMMENTS
  static Future<void> addComment({
    required int activityId,
    required String comment,
  }) async {
    final profile = await getCurrentProfile();

    await client.from('comments').insert({
      'activity_id': activityId,
      'user_id': currentUserId,
      'user_name': profile?['name'] ?? currentUserEmail,
      'comment': comment,
    });
  }

  static Future<List<dynamic>> getComments(int activityId) async {
    return await client
        .from('comments')
        .select()
        .eq('activity_id', activityId)
        .order('created_at', ascending: false);
  }
}