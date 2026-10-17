import 'package:flutter/material.dart';

class AnnouncementItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;

  const AnnouncementItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
  });
}

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final announcements = [
      AnnouncementItem(
        id: '1',
        title: 'Midterm Examination Schedule Released',
        body:
            'The schedule for the upcoming midterm examinations has been officially published. Check the student portal for room details.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AnnouncementItem(
        id: '2',
        title: 'System Maintenance Notice',
        body:
            'Campus Portal services will undergo routine maintenance tonight from 23:00 to 02:00 WIB.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AnnouncementItem(
        id: '3',
        title: 'Guest Lecture: Mobile Security & Cloud Messaging',
        body:
            'Join the seminar on modern authentication protocols and FCM architecture this Friday in Auditorium 2.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Announcements'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: announcements.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = announcements[index];
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.notifications_active,
                          size: 18, color: Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.body,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')} • ${_formatDate(item.timestamp)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
