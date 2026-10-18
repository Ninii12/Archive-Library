import 'dart:convert';
import 'dart:math' as math;
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: const ArchiveScrollBehavior(),
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF3A3733),
          onPrimary: Colors.white,
          secondary: Color(0xFF6E6A64),
          onSecondary: Colors.white,
          surface: Color(0xFFFBF9F4),
          onSurface: Color(0xFF3A3733),
        ),
        scaffoldBackgroundColor: const Color(0xFFFBF9F4),
      ),
      home: const ArchiveRoom(),
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
  List<String> vinylFavorites = List.filled(12, '');
  @override
void initState() {
  super.initState();
  loadBooks();
}

Future<void> loadBooks() async {
  final prefs = await SharedPreferences.getInstance();
  final savedBooks = prefs.getString('saved_books');
  if (savedBooks != null) {
    try {
      final List<dynamic> decodedBooks = jsonDecode(savedBooks);
      final loaded = <Book>[];
      for (final item in decodedBooks) {
        try {
          loaded.add(Book.fromJson(item as Map<String, dynamic>));
        } catch (_) {
          // Skip one unreadable record instead of losing the whole shelf.
        }
      }
      setState(() {
        books = loaded;
      });
    } catch (_) {
      // Corrupt storage: keep the empty shelf instead of crashing.
    }
  }

  final savedVinyls = prefs.getString('saved_vinyls');
  if (savedVinyls != null) {
    try {
      final List<dynamic> decodedVinyls = jsonDecode(savedVinyls);
      setState(() {
        vinylFavorites = [
          for (var i = 0; i < 12; i++)
            i < decodedVinyls.length && decodedVinyls[i] is String
                ? decodedVinyls[i] as String
                : '',
        ];
      });
    } catch (_) {
      // Keep the empty record wall instead of crashing.
    }
  }
}
Future<void> saveBooks() async {
  final prefs = await SharedPreferences.getInstance();

  final encodedBooks = jsonEncode(
    books.map((book) => book.toJson()).toList(),
  );

  await prefs.setString('saved_books', encodedBooks);
}

Future<void> saveVinyls() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('saved_vinyls', jsonEncode(vinylFavorites));
}

// Tap an empty slot to add a favorite; tap a filled one for options.
void handleVinylTap(int index) {
  final title = vinylFavorites[index];

  if (title.isEmpty) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Add Favorite"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: "Anime or movie"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  vinylFavorites[index] = name;
                });
                saveVinyls();
              }
              Navigator.pop(dialogContext);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: const Text("Favorite anime or movie"),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              vinylFavorites[index] = "";
            });
            saveVinyls();
            Navigator.pop(dialogContext);
          },
          child: const Text("Delete"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text("Close"),
        ),
      ],
    ),
  );
}

