import 'package:flutter/material.dart';

import '../../data/models/feedback_summary.dart';
import '../../workouts_dependencies.dart';

class FeedbackInsightsPage extends StatelessWidget {
  const FeedbackInsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback insights'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Live updates enabled')),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<FeedbackSummary>>(
        stream: workoutFeedbackService.watchSummaries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final summaries = snapshot.data ?? const [];
          if (summaries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.insights_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text('No feedback yet', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text(
                      'Once users start submitting ratings the live dashboard will populate automatically.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          final totalResponses = summaries.fold<int>(
            0,
            (sum, item) => sum + item.responsesCount,
          );
          final avgRating = summaries.isEmpty
              ? 0
              : summaries
                        .map((s) => s.averageRating * s.responsesCount)
                        .reduce((a, b) => a + b) /
                    totalResponses;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  title: Text(
                    'Overall rating ${avgRating.toStringAsFixed(1)} / 5',
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text('$totalResponses total submissions'),
                  trailing: const Icon(Icons.query_stats),
                ),
              ),
              const SizedBox(height: 16),
              for (final summary in summaries)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                summary.featureKey,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              summary.averageRating.toStringAsFixed(1),
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.star, color: Colors.amber),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${summary.responsesCount} responses · ${_formatTimestamp(summary.lastResponseAt)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (summary.sampleComments.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: summary.sampleComments
                                .map(
                                  (comment) => Chip(
                                    avatar: const Icon(
                                      Icons.chat_bubble,
                                      size: 16,
                                    ),
                                    label: Text(comment),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _formatTimestamp(DateTime? timestamp) {
  if (timestamp == null) return 'Awaiting first submission';
  final local = timestamp.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month/$day $hour:$minute';
}
