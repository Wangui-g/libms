import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AppConstants {
  static const String appName = 'Library Management System';
  static const int defaultBorrowingDays = 14;
  static const double lateFeePerDay = 0.50;
  static const int maxBooksPerUser = 5;
  static const int renewalDays = 7;
}

enum UserType {
  student,
  faculty,
  public,
  librarian,
}

enum BorrowingStatus {
  borrowed,
  returned,
  overdue,
}

enum NotificationType {
  dueReminder,
  overdue,
  returnConfirmation,
  feeNotice,
  general,
}