// One slot of the vinyl wall: a record, or a dashed empty spot to fill.
Widget vinylSlot(int index) {
  final title = vinylFavorites[index];
  return GestureDetector(
    onTap: () => handleVinylTap(index),
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      width: 88,
      height: 90,
      child: Column(
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: CustomPaint(
              painter: VinylPainter(
                labelColor: const [
                  Color(0xFFF2B8C6),
                  Color(0xFFCDBCEB),
                  Color(0xFFB8D8F0),
                  Color(0xFFBFDCC5),
                  Color(0xFFF5E3A6),
                ][index % 5],
                variant: index % 3,
                empty: title.isEmpty,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3A3733),
            ),
          ),
        ],
      ),
    ),
  );
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
          color: const Color(0xFF3A3733),
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
      width: 23 + (position % 4) * 3,
      height: 58 + (position % 4) * 3,
      margin: const EdgeInsets.only(right: 4),
      child: CustomPaint(
        painter: BookSpinePainter(
          variant: (book.title.length + position) % 3,
          fill: book.color,
        ),
        child: Center(
          child: RotatedBox(
            quarterTurns: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF3A3733),
                  fontSize: 9,
                ),
              ),
            ),
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
                  Color(0xFFFEFDFA),
                  Color(0xFFF4F1EB),
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
  Color(0xFFFEFDFA),
  Color(0xFFF2EFE8),
  Color(0xFFFEFDFA),
],

                ),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
  color: const Color(0xFF3A3733),
  width: 3,
),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x59807A72),
                    blurRadius: 24,
                    offset: Offset(10, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
  color: const Color(0xFF8A857E),
  width: 1.5,
),
                  color: const Color(0xFFFDFCF8),
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
                        color: const Color(0xFF3A3733),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
  BoxShadow(
    color: Color(0xFFDCD7CF),
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
                        color: const Color(0xFF3A3733),
                        width: 3,
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
        color: const Color(0xFFDCD7CF),
      ),
      Container(
        width: 7,
        height: 55,
        color: const Color(0xFF3A3733),
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
        color: const Color(0xFF3A3733),
      ),
      Container(
        width: 2,
        height: 55,
        color: const Color(0xFFDCD7CF),
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
        color: const Color(0xFFDCD7CF),
      ),
      Container(
        width: 7,
        height: 48,
        color: const Color(0xFF3A3733),
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
        color: const Color(0xFF3A3733),
      ),
      Container(
        width: 2,
        height: 48,
        color: const Color(0xFFDCD7CF),
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
              color: const Color(0xFFE9E5DC),
              border: Border.all(
                color: const Color(0xFF3A3733),
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
              color: const Color(0xFFF2EFE8),
              border: Border.all(
                color: const Color(0xFF3A3733),
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
              color: const Color(0xFFE9E5DC),
              border: Border.all(
                color: const Color(0xFF3A3733),
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
          color: const Color(0xFFE8E3D9),
          border: Border.all(
            color: const Color(0xFF3A3733),
            width: 2,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(8),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFDCD7CF),
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
  color: const Color(0xFF3A3733),
  width: 3,
),
boxShadow: [
  BoxShadow(
    color: const Color(0xFFDCD7CF),
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
      color: const Color(0xFF3A3733),
      width: 3,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFFDCD7CF),
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
      child: SizedBox(
        width: 45,
        height: 12,
        child: CustomPaint(
          painter: BookSpinePainter(
            variant: (entry.value.value.title.length + entry.key) % 3,
            fill: entry.value.value.color,
            lying: true,
          ),
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
      saveBooks();
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
                child: SizedBox(
                  width: 65,
                  height: 26,
                  child: CustomPaint(
                    painter: BookSpinePainter(
                      variant: (entry.value.value.title.length + entry.key) % 3,
                      fill: entry.value.value.color,
                      lying: true,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: Text(
                          entry.value.value.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3A3733),
                          ),
                        ),
                      ),
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
                  color: const Color(0xFF3A3733),
                  width: 3,
                ),
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E3D9),
                    border: Border.all(
                      color: const Color(0xFF3A3733),
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
                          color: const Color(0xFF3A3733),
                        ),
                      ),
                      Positioned(
                        left: 5,
                        right: 5,
                        bottom: 5,
                        child: Container(
                          height: 1,
                          color: const Color(0xFF3A3733),
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
                border: Border.all(color: const Color(0xFF3A3733), width: 3),
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

          // Vinyl wall: favorite anime and movies, 4 across and 3 down
          Positioned(
            left: 620,
            top: 145,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFCF8),
                border: Border.all(
                  color: const Color(0xFF3A3733),
                  width: 3,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFDCD7CF),
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "FAVORITES",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Color(0xFF3A3733),
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var row = 0; row < 3; row++)
                    Row(
                      children: [
                        for (var col = 0; col < 4; col++)
                          vinylSlot(row * 4 + col),
                      ],
                    ),
                ],
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
              color: const Color(0xFF3A3733),
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
                color: const Color(0xFF3A3733),
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
                  color: const Color(0xFF3A3733),
                  width: 3,
                ),
              ),
              child: CustomPaint(
                painter: CurtainPainter(),
              ),
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
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF3A3733),
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
      backgroundColor: const Color(0xFFF7F5F0),
     title: const Text(
  "Add a new book",
  style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Color(0xFF3A3733),
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
  fillColor: const Color(0xFFF3F0EA),
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
              fillColor: const Color(0xFFF3F0EA),
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
  fillColor: const Color(0xFFF3F0EA),
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
              fillColor: const Color(0xFFF3F0EA),
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
    onPressed: () async {
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
      await saveBooks();
      if (context.mounted) {
        Navigator.pop(context);
      }
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
                backgroundColor: const Color(0xFFFBF9F4),
                foregroundColor: const Color(0xFF3A3733),
                side: const BorderSide(
                  color: Color(0xFF3A3733),
                  width: 2,
                ),
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
      color: Color(0xFF3A3733),
      width: 2,
    ),
  ),
      boxShadow: [
        BoxShadow(
          color: Color(0x66807A72),
          blurRadius: 5,
          offset: Offset(0, 3),
        ),
      ],
    ),
  );
}

