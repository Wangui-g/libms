import '../utils/constants.dart';
import '../models/borrowing_record.dart';
// import '../models/book.dart';
import 'notification_service.dart';

class BorrowingService {
  final _supabase = supabase;
  final NotificationService _notificationService = NotificationService();

  Future<List<BorrowingRecord>> getUserBorrowingHistory(String userId) async {
    final response = await _supabase
        .from('borrowing_records')
        .select('*, books(title, author)')
        .eq('user_id', userId)
        .order('borrowed_date', ascending: false);

    return response.map<BorrowingRecord>((json) => 
        BorrowingRecord.fromJson(json)).toList();
  }

  Future<List<BorrowingRecord>> getCurrentBorrowings(String userId) async {
    final response = await _supabase
        .from('borrowing_records')
        .select('*, books(title, author)')
        .eq('user_id', userId)
        .eq('status', 'borrowed')
        .order('due_date');

    return response.map<BorrowingRecord>((json) => 
        BorrowingRecord.fromJson(json)).toList();
  }

  Future<List<BorrowingRecord>> getOverdueBooks([String? libraryId]) async {
    var query = _supabase
        .from('borrowing_records')
        .select('*, books(title, author), user_profiles(full_name)')
        .eq('status', 'borrowed')
        .lt('due_date', DateTime.now().toIso8601String());

    if (libraryId != null) {
      query = query.eq('library_id', libraryId);
    }

    final response = await query.order('due_date');

    return response.map<BorrowingRecord>((json) => 
        BorrowingRecord.fromJson(json)).toList();
  }

  Future<void> borrowBook({
    required String userId,
    required String bookId,
    required String libraryId,
    int borrowingDays = 14,
  }) async {
    // Check if book is available
    final book = await _supabase
        .from('books')
        .select()
        .eq('id', bookId)
        .single();

    if (book['available_copies'] <= 0) {
      throw Exception('Book is not available for borrowing');
    }

    // Check user's current borrowings
    final currentBorrowings = await _supabase
        .from('borrowing_records')
        .select()
        .eq('user_id', userId)
        .eq('status', 'borrowed');

    if (currentBorrowings.length >= AppConstants.maxBooksPerUser) {
      throw Exception('Maximum borrowing limit reached');
    }

    final dueDate = DateTime.now().add(Duration(days: borrowingDays));

    // Create borrowing record
    await _supabase.from('borrowing_records').insert({
      'user_id': userId,
      'book_id': bookId,
      'library_id': libraryId,
      'due_date': dueDate.toIso8601String(),
      'status': 'borrowed',
    });

    // Update book availability
    await _supabase
        .from('books')
        .update({
          'available_copies': book['available_copies'] - 1,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', bookId);

    // Send notification
    await _notificationService.createNotification(
      userId: userId,
      title: 'Book Borrowed Successfully',
      message: 'You have successfully borrowed "${book['title']}". Due date: ${dueDate.toString().split(' ')[0]}',
      type: 'return_confirmation',
    );
  }

  Future<void> returnBook({
    required String recordId,
    double damageFee = 0,
    String? notes,
  }) async {
    final record = await _supabase
        .from('borrowing_records')
        .select('*, books(*)')
        .eq('id', recordId)
        .single();

    if (record['status'] != 'borrowed') {
      throw Exception('Book is already returned');
    }

    final dueDate = DateTime.parse(record['due_date']);
    final returnDate = DateTime.now();
    double lateFee = 0;

    // Calculate late fee if overdue
    if (returnDate.isAfter(dueDate)) {
      final daysLate = returnDate.difference(dueDate).inDays;
      lateFee = daysLate * AppConstants.lateFeePerDay;
    }

    // Update borrowing record
    await _supabase
        .from('borrowing_records')
        .update({
          'returned_date': returnDate.toIso8601String(),
          'status': 'returned',
          'late_fee': lateFee,
          'damage_fee': damageFee,
          'notes': notes,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', recordId);

    // Update book availability
    final book = record['books'];
    await _supabase
        .from('books')
        .update({
          'available_copies': book['available_copies'] + 1,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', book['id']);

    // Send notification
    await _notificationService.createNotification(
      userId: record['user_id'],
      title: 'Book Returned Successfully',
      message: 'You have successfully returned "${book['title']}".' +
          (lateFee > 0 ? ' Late fee: \$${lateFee.toStringAsFixed(2)}' : '') +
          (damageFee > 0 ? ' Damage fee: \$${damageFee.toStringAsFixed(2)}' : ''),
      type: 'return_confirmation',
    );
  }

  Future<void> renewBook(String recordId, {int renewalDays = 7}) async {
    final record = await _supabase
        .from('borrowing_records')
        .select('*, books(title)')
        .eq('id', recordId)
        .single();

    if (record['status'] != 'borrowed') {
      throw Exception('Only borrowed books can be renewed');
    }

    final currentDueDate = DateTime.parse(record['due_date']);
    final newDueDate = currentDueDate.add(Duration(days: renewalDays));

    await _supabase
        .from('borrowing_records')
        .update({
          'due_date': newDueDate.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', recordId);

    // Send notification
    await _notificationService.createNotification(
      userId: record['user_id'],
      title: 'Book Renewed Successfully',
      message: 'You have successfully renewed "${record['books']['title']}". New due date: ${newDueDate.toString().split(' ')[0]}',
      type: 'due_reminder',
    );
  }

  Future<Map<String, dynamic>> getBorrowingStats(String libraryId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Total borrowings this month
    final monthlyBorrowings = await _supabase
        .from('borrowing_records')
        .select()
        .eq('library_id', libraryId)
        .gte('borrowed_date', startOfMonth.toIso8601String());

    // Currently borrowed books
    final currentBorrowings = await _supabase
        .from('borrowing_records')
        .select()
        .eq('library_id', libraryId)
        .eq('status', 'borrowed');

    // Overdue books
    final overdueBooks = await _supabase
        .from('borrowing_records')
        .select()
        .eq('library_id', libraryId)
        .eq('status', 'borrowed')
        .lt('due_date', now.toIso8601String());

    return {
      'monthly_borrowings': monthlyBorrowings.length,
      'current_borrowings': currentBorrowings.length,
      'overdue_books': overdueBooks.length,
    };
  }
}
