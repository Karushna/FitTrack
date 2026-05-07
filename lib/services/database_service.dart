import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  DatabaseService._();

  static final SupabaseClient client = Supabase.instance.client;

  static String get currentUserId => client.auth.currentUser!.id;
  static String get currentUserEmail => client.auth.currentUser!.email ?? '';

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
      'location': 'Colombo, Sri Lanka',
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

  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    return await client
        .from('profiles')
        .select()
        .eq('id', currentUserId)
        .maybeSingle();
  }

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
      'type': type,
      'distance_km': distanceKm,
      'minutes': minutes,
      'image_url': imageUrl,
    });
  }

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