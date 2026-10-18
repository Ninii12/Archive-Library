import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ArchiveApp());
}


 class ArchiveApp extends StatelessWidget {
  const ArchiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: ArchiveScrollBehavior(),
      home: ArchiveRoom(),
    );
  }
}

// Lets the shelf rows be dragged sideways with a mouse or trackpad,
// not only with a finger.
class ArchiveScrollBehavior extends MaterialScrollBehavior {
  const ArchiveScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
class ArchiveRoom extends StatefulWidget {
  const ArchiveRoom({super.key});

  @override
  State<ArchiveRoom> createState() => _ArchiveRoomState();
}

class _ArchiveRoomState extends State<ArchiveRoom> {
  String selectedStatus = "Want to read";
  List<Book> books = [];
  @override
void initState() {
  super.initState();
  loadBooks();
}

Future<void> loadBooks() async {
  final prefs = await SharedPreferences.getInstance();
  final savedBooks = prefs.getString('saved_books');
  print('SAVED BOOKS: $savedBooks');

  if (savedBooks != null) {
  final List<dynamic> decodedBooks = jsonDecode(savedBooks);

  setState(() {
    books = decodedBooks
        .map((item) => Book.fromJson(item as Map<String, dynamic>))
        .toList();
  });
}
}
Future<void> saveBooks() async {
  final prefs = await SharedPreferences.getInstance();

  final encodedBooks = jsonEncode(
    books.map((book) => book.toJson()).toList(),
  );

  await prefs.setString('saved_books', encodedBooks);
}

// One shelf: a bottom-aligned row of books that scrolls sideways
// when the row is wider than the shelf.
Widget shelfSpace(List<Book> shelfRowBooks) {
  return Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border.all(
          color: const Color(0xFF222222),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              height: constraints.maxHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 5),
                  for (var i = 0; i < shelfRowBooks.length; i++)
                    shelfBook(shelfRowBooks[i], i),
                  const SizedBox(width: 5),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

// A single book spine standing on the shelf.
Widget shelfBook(Book book, int position) {
  return GestureDetector(
    onTap: () {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(book.title),
            content: Text(
              "Author: ${book.author}\n"
              "Genre: ${book.genre}\n"
              "Status: ${book.status}",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    book.status = "Currently reading";
                  });
                  saveBooks();
                  Navigator.pop(dialogContext);
                },
                child: const Text("Read now"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    book.status = "Want to read";
                  });
                  saveBooks();
                  Navigator.pop(dialogContext);
                },
                child: const Text("Want to read"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);

                  final titleController =
                      TextEditingController(text: book.title);
                  final authorController =
                      TextEditingController(text: book.author);
                  final genreController =
                      TextEditingController(text: book.genre);