// One book spine, drawn like a small pencil study: capped ends,
// head and tail bands, raised bands or a title plate, edge shading.
class BookSpinePainter extends CustomPainter {
  BookSpinePainter({
    required this.variant,
    required this.fill,
    this.lying = false,
  });

  final int variant;
  final Color fill;
  final bool lying;

  @override
  void paint(Canvas canvas, Size size) {
    if (lying) {
      // A quarter turn lays the standing spine flat.
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(math.pi / 2);
      canvas.translate(-size.height / 2, -size.width / 2);
      _paintSpine(canvas, Size(size.height, size.width));
      canvas.restore();
      return;
    }
    _paintSpine(canvas, size);
  }

  void _paintSpine(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final ink = Paint()
      ..color = const Color(0xFF3A3733)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final inkSoft = Paint()
      ..color = const Color(0xFF8A857E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.6, 0.6, w - 1.2, h - 1.2),
      const Radius.circular(2.5),
    );

    // Body with a hint of roundness along the edges.
    canvas.drawRRect(body, Paint()..color = fill);
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawLine(
      const Offset(2.4, 0),
      Offset(2.4, h),
      Paint()
        ..color = const Color(0x335A554E)
        ..strokeWidth = 1.4,
    );
    canvas.drawLine(
      Offset(w - 2.2, 0),
      Offset(w - 2.2, h),
      Paint()
        ..color = const Color(0x405A554E)
        ..strokeWidth = 1.6,
    );
    canvas.restore();

    // Head and tail bands.
    final band = Paint()..color = const Color(0xFF4A463F);
    canvas.drawRect(Rect.fromLTWH(1.4, 1.6, w - 2.8, 1.8), band);
    canvas.drawRect(Rect.fromLTWH(1.4, h - 3.4, w - 2.8, 1.8), band);
    canvas.drawLine(Offset(1.6, 4.2), Offset(w - 1.6, 4.2), inkSoft);
    canvas.drawLine(Offset(1.6, h - 4.6), Offset(w - 1.6, h - 4.6), inkSoft);

    // Raised bands or a title plate, by variant.
    if (variant == 0) {
      for (final f in const [0.20, 0.80]) {
        canvas.drawLine(Offset(1.6, h * f), Offset(w - 1.6, h * f), inkSoft);
        canvas.drawLine(
          Offset(1.6, h * f + 1.4),
          Offset(w - 1.6, h * f + 1.4),
          inkSoft,
        );
      }
    } else if (variant == 1) {
      for (final f in const [0.14, 0.24, 0.34, 0.76]) {
        canvas.drawLine(Offset(1.6, h * f), Offset(w - 1.6, h * f), inkSoft);
      }
    } else {
      final plate = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.2, w * 0.64, h * 0.6),
        const Radius.circular(2),
      );
      canvas.drawRRect(plate, Paint()..color = const Color(0x1A5A554E));
      canvas.drawRRect(plate, inkSoft);
    }

    // Sketchy double outline.
    canvas.drawRRect(body, ink);
    canvas.drawRRect(
      body.inflate(0.5).shift(const Offset(0.4, 0.3)),
      Paint()
        ..color = const Color(0x668A857E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
  }

  @override
  bool shouldRepaint(covariant BookSpinePainter oldDelegate) =>
      oldDelegate.variant != variant ||
      oldDelegate.fill != fill ||
      oldDelegate.lying != lying;
}

// Vinyl on the favorites wall, or an empty slot waiting to be filled.
class VinylPainter extends CustomPainter {
  VinylPainter({
    required this.labelColor,
    required this.variant,
    required this.empty,
  });

  final Color labelColor;
  final int variant;
  final bool empty;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 1;

