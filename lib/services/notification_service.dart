import '../utils/constants.dart';

class NotificationService {
  final _supabase = supabase;

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedRecordId,
  }) async {
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'related_record_id': relatedRecordId,
    });
  }

  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }

  Future<int> getUnreadCount(String userId) async {
    final response = await _supabase
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return response.length;
  }

  Future<void> sendDueReminders() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowStr = tomorrow.toIso8601String().split('T')[0];

    // Get books due tomorrow
    final dueTomorrow = await _supabase
        .from('borrowing_records')
        .select('*, books(title), user_profiles(full_name)')
        .eq('status', 'borrowed')
        .gte('due_date', '${tomorrowStr}T00:00:00')
        .lt('due_date', '${tomorrowStr}T23:59:59');

    for (final record in dueTomorrow) {
      await createNotification(
        userId: record['user_id'],
        title: 'Book Due Tomorrow',
        message: 'Your book "${record['books']['title']}" is due tomorrow. Please return or renew it.',
        type: 'due_reminder',
        relatedRecordId: record['id'],
      );
    }
  }

  Future<void> sendOverdueNotifications() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    // Get newly overdue books (due yesterday)
    final newlyOverdue = await _supabase
        .from('borrowing_records')
        .select('*, books(title)')
        .eq('status', 'borrowed')
        .lt('due_date', yesterday.toIso8601String())
        .gte('due_date', yesterday.subtract(const Duration(days: 1)).toIso8601String());

    for (final record in newlyOverdue) {
      await createNotification(
        userId: record['user_id'],
        title: 'Book Overdue',
        message: 'Your book "${record['books']['title']}" is overdue. Please return it as soon as possible to avoid additional fees.',
        type: 'overdue',
        relatedRecordId: record['id'],
      );
    }
  }
}