                  showDialog(
                    context: context,
                    builder: (editContext) => AlertDialog(
                      title: const Text("Edit Book"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: titleController,
                            decoration:
                                const InputDecoration(labelText: "Title"),
                          ),
                          TextField(
                            controller: authorController,
                            decoration:
                                const InputDecoration(labelText: "Author"),
                          ),
                          TextField(
                            controller: genreController,
                            decoration:
                                const InputDecoration(labelText: "Genre"),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(editContext),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              book.title = titleController.text;
                              book.author = authorController.text;
                              book.genre = genreController.text;
                            });
                            saveBooks();
                            Navigator.pop(editContext);
                          },
                          child: const Text("Save"),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text("Edit"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Close"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    books.remove(book);
                  });
                  saveBooks();
                  Navigator.pop(dialogContext);
                },
                child: const Text("Delete"),
              ),
            ],
          );
        },
      );
    },
    child: Container(
      width: 24 + (position % 3) * 3,
      height: 65,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: book.color,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: const Color(0xFF222222),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 1,
            offset: Offset(1, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF222222),
            fontSize: 9,
          ),
        ),
      ),
    ),
  );
}

  

  @override
  Widget build(BuildContext context) {
    final finishedBooks =
        books.where((book) => book.status == "Finished").toList();

    // Finished books fill the shelves from the bottom up, seven per
    // shelf so that every populated row has more books than fit and
    // scrolls sideways. Extra books stay on the top shelf.
    const booksPerShelf = 7;
    final shelfRows = List<List<Book>>.generate(5, (_) => <Book>[]);
    for (var i = 0; i < finishedBooks.length; i++) {
      final level = i ~/ booksPerShelf;
      shelfRows[level > 4 ? 4 : level].add(finishedBooks[i]);
    }

    return Scaffold(
      body: Stack(
        children: [
          // Wall
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF7F7F7),
                ],
              ),
            ),
          ),

          // Wooden floor. Kept beneath the bookshelf and non-interactive,
          // so it never paints over or blocks the shelf rows.
          IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: CustomPaint(
                  painter: CheckerFloorPainter(),
                ),
              ),
            ),
          ),

          // Bookshelf
          Positioned(
            left: 50,
            top: 70,
            width: 230,
            height: 480,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
  Color(0xFFFFFFFF),
  Color(0xFFF7F7F7),
  Color(0xFFFFFFFF),
],

                ),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
  color: const Color(0xFF222222),
  width: 4,
),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 24,
                    offset: Offset(10, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
  color: const Color(0xFFD6D6D6),
  width: 2,
),
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var level = 4; level >= 0; level--) ...[
                      shelfSpace(shelfRows[level]),
                      if (level > 0) shelfBoard(),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Hangingcreeper (non-interactive so it never blocks books)
          Positioned(
            left: 25,
            top: 55,
            width: 90,
            height: 260,
            child: IgnorePointer(
              child: CustomPaint(
                painter: CreeperPainter(),
              ),
            ),
          ),
          // Reading chair
          Positioned(
            left: 340,
            bottom: 130,
            width: 160,
            height: 200,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Backrest
                Positioned(
                  top: 10,
                  child: Container(
                    width: 100,
                    height: 95,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFF222222),
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
  BoxShadow(
    color: Color(0xFFD6D6D6),
    offset: Offset(3, 3),
    blurRadius: 0,
  ),
],
                    ),
                  ),
                ),

                // Inner backrest seam
                Positioned(
                  top: 28,
                  child: Container(
                    width: 2,
                    height: 55,
                    color: const Color(0xFFBDBDBD),
                  ),
                ),

                // Seat

                Positioned(
                  top: 95,
                  child: Container(
                    width: 125,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFF222222),
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),

                // Front legs
Positioned(
  top: 115,
  left: 25,
  child: Row(
    children: [
      Container(
        width: 2,
        height: 55,
        color: const Color(0xFFD6D6D6),
      ),
      Container(
        width: 7,
        height: 55,
        color: const Color(0xFF222222),
      ),
    ],
  ),
),
Positioned(
  top: 115,
  right: 25,
  child: Row(
    children: [
      Container(
        width: 7,
        height: 55,
        color: const Color(0xFF222222),
      ),
      Container(
        width: 2,
        height: 55,
        color: const Color(0xFFD6D6D6),
      ),
    ],
  ),
),

                // Side legs
Positioned(
  top: 110,
  left: 10,
  child: Row(
    children: [
      Container(
        width: 2,
        height: 48,
        color: const Color(0xFFD6D6D6),
      ),
      Container(
        width: 7,
        height: 48,
        color: const Color(0xFF222222),
      ),
    ],
  ),
),
Positioned(
  top: 110,
  right: 10,
  child: Row(
    children: [
      Container(
        width: 7,
        height: 48,
        color: const Color(0xFF222222),
      ),
      Container(
        width: 2,
        height: 48,
        color: const Color(0xFFD6D6D6),
      ),
    ],
  ),
),
 ],
            ),
          ),


// Small plant beside the reading table
Positioned(
  left: 760,
  bottom: 130,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Plant leaves
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 15,
            height: 25,
            decoration: BoxDecoration(
              color: const Color(0xFFB8D8C0),
              border: Border.all(
                color: const Color(0xFF222222),
                width: 2,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
          Container(
            width: 15,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFCDBCEB),
              border: Border.all(
                color: const Color(0xFF222222),
                width: 2,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
          Container(
            width: 15,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFB8D8C0),
              border: Border.all(
                color: const Color(0xFF222222),
                width: 2,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
        ],
      ),

      // Plant pot
      Container(
        width: 48,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF2B8C6),
          border: Border.all(
            color: const Color(0xFF222222),
            width: 2,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(8),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFD6D6D6),
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
      ),
    ],
  ),
),


          // Large reading table
          Positioned(
            left: 410,
            bottom: 130,
            width: 380,
            height: 190,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 380,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
  color: const Color(0xFF222222),
  width: 4,
),
boxShadow: [
  BoxShadow(
    color: const Color(0xFFD6D6D6),
    offset: const Offset(3, 3),
    blurRadius: 0,
  ),
],
                  ),
                ),
                Container(
  width: 340,
  height: 125,
  decoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(
      color: const Color(0xFF222222),
      width: 4,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFFD6D6D6),
        offset: const Offset(3, 3),
        blurRadius: 0,
      ),
    ],
  ),
),

              ],
            ),
          ),

