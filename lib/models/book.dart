class Book {
  final String id;
  final String title;
  final String author;
  final String? isbn;
  final String? genreId;
  final String libraryId;
  final int totalCopies;
  final int availableCopies;
  final int? publicationYear;
  final String? description;
  final String? coverImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? genreName;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.isbn,
    this.genreId,
    required this.libraryId,
    required this.totalCopies,
    required this.availableCopies,
    this.publicationYear,
    this.description,
    this.coverImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.genreName,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      isbn: json['isbn'],
      genreId: json['genre_id'],
      libraryId: json['library_id'],
      totalCopies: json['total_copies'] ?? 1,
      availableCopies: json['available_copies'] ?? 1,
      publicationYear: json['publication_year'],
      description: json['description'],
      coverImageUrl: json['cover_image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      genreName: json['genres']?['name'],
    );
  }

  bool get isAvailable => availableCopies > 0;
}
