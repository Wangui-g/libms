import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';
import '../models/book.dart';


class BookService {
  final _supabase = supabase;

  Future<List<Book>> getBooks({
    String? libraryId,
    String? genreId,
    String? searchQuery,
  }) async {
    var query = _supabase
        .from('books')
        .select('*, genres(name)')
        .order('title') as PostgrestFilterBuilder;
   

    if (libraryId != null) {
      query = query.eq('library_id', libraryId);
    }

    if (genreId != null) {
      query = query.eq('genre_id', genreId);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
       query = query.ilike('title', '%$searchQuery%')
                 .or('author.ilike.%$searchQuery%');
    }


    final response = await query;
    return response.map<Book>((json) => Book.fromJson(json)).toList();
  }

  Future<Book?> getBookById(String bookId) async {
    final response = await _supabase
        .from('books')
        .select('*, genres(name)')
        .eq('id', bookId)
        .single();
    
    return Book.fromJson(response);
  }

  Future<void> addBook(Book book) async {
    await _supabase.from('books').insert({
      'title': book.title,
      'author': book.author,
      'isbn': book.isbn,
      'genre_id': book.genreId,
      'library_id': book.libraryId,
      'total_copies': book.totalCopies,
      'available_copies': book.availableCopies,
      'publication_year': book.publicationYear,
      'description': book.description,
      'cover_image_url': book.coverImageUrl,
    });
  }

  Future<void> updateBook(Book book) async {
    await _supabase
        .from('books')
        .update({
          'title': book.title,
          'author': book.author,
          'isbn': book.isbn,
          'genre_id': book.genreId,
          'total_copies': book.totalCopies,
          'available_copies': book.availableCopies,
          'publication_year': book.publicationYear,
          'description': book.description,
          'cover_image_url': book.coverImageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', book.id);
  }

  Future<void> deleteBook(String bookId) async {
    await _supabase.from('books').delete().eq('id', bookId);
  }

  Future<List<Map<String, dynamic>>> getGenres() async {
    final response = await _supabase
        .from('genres')
        .select()
        .order('name');
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, int>> getBookStatsByLibrary(String libraryId) async {
    final books = await getBooks(libraryId: libraryId);
    
    final stats = <String, int>{};
    int totalBooks = 0;
    int borrowedBooks = 0;
    
    for (final book in books) {
      totalBooks += book.totalCopies;
      borrowedBooks += (book.totalCopies - book.availableCopies);
    }
    
    stats['total'] = totalBooks;
    stats['borrowed'] = borrowedBooks;
    stats['available'] = totalBooks - borrowedBooks;
    
    return stats;
  }
}