for (final entry in books
    .asMap()
    .entries
    .where((entry) => entry.value.status == "Currently reading")
    .toList()
    .asMap()
    .entries)
  Positioned(
    left: 480 + (entry.key * 55),
    bottom: 280,
    child: GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(entry.value.value.title),
            content: Text(
              "Author: ${entry.value.value.author}\n"
              "Genre: ${entry.value.value.genre}\n"
              "Status: ${entry.value.value.status}",
            ),
            actions: [
  TextButton(
    onPressed: () {
      setState(() {
        entry.value.value.status = "Want to read";
      });
      saveBooks();
      Navigator.pop(context);
    },
    child: const Text("Want to read"),
  ),
  TextButton(
    onPressed: () {
      setState(() {
        entry.value.value.status = "Finished";
      });
      saveBooks();
      Navigator.pop(context);
    },
    child: const Text("Finished"),
  ),
  TextButton(
  onPressed: () {
    setState(() {
      books.remove(entry.value.value);
    });
    saveBooks();
    Navigator.pop(context);
  },
  child: const Text("Delete"),
),
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: const Text("Close"),
  ),
],
          ),
        );
      },
      child: Container(
        width: 45,
        height: 12,
        decoration: BoxDecoration(
          color: entry.value.value.color,
          border: Border.all(
            color: const Color(0xFF222222),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  ),

  // Want to read books on the floor
          for (final entry in books
              .asMap()
              .entries
              .where((entry) => entry.value.status == "Want to read")
              .toList()
              .asMap()
              .entries)
            Positioned(
              left: 830 + (entry.key * 70),
              bottom: 160 + (entry.key ~/ 4) * 18,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(entry.value.value.title),
                      content: Text(
                        "Author: ${entry.value.value.author}\n"
                        "Genre: ${entry.value.value.genre}\n"
                        "Status: ${entry.value.value.status}",
                      ),
                      actions: [
  TextButton(
    onPressed: () {
      setState(() {
        entry.value.value.status = "Currently reading";
      });
      Navigator.pop(context);
    },
    child: const Text("Read now"),
  ),
  TextButton(
  onPressed: () {
    setState(() {
      entry.value.value.status = "Finished";
    });

    saveBooks();
    Navigator.pop(context);
  },
  child: const Text("Finished"),
),
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: const Text("Close"),
  ),
  TextButton(
  onPressed: () {
    setState(() {
      books.remove(entry.value.value);
    });
    saveBooks();
    Navigator.pop(context);
  },
  child: const Text("Delete"),
),
],

                    ),
                  );
                },
                child: Container(
                  width: 65,
                  height: 26,
                  decoration: BoxDecoration(
                    color: entry.value.value.color,
                    border: Border.all(
                      color: const Color(0xFF222222),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.value.value.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
  fontSize: 9,
  fontWeight: FontWeight.bold,
  color: Color(0xFF222222),
),
                  ),
                ),
              ),
            ),
          
          
