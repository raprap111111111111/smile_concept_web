import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ActivityCard extends StatelessWidget {
  final List<dynamic> activities;

  const ActivityCard(this.activities, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Patient Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            const Center(child: Text('No recent activity', style: TextStyle(color: Colors.white70)))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length > 5 ? 5 : activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Colors.grey),
                  title: Text(activity['patientName'] ?? 'Unknown'),
                  subtitle: Text(activity['action'] ?? ''),
                  trailing: Text(
                    activity['timeAgo'] ?? '',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}