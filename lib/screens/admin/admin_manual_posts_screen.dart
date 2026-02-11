import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/manual_post_model.dart';
import '../../services/admin_dispute_service.dart';
import '../../services/analytics_moderation.dart';

class AdminManualPostsScreen extends StatefulWidget {
  const AdminManualPostsScreen({super.key});

  @override
  State<AdminManualPostsScreen> createState() => _AdminManualPostsScreenState();
}

class _AdminManualPostsScreenState extends State<AdminManualPostsScreen> {
  final AnalyticsModerationService _analytics = AnalyticsModerationService();
  final AdminDisputeService _admin = AdminDisputeService();

  List<ManualPostModel> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _analytics.getPendingManualPosts();
    if (mounted) setState(() {
      _posts = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual analytics'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _posts.isEmpty
          ? const Center(child: Text('No pending manual posts'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _posts.length,
              itemBuilder: (context, i) {
                final p = _posts[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (p.postUrl != null) Text('URL: ${p.postUrl}', style: const TextStyle(fontSize: 12)),
                        Text('Views: ${p.views ?? 0} | Likes: ${p.likes ?? 0} | Comments: ${p.comments ?? 0}'),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async {
                                await _admin.rejectManualPost(p.id);
                                _load();
                              },
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () async {
                                await _admin.approveManualPost(p.id);
                                _load();
                              },
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