// Wall picture frame
          Positioned(
            left: 500,
            top: 90,
            child: Container(
              width: 90,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFF222222),
                  width: 4,
                ),
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2B8C6),
                    border: Border.all(
                      color: const Color(0xFF222222),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 5,
                        right: 5,
                        top: 5,
                        child: Container(
                          height: 1,
                          color: const Color(0xFF222222),
                        ),
                      ),
                      Positioned(
                        left: 5,
                        right: 5,
                        bottom: 5,
                        child: Container(
                          height: 1,
                          color: const Color(0xFF222222),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // One Piece frame on the right wall, near the curtain
          Positioned(
            right: 160,
            top: 200,
            child: Container(
              width: 130,
              height: 165,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF222222), width: 4),
              ),
              child: Center(
                child: Container(
                  width: 94,
                  height: 129,
                  color: const Color(0xFF1C1C1C),
                  child: CustomPaint(
                    painter: OnePieceArtPainter(),
                  ),
                ),
              ),
            ),
          ),

          // Curtain rod
          Positioned(
            right: 0,
            top: 65,
            child: Container(
              width: 145,
              height: 5,
              color: const Color(0xFF222222),
            ),
          ),

          // Curtain rod end knob
          Positioned(
            right: 135,
            top: 58,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                shape: BoxShape.circle,
              ),
            ),
          ),



          // Long white curtain
          Positioned(
            right: 0,
            top: 70,
            bottom: 150,
            width: 130,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFF222222),
                  width: 3,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
  5,
  (index) => Container(
    width: 1,
    margin: const EdgeInsets.symmetric(horizontal: 2),
    color: const Color(0xFF222222),
  ),
),
              ),
            ),
          ),
           

          // Night lamp
          Positioned(
            left: 690,
            bottom: 285,
            width: 70,
            height: 110,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 70,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                     color: const Color(0xFF222222),
                      width: 3,
                    ),
                    
                  ),
                ),
                Container(
                  width: 8,
                  height: 45,
                  color: const Color(0xFF222222),
                ),
                Container(
                  width: 35,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),

          // Welcome text
          const Positioned(
            top: 35,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Your shelves are waiting.",
                style: TextStyle(
                  fontSize: 25,
                  color: Color(0xFF4A3828),
                ),
              ),
            ),
          ),
          

          // Add book button
          Positioned(
            top: 110,
            right: 180,
            child: ElevatedButton.icon(
              onPressed: () {
                
  
  showDialog(
  context: context,
  builder: (context) {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final genreController = TextEditingController();

    return AlertDialog(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(18),
  ),
      backgroundColor: const Color(0xFFF1D9E8),
     title: const Text(
  "Add a new book",
  style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Color(0xFF4A3022),
  ),
),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: InputDecoration(
  labelText: "Book title",
  hintText: "Enter the book title",
  filled: true,
  fillColor: const Color(0xFFFFF8F0),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
),
          ),
          const SizedBox(height: 16),
          TextField(
           controller: authorController,
            decoration: InputDecoration(
              labelText: "Author",
              hintText: "Enter the author's name",
              filled: true,
              fillColor: const Color(0xFFFFF8F0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: genreController,
            decoration: InputDecoration(
  labelText: "Genre",
  hintText: "e.g. Fiction, Romance, Fantasy",
  filled: true,
  fillColor: const Color(0xFFFFF8F0),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            initialValue: "Want to read",
            decoration: InputDecoration(
              labelText: "Status",
              filled: true,
              fillColor: const Color(0xFFFFF8F0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: "Currently reading",
                child: Text("Currently reading"),
              ),
              DropdownMenuItem(
                value: "Want to read",
                child: Text("Want to read"),
              ),
              DropdownMenuItem(
                value: "Finished",
                child: Text("Finished"),
              ),
            ],
            onChanged: (value) {
              setState(() {
                selectedStatus = value!;
              });
            },
          ),

        ],
      ),
      actions: [
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: const Text("Close"),
  ),
  ElevatedButton(
    onPressed: () {
      setState(() {
  books.add(
    Book(
  title: titleController.text,
  author: authorController.text,
  genre: genreController.text,
  status: selectedStatus,
  color: [
    const Color(0xFFF2B8C6), // Pastel pink
    const Color(0xFFCDBCEB), // Lavender
    const Color(0xFFB8D8F0), // Baby blue
    const Color(0xFFBFDCC5), // Mint green
    const Color(0xFFF5E3A6), // Butter yellow
  ][books.length % 5],

),
  );
});
       saveBooks();
      
      Navigator.pop(context);
    },
    child: const Text("Save Book"),
  ),
],
    );
  },
);
              },
              icon: const Icon(Icons.add),
              label: const Text("Add a Book"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
  horizontal: 20,
  vertical: 13,
),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget shelfBoard() {
  return Container(
    height: 12,
    decoration: const BoxDecoration(
  color: Color(0xFFFFFFFF),
  border: Border(
    top: BorderSide(
      color: Color(0xFF222222),
      width: 2,
    ),
  ),
      boxShadow: [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 5,
          offset: Offset(0, 3),
        ),
      ],
    ),
  );
}

class CreeperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final vine = Paint()
      ..color = const Color(0xFF536B3A)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leaf = Paint()
      ..color = const Color(0xFF718A4D)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(10, 0)
      ..cubicTo(5, 45, 35, 65, 25, 105)
      ..cubicTo(15, 145, 45, 165, 35, 215)
      ..cubicTo(30, 235, 40, 250, 50, 260);


