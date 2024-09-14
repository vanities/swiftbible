import re

def parse_summaries(input_file_path):
    """
    Parses the input file to extract chapter summaries for each book.

    Args:
        input_file_path (str): Path to the input file containing Swift dictionaries.

    Returns:
        dict: A dictionary with books as keys and another dictionary of chapter summaries as values.
    """
    books = {}
    current_book = None
    chapter_pattern = re.compile(r'//\s*Chapter\s+(\d+):\s*(.+)')
    book_pattern = re.compile(r'"([^"]+)":\s*\[')

    with open(input_file_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue  # Skip empty lines

            # Check if the line starts a new book
            book_match = book_pattern.match(line)
            if book_match:
                current_book = book_match.group(1)
                books[current_book] = {}
                continue

            # If within a book, look for chapter summaries
            if current_book:
                chapter_match = chapter_pattern.match(line)
                if chapter_match:
                    chapter_number = chapter_match.group(1)
                    chapter_summary = chapter_match.group(2).strip()
                    books[current_book][chapter_number] = chapter_summary
                elif line == '],':
                    current_book = None  # End of current book

    return books

def write_swift_file(books, output_file_path):
    """
    Writes the chapter summaries to a Swift file in the desired format.

    Args:
        books (dict): Dictionary containing books and their chapter summaries.
        output_file_path (str): Path to the output Swift file.
    """
    with open(output_file_path, 'w', encoding='utf-8') as f:
        f.write("let chapterSummaries: [String: [String: String]] = [\n")
        for book, chapters in books.items():
            f.write(f'    "{book}": [\n')
            for chapter, summary in chapters.items():
                # Escape double quotes in summaries
                safe_summary = summary.replace('"', '\\"')
                f.write(f'        "{chapter}": "{safe_summary}",\n')
            f.write('    ],\n')
        f.write("]\n")

def main():
    input_file = 'summaries.swift'        # Replace with your input file path
    output_file = 'ChapterSummaries.swift'  # Desired output Swift file path

    print("Parsing summaries...")
    books = parse_summaries(input_file)
    print(f"Found {len(books)} books.")

    print("Writing to Swift file...")
    write_swift_file(books, output_file)
    print(f"Swift file '{output_file}' has been created successfully.")

if __name__ == "__main__":
    main()

