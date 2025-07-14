-- Insert sample libraries
INSERT INTO libraries (id, name, address, phone, email) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'Central Public Library', '123 Main St, City Center', '+1-555-0101', 'central@library.com'),
('550e8400-e29b-41d4-a716-446655440002', 'University Library', '456 Campus Ave, University District', '+1-555-0102', 'university@library.edu'),
('550e8400-e29b-41d4-a716-446655440003', 'Community Branch Library', '789 Oak St, Residential Area', '+1-555-0103', 'community@library.com');

-- Insert sample genres
INSERT INTO genres (name, description) VALUES
('Fiction', 'Literary works of imagination'),
('Non-Fiction', 'Factual and informational books'),
('Science Fiction', 'Speculative fiction with futuristic concepts'),
('Romance', 'Stories focused on romantic relationships'),
('Mystery', 'Stories involving puzzles and investigations'),
('Biography', 'Life stories of real people'),
('History', 'Books about past events'),
('Science', 'Scientific knowledge and discoveries'),
('Technology', 'Books about technological advances'),
('Self-Help', 'Books for personal improvement');

-- Insert sample books
INSERT INTO books (title, author, isbn, genre_id, library_id, total_copies, available_copies, publication_year, description) VALUES
('The Great Gatsby', 'F. Scott Fitzgerald', '9780743273565', (SELECT id FROM genres WHERE name = 'Fiction'), '550e8400-e29b-41d4-a716-446655440001', 5, 3, 1925, 'A classic American novel set in the Jazz Age'),
('To Kill a Mockingbird', 'Harper Lee', '9780061120084', (SELECT id FROM genres WHERE name = 'Fiction'), '550e8400-e29b-41d4-a716-446655440001', 4, 2, 1960, 'A story of racial injustice and childhood innocence'),
('1984', 'George Orwell', '9780451524935', (SELECT id FROM genres WHERE name = 'Science Fiction'), '550e8400-e29b-41d4-a716-446655440002', 6, 4, 1949, 'A dystopian social science fiction novel'),
('Pride and Prejudice', 'Jane Austen', '9780141439518', (SELECT id FROM genres WHERE name = 'Romance'), '550e8400-e29b-41d4-a716-446655440002', 3, 1, 1813, 'A romantic novel of manners'),
('The Catcher in the Rye', 'J.D. Salinger', '9780316769174', (SELECT id FROM genres WHERE name = 'Fiction'), '550e8400-e29b-41d4-a716-446655440003', 4, 4, 1951, 'A coming-of-age story in New York City');
