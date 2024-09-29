import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:html/parser.dart' as html;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lyrics App',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String lyrics = "Loading..."; // Inicjalizacja tekstu piosenki
  String songQuery = ""; // Zmienna do przechowywania tytułu piosenki
  List<String> bannedWords = ["chuj", "dupa"]; // Lista słów do zablokowania
  List<String> warningWords = ["zajebiście", "fiut"]; // Lista słów ostrzegawczych

  @override
  void initState() {
    super.initState();
    getSongLyrics("Shape of You"); // Przykładowe zapytanie
  }

  Future<void> getSongLyrics(String query) async {
    final String accessToken = '0yAD_663dCB-jY25V8TBRzAPK18gE5Y2SeCdQUIHvlPoIpCwp87-M2u0SYu4TboK';
    final String searchUrl = 'https://api.genius.com/search?q=$query';

    var response = await http.get(
      Uri.parse(searchUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      var hits = jsonResponse['response']['hits'];

      if (hits.isNotEmpty) {
        var songPath = hits[0]['result']['path'];
        await getLyrics(songPath);
      } else {
        setState(() {
          lyrics = 'No songs found.';
        });
      }
    } else {
      setState(() {
        lyrics = 'Failed to fetch song: ${response.statusCode}';
      });
    }
  }

  Future<void> getLyrics(String songPath) async {
    final String lyricsUrl = 'https://genius.com$songPath';

    var response = await http.get(Uri.parse(lyricsUrl));

    if (response.statusCode == 200) {
      var document = html.parse(response.body);
      var lyricsElements = document.querySelectorAll('.Lyrics__Container-sc-1ynbvzw-1');

      if (lyricsElements.isNotEmpty) {
        setState(() {
          String fullLyrics = '';
          for (var element in lyricsElements) {
            fullLyrics += element.text + '\n'; // Dodaj nową linię po każdym elemencie
          }
          lyrics = fullLyrics.trim(); // Zapisz tekst do zmiennej stanu
        });
      } else {
        setState(() {
          lyrics = 'Lyrics not found on the page.';
        });
      }
    } else {
      setState(() {
        lyrics = 'Failed to fetch lyrics: ${response.statusCode}';
      });
    }
  }

  void searchLyrics() {
    setState(() {
      lyrics = "Loading..."; // Resetuj tekst piosenki przed nowym wyszukiwaniem
    });
    getSongLyrics(songQuery); // Wywołaj wyszukiwanie
  }

  // Funkcja do wyróżniania słów zabronionych i ostrzegawczych
  List<TextSpan> highlightWords(String text) {
    List<TextSpan> spans = [];
    List<String> lines = text.split('\n'); // Dziel tekst na linie

    for (String line in lines) {
      List<String> words = line.split(' ');

      for (String word in words) {
        if (bannedWords.contains(word.toLowerCase())) {
          spans.add(TextSpan(
            text: '$word ',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold), // Czerwony dla banned words
          ));
        } else if (warningWords.contains(word.toLowerCase())) {
          spans.add(TextSpan(
            text: '$word ',
            style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold), // Żółty dla warning words
          ));
        } else {
          spans.add(TextSpan(text: '$word ')); // Domyślny styl
        }
      }
      spans.add(TextSpan(text: '\n')); // Dodaj nową linię po każdej linii tekstu
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Song Lyrics'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                onChanged: (value) {
                  setState(() {
                    songQuery = value; // Aktualizuj tytuł piosenki
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Enter song title',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0), // Odstęp
              ElevatedButton(
                onPressed: searchLyrics, // Wywołaj funkcję wyszukiwania
                child: Text('Search'),
              ),
              SizedBox(height: 16.0), // Odstęp
              Expanded(
                child: SingleChildScrollView(
                  child: RichText(
                    text: TextSpan(
                      children: highlightWords(lyrics), // Użyj funkcji do wyróżniania
                      style: TextStyle(fontSize: 18, color: Colors.black), // Styl domyślny
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