    if (empty) {
      // Dashed outline and a plus: an empty spot inviting a favorite.
      final dash = Paint()
        ..color = const Color(0x668A857E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;
      for (var i = 0; i < 12; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius * 0.82),
          i * math.pi / 6,
          math.pi / 12,
          false,
          dash,
        );
      }
      final plus = Paint()
        ..color = const Color(0xFF8A857E)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center - Offset(radius * 0.22, 0),
        center + Offset(radius * 0.22, 0),
        plus,
      );
      canvas.drawLine(
        center - Offset(0, radius * 0.22),
        center + Offset(0, radius * 0.22),
        plus,
      );
      return;
    }

    // The record itself.
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF36332F));

    // Groove rings, by variant.
    final groove = Paint()
      ..color = const Color(0x479A948C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    const ringSets = [
      [0.96, 0.89, 0.82, 0.75, 0.68],
      [0.96, 0.91, 0.86, 0.56, 0.49],
      [0.94, 0.72, 0.55],
    ];
    for (final f in ringSets[variant % ringSets.length]) {
      canvas.drawCircle(center, radius * f, groove);
    }

    // Glossy glints over the record.
    final glint = Paint()
      ..color = const Color(0x40FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.88),
      -2.4,
      0.9,
      false,
      glint,
    );
    glint.color = const Color(0x26FFFFFF);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.55),
      -2.2,
      0.6,
      false,
      glint,
    );

    // Center label with a spindle hole.
    canvas.drawCircle(center, radius * 0.34, Paint()..color = labelColor);
    canvas.drawCircle(
      center,
      radius * 0.34,
      Paint()
        ..color = const Color(0xFF8A857E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    canvas.drawCircle(center, 1.7, Paint()..color = const Color(0xFFFDFCF8));
    canvas.drawCircle(
      center,
      1.7,
      Paint()
        ..color = const Color(0x663A3733)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    // Sketchy outline, with a loose second stroke.
    final ink = Paint()
      ..color = const Color(0xFF3A3733)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius, ink);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 0.6),
      -0.9,
      1.6,
      false,
      Paint()
        ..color = const Color(0x668A857E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
  }

  @override
  bool shouldRepaint(covariant VinylPainter oldDelegate) =>
      oldDelegate.labelColor != labelColor ||
      oldDelegate.variant != variant ||
      oldDelegate.empty != empty;
}

// Curtain folds, drawn like loose pencil strokes.
class CurtainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fold = Paint()
      ..color = const Color(0xFF3A3733)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final foldSoft = Paint()
      ..color = const Color(0xFF9A948C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    final shade = Paint()
      ..color = const Color(0x14807A72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    const folds = 5;

    for (var i = 1; i <= folds; i++) {
      final x = i * w / (folds + 1);
      final sway = i.isEven ? 2.6 : -2.2;
      final foldPath = Path()
        ..moveTo(x + sway, 1)
        ..quadraticBezierTo(x - sway, h * 0.5, x + sway, h - 1);
      // Soft shading beside each fold.
      canvas.drawPath(
        Path()
          ..moveTo(x + sway + 4, 1)
          ..quadraticBezierTo(x - sway + 4, h * 0.5, x + sway + 4, h - 1),
        shade,
      );
      canvas.drawPath(foldPath, fold);
      canvas.drawPath(foldPath.shift(const Offset(1.4, 0.7)), foldSoft);
    }
  }

  @override
  bool shouldRepaint(covariant CurtainPainter oldDelegate) => false;
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
      title: json['title'] ?? 'Untitled',
      author: json['author'] ?? 'Unknown',
      genre: json['genre'] ?? '',
      status: json['status'] ?? 'Want to read',
      color: Color((json['color'] as int?) ?? 0xFFEDE9E1),
    );
  }
}

class CheckerFloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tileSize = 32.0;

    final paper = Paint()..color = const Color(0xFFFBF9F4);
    final dark = Paint()..color = const Color(0xFF3A3733);

    for (var row = 0; row * tileSize < size.height; row++) {
      for (var col = 0; col * tileSize < size.width; col++) {
        final tile = Rect.fromLTWH(
          col * tileSize,
          row * tileSize,
          tileSize,
          tileSize,
        );
        canvas.drawRect(tile, (row + col).isOdd ? dark : paper);
      }
    }

    // Sketchy front edge where the floor meets the wall.
    final edge = Paint()
      ..color = const Color(0xFF3A3733)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final edgeSoft = Paint()
      ..color = const Color(0xFF9A948C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawLine(const Offset(0, 1.2), Offset(size.width, 1.2), edge);
    canvas.drawLine(const Offset(0, 3.6), Offset(size.width, 3.0), edgeSoft);
  }

  @override
  bool shouldRepaint(covariant CheckerFloorPainter oldDelegate) => false;
}

// The jolly roger, drawn in the flag's own 100x66 space.
void _paintJollyRoger(Canvas canvas) {
  final dark = Paint()..color = const Color(0xFF3A3733);
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
      ..color = const Color(0xFF3A3733)
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

