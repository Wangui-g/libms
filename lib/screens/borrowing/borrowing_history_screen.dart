import 'package:flutter/material.dart';
import '../../services/borrowing_service.dart';
import '../../services/auth_service.dart';
import '../../models/borrowing_record.dart';

class BorrowingHistoryScreen extends StatefulWidget {
  const BorrowingHistoryScreen({super.key});

  @override
  State<BorrowingHistoryScreen> createState() => _BorrowingHistoryScreenState();
}

class _BorrowingHistoryScreenState extends State<BorrowingHistoryScreen>
    with SingleTickerProviderStateMixin {
  final BorrowingService _borrowingService = BorrowingService();
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  List<BorrowingRecord> _allRecords = [];
  List<BorrowingRecord> _currentBorrowings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBorrowingHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBorrowingHistory() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final allRecords = await _borrowingService.getUserBorrowingHistory(user.id);
        final currentBorrowings = await _borrowingService.getCurrentBorrowings(user.id);
        
        setState(() {
          _allRecords = allRecords;
          _currentBorrowings = currentBorrowings;
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _renewBook(BorrowingRecord record) async {
    try {
      await _borrowingService.renewBook(record.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book renewed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBorrowingHistory(); // Refresh the list
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error renewing book: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrowing History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'All History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCurrentBorrowings(),
                _buildAllHistory(),
              ],
            ),
    );
  }

  Widget _buildCurrentBorrowings() {
    if (_currentBorrowings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No books currently borrowed',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBorrowingHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _currentBorrowings.length,
        itemBuilder: (context, index) {
          final record = _currentBorrowings[index];
          final isOverdue = record.isOverdue;
          final daysUntilDue = record.dueDate.difference(DateTime.now()).inDays;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.bookTitle ?? 'Unknown Book',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'by ${record.bookAuthor ?? 'Unknown Author'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'OVERDUE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Borrowed: ${record.borrowedDate.toString().split(' ')[0]}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 16,
                        color: isOverdue ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${record.dueDate.toString().split(' ')[0]}',
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.grey[600],
                          fontSize: 14,
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${record.daysOverdue} days overdue)',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else if (daysUntilDue <= 3) ...[
                        const SizedBox(width: 8),
                        Text(
                          '($daysUntilDue days left)',
                          style: TextStyle(
                            color: daysUntilDue <= 1 ? Colors.orange : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: daysUntilDue <= 1 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (record.totalFees > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning,
                            size: 16,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Outstanding fees: \$${record.totalFees.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isOverdue)
                        TextButton.icon(
                          onPressed: () => _renewBook(record),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Renew'),
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

  Widget _buildAllHistory() {
    if (_allRecords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No borrowing history',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBorrowingHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allRecords.length,
        itemBuilder: (context, index) {
          final record = _allRecords[index];
          final isReturned = record.status == 'returned';
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isReturned ? Colors.green[100] : Colors.blue[100],
                child: Icon(
                  isReturned ? Icons.check : Icons.book,
                  color: isReturned ? Colors.green[700] : Colors.blue[700],
                ),
              ),
              title: Text(
                record.bookTitle ?? 'Unknown Book',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('by ${record.bookAuthor ?? 'Unknown Author'}'),
                  const SizedBox(height: 4),
                  Text(
                    'Borrowed: ${record.borrowedDate.toString().split(' ')[0]}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (isReturned)
                    Text(
                      'Returned: ${record.returnedDate?.toString().split(' ')[0] ?? 'Unknown'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    )
                  else
                    Text(
                      'Due: ${record.dueDate.toString().split(' ')[0]}',
                      style: TextStyle(
                        color: record.isOverdue ? Colors.red : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: record.isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isReturned ? Colors.green : 
                             record.isOverdue ? Colors.red : Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isReturned ? 'RETURNED' : 
                      record.isOverdue ? 'OVERDUE' : 'BORROWED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (record.totalFees > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '\$${record.totalFees.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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
}
