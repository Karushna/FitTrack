import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/database_service.dart';
import 'user_profile_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void openAddActivitySheet(BuildContext context) {
    final typeController = TextEditingController();
    final distanceController = TextEditingController();
    final minutesController = TextEditingController();

    showModalBottomSheet(
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
                'Add Feed Activity',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: typeController,
                decoration: const InputDecoration(labelText: 'Activity type'),
              ),
              TextField(
                controller: distanceController,
                decoration: const InputDecoration(labelText: 'Distance km'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: minutesController,
                decoration: const InputDecoration(labelText: 'Time minutes'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await DatabaseService.addActivity(
                      type: typeController.text.trim().isEmpty
                          ? 'New Activity'
                          : typeController.text.trim(),
                      distanceKm: double.tryParse(distanceController.text) ?? 0,
                      minutes: int.tryParse(minutesController.text) ?? 0,
                      imageUrl:
                          'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=900',
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                    }

                    setState(() {});
                  } catch (e) {
                    showMessage(e.toString());
                  }
                },
                child: const Text('Add Activity'),
              ),
            ],
          ),
        );
      },
    );
  }

  void openUserProfile(String? userId) {
    if (userId == null || userId.isEmpty) {
      showMessage('This activity does not have a valid user profile.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: userId),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  void openCommentsSheet(int activityId) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> addComment() async {
              final text = commentController.text.trim();

              if (text.isEmpty) return;

              try {
                await DatabaseService.addComment(
                  activityId: activityId,
                  comment: text,
                );

                commentController.clear();
                setSheetState(() {});
                setState(() {});
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SizedBox(
                height: 430,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: FutureBuilder<List<dynamic>>(
                        future: DatabaseService.getComments(activityId),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(snapshot.error.toString()),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final comments = snapshot.data!;

                          if (comments.isEmpty) {
                            return const Center(
                              child: Text('No comments yet. Be the first.'),
                            );
                          }

                          return ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];

                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFFFE4D8),
                                  child: Icon(
                                    Icons.person,
                                    color: Color(0xFFFF5A1F),
                                  ),
                                ),
                                title: Text(
                                  comment['user_name']?.toString() ?? 'User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  comment['comment']?.toString() ?? '',
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: const InputDecoration(
                              hintText: 'Write a comment...',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => addComment(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Color(0xFFFF5A1F),
                          ),
                          onPressed: addComment,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      commentController.dispose();
      setState(() {});
    });
  }

  Widget buildAvatar(Map<String, dynamic> activity) {
    final avatarUrl = activity['avatar_url']?.toString();

    return CircleAvatar(
      backgroundColor: const Color(0xFFFF5A1F),
      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
          ? NetworkImage(avatarUrl)
          : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? const Icon(Icons.person, color: Colors.white)
          : null,
    );
  }

  Widget buildActivityImage(Map<String, dynamic> activity) {
    final imageUrl = activity['image_url']?.toString();

    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: 165,
        width: double.infinity,
        color: const Color(0xFFFFE4D8),
        child: const Icon(
          Icons.image_not_supported,
          size: 42,
          color: Color(0xFFFF5A1F),
        ),
      );
    }

    return Image.network(
      imageUrl,
      height: 165,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 165,
          width: double.infinity,
          color: const Color(0xFFFFE4D8),
          child: const Icon(
            Icons.broken_image,
            size: 42,
            color: Color(0xFFFF5A1F),
          ),
        );
      },
    );
  }

  Widget stat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> toggleKudos(int activityId) async {
    try {
      await DatabaseService.toggleKudos(activityId);
      setState(() {});
    } catch (e) {
      showMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = Supabase.instance.client
        .from('activities')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FitTrack',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: const [
          Icon(Icons.notifications_outlined),
          SizedBox(width: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openAddActivitySheet(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final activities = snapshot.data!;

          if (activities.isEmpty) {
            return const Center(
              child: Text('No feed activities yet. Add one.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];

              final activityId = activity['id'];
              final userId = activity['user_id']?.toString();

              if (activityId == null) {
                return const SizedBox.shrink();
              }

              final int id = activityId as int;
              final distance = (activity['distance_km'] ?? 0).toDouble();
              final minutes = activity['minutes'] ?? 0;
              final pace = distance <= 0
                  ? '-- /km'
                  : '${(minutes / distance).toStringAsFixed(1)} /km';

              return Card(
                margin: const EdgeInsets.only(bottom: 18),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      onTap: () => openUserProfile(userId),
                      leading: buildAvatar(activity),
                      title: Text(
                        activity['user_name']?.toString() ?? 'Athlete',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        activity['type']?.toString() ?? 'Activity',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                    buildActivityImage(activity),
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
                    FutureBuilder<List<dynamic>>(
                      future: Future.wait([
                        DatabaseService.hasGivenKudos(id),
                        DatabaseService.getKudosCount(id),
                        DatabaseService.getComments(id),
                      ]),
                      builder: (context, actionSnapshot) {
                        final hasKudos =
                            actionSnapshot.data?[0] as bool? ?? false;
                        final kudosCount =
                            actionSnapshot.data?[1] as int? ?? 0;
                        final comments =
                            actionSnapshot.data?[2] as List<dynamic>? ?? [];

                        return Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => toggleKudos(id),
                                child: Row(
                                  children: [
                                    Icon(
                                      hasKudos
                                          ? Icons.thumb_up_alt
                                          : Icons.thumb_up_alt_outlined,
                                      size: 20,
                                      color: hasKudos
                                          ? const Color(0xFFFF5A1F)
                                          : Colors.black,
                                    ),
                                    const SizedBox(width: 6),
                                    Text('Kudos $kudosCount'),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              InkWell(
                                onTap: () => openCommentsSheet(id),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.comment_outlined,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text('Comment ${comments.length}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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