canvas.drawPath(path, vine);

    final leaves = [
      Offset(12, 35),
      Offset(28, 65),
      Offset(22, 105),
      Offset(38, 140),
      Offset(32, 180),
      Offset(40, 220),
      Offset(50, 245),
    ];

    for (final position in leaves) {
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(-0.5);

      final leafPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(18, -12, 22, 2)
        ..quadraticBezierTo(12, 12, 0, 0);

      canvas.drawPath(leafPath, leaf);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
class Book {
   String title;
   String author;
   String genre;
   String status;
  final Color color;

  Book({
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    required this.color,
  });
  Map<String, dynamic> toJson() {
  return {
    'title': title,
    'author': author,
    'genre': genre,
    'status': status,
    'color': color.toARGB32(),
  };
}
 factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'],
      author: json['author'],
      genre: json['genre'],
      status: json['status'],
      color: Color(json['color']),
    );
  }
}

class CheckerFloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tileSize = 32.0;

    final white = Paint()..color = Colors.white;
    final black = Paint()..color = const Color(0xFF222222);

    for (int row = 0; row * tileSize < size.height; row++) {
      for (int col = 0; col * tileSize < size.width; col++) {
        canvas.drawRect(
          Rect.fromLTWH(
            col * tileSize,
            row * tileSize,
            tileSize,
            tileSize,
          ),
          (row + col).isEven ? white : black,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CheckerFloorPainter oldDelegate) => false;
}

// The jolly roger, drawn in the flag's own 100x66 space.
void _paintJollyRoger(Canvas canvas) {
  final dark = Paint()..color = const Color(0xFF222222);
  final bone = Paint()..color = const Color(0xFFEDE7DA);
  final skull = Paint()..color = const Color(0xFFFDFBF6);
  final hat = Paint()..color = const Color(0xFFFFFFFF);

  // Crossbones behind the skull.
  final boneStroke = Paint()
    ..color = const Color(0xFFEDE7DA)
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(const Offset(32, 29), const Offset(64, 43), boneStroke);
  canvas.drawLine(const Offset(32, 43), const Offset(64, 29), boneStroke);
  for (final knob in const [
    Offset(32, 29),
    Offset(64, 43),
    Offset(32, 43),
    Offset(64, 29),
  ]) {
    canvas.drawCircle(knob, 3.5, bone);
  }

  // Skull with jaw.
  canvas.drawCircle(const Offset(48, 27), 12, skull);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTRB(39, 34, 57, 46),
      const Radius.circular(4),
    ),
    skull,
  );

  // Eyes and grin.
  canvas.drawCircle(const Offset(43, 28.5), 3, dark);
  canvas.drawCircle(const Offset(53, 28.5), 3, dark);
  final grin = Path()
    ..moveTo(40.5, 40.5)
    ..quadraticBezierTo(48, 44, 55.5, 40.5);
  canvas.drawPath(
    grin,
    Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round,
  );

  // Straw hat: white dome, dark band, wide brim.
  canvas.drawCircle(const Offset(48, 12), 12.5, dark);
  canvas.drawCircle(const Offset(48, 12), 11, hat);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTRB(37.5, 12, 58.5, 18.5),
      const Radius.circular(2),
    ),
    dark,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTRB(38.5, 13, 57.5, 17.5),
      const Radius.circular(1.5),
    ),
    dark,
  );
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(48, 22.5), width: 35, height: 8.5),
    dark,
  );
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(48, 22.5), width: 32, height: 6.5),
    hat,
  );
}

// Framed One Piece print hanging on the right wall.
class OnePieceArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // The print is designed in a 94x129 space and scaled to fit.
    canvas.save();
    canvas.scale(size.width / 94, size.height / 129);

    // "WANTED" headline.
    final title = TextPainter(
      text: const TextSpan(
        text: 'WANTED',
        style: TextStyle(
          color: Color(0xFFFDFBF6),
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    title.paint(canvas, Offset((94 - title.width) / 2, 11));

    // Jolly roger, reusing the flag's 100x66 artwork space.
    canvas.save();
    canvas.translate(47, 84);
    canvas.scale(1.7);
    canvas.translate(-48, -23.5);
    _paintJollyRoger(canvas);
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OnePieceArtPainter oldDelegate) => false;
}

