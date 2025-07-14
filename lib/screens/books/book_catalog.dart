import 'package:flutter/material.dart';
import '../../services/book_service.dart';
import '../../services/borrowing_service.dart';
import '../../services/auth_service.dart';
import '../../models/book.dart';
// import '../../utils/constants.dart';

class BookCatalogScreen extends StatefulWidget {
  const BookCatalogScreen({super.key});

  @override
  State<BookCatalogScreen> createState() => _BookCatalogScreenState();
}

class _BookCatalogScreenState extends State<BookCatalogScreen> {
  final BookService _bookService = BookService();
  final BorrowingService _borrowingService = BorrowingService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Book> _books = [];
  List<Map<String, dynamic>> _genres = [];
  bool _isLoading = true;
  String? _selectedGenre;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final books = await _bookService.getBooks(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        genreId: _selectedGenre,
      );
      final genres = await _bookService.getGenres();
      
      setState(() {
        _books = books;
        _genres = genres;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading books: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _borrowBook(Book book) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      await _borrowingService.borrowBook(
        userId: user.id,
        bookId: book.id,
        libraryId: book.libraryId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully borrowed "${book.title}"'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Refresh the list
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error borrowing book: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBookDetails(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Author: ${book.author}'),
              if (book.isbn != null) Text('ISBN: ${book.isbn}'),
              if (book.genreName != null) Text('Genre: ${book.genreName}'),
              if (book.publicationYear != null) 
                Text('Published: ${book.publicationYear}'),
              Text('Available: ${book.availableCopies}/${book.totalCopies}'),
              if (book.description != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(book.description!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (book.isAvailable)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _borrowBook(book);
              },
              child: const Text('Borrow'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Catalog'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search books by title or author...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _loadData();
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    setState(() => _searchQuery = value);
                    _loadData();
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedGenre,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Genre',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Genres'),
                    ),
                    ..._genres.map((genre) {
                      return DropdownMenuItem(
                        value: genre['id'],
                        child: Text(genre['name']),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedGenre = value);
                    _loadData();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _books.isEmpty
                    ? const Center(
                        child: Text(
                          'No books found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _books.length,
                        itemBuilder: (context, index) {
                          final book = _books[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: book.coverImageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          book.coverImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.book,
                                              color: Colors.blue,
                                            );
                                          },
                                        ),
                                      )
                                    : const Icon(
                                        Icons.book,
                                        color: Colors.blue,
                                      ),
                              ),
                              title: Text(
                                book.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('by ${book.author}'),
                                  if (book.genreName != null)
                                    Text(
                                      book.genreName!,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      Icon(
                                        book.isAvailable
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        size: 16,
                                        color: book.isAvailable
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        book.isAvailable
                                            ? 'Available (${book.availableCopies})'
                                            : 'Not Available',
                                        style: TextStyle(
                                          color: book.isAvailable
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.info_outline),
                                    onPressed: () => _showBookDetails(book),
                                  ),
                                  if (book.isAvailable)
                                    ElevatedButton(
                                      onPressed: () => _borrowBook(book),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(80, 36),
                                      ),
                                      child: const Text('Borrow'),
                                    ),
                                ],
                              ),
                              onTap: () => _showBookDetails(book),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
