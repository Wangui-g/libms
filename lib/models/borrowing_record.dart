class BorrowingRecord {
  final String id;
  final String userId;
  final String bookId;
  final String libraryId;
  final DateTime borrowedDate;
  final DateTime dueDate;
  final DateTime? returnedDate;
  final String status;
  final double lateFee;
  final double damageFee;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? bookTitle;
  final String? bookAuthor;
  final String? userName;

  BorrowingRecord({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.libraryId,
    required this.borrowedDate,
    required this.dueDate,
    this.returnedDate,
    required this.status,
    required this.lateFee,
    required this.damageFee,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.bookTitle,
    this.bookAuthor,
    this.userName,
  });

  factory BorrowingRecord.fromJson(Map<String, dynamic> json) {
    return BorrowingRecord(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'],
      libraryId: json['library_id'],
      borrowedDate: DateTime.parse(json['borrowed_date']),
      dueDate: DateTime.parse(json['due_date']),
      returnedDate: json['returned_date'] != null 
          ? DateTime.parse(json['returned_date']) 
          : null,
      status: json['status'],
      lateFee: (json['late_fee'] ?? 0).toDouble(),
      damageFee: (json['damage_fee'] ?? 0).toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      bookTitle: json['books']?['title'],
      bookAuthor: json['books']?['author'],
      userName: json['user_profiles']?['full_name'],
    );
  }

  bool get isOverdue => 
      status == 'borrowed' && DateTime.now().isAfter(dueDate);
  
  int get daysOverdue => 
      isOverdue ? DateTime.now().difference(dueDate).inDays : 0;
  
  double get totalFees => lateFee + damageFee;
}
