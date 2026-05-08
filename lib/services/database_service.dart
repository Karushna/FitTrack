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
      'avatar_url': null,
    });
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
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
}