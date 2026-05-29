import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const BridgeCallAI());
}

class BridgeCallAI extends StatelessWidget {
  const BridgeCallAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "BridgeCall AI",
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String fromLanguage = "English";
  String toLanguage = "Pashto";

  final List<String> languages = [
    "English",
    "Pashto",
    "Arabic",
    "Dari",
    "Spanish",
    "French",
  ];

  Widget languageDropdown({
    required String label,
    required String value,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Text("$label:", style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 18),
          Expanded(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF151515),
              underline: const SizedBox(),
              items: languages.map((language) {
                return DropdownMenuItem(value: language, child: Text(language));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: const Text("BridgeCall AI"),
        centerTitle: true,
        backgroundColor: const Color(0xFF050505),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.record_voice_over, size: 80),
            const SizedBox(height: 25),
            const Text(
              "AI Live Translation",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Speak naturally. BridgeCall AI translates your voice into another language.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            languageDropdown(
              label: "From",
              value: fromLanguage,
              onChanged: (value) {
                setState(() => fromLanguage = value!);
              },
            ),
            const SizedBox(height: 18),
            languageDropdown(
              label: "To",
              value: toLanguage,
              onChanged: (value) {
                setState(() => toLanguage = value!);
              },
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.mic),
                label: const Text(
                  "Start Conversation",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConversationPage(
                        fromLanguage: fromLanguage,
                        toLanguage: toLanguage,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageItem {
  final String original;
  final String translated;

  MessageItem({
    required this.original,
    required this.translated,
  });
}

class ConversationPage extends StatefulWidget {
  final String fromLanguage;
  final String toLanguage;

  const ConversationPage({
    super.key,
    required this.fromLanguage,
    required this.toLanguage,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  late stt.SpeechToText speech;
  late FlutterTts flutterTts;

  bool isListening = false;
  String spokenText = "Your spoken words will appear here.";
  String translatedText = "Translated text will appear here.";

  final List<MessageItem> history = [];

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
    flutterTts = FlutterTts();
  }

  Future<String> translateText(String text) async {
    try {
      final response = await http.post(
        Uri.parse("http://localhost:3000/translate"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": text,
          "from": widget.fromLanguage,
          "to": widget.toLanguage,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["translated"] ?? "No translation returned.";
      }

      return "Translation failed. Status code: ${response.statusCode}";
    } catch (error) {
      return "Could not connect to backend. Make sure server.js is running.";
    }
  }

  Future<void> speakTranslation() async {
    await flutterTts.setSpeechRate(0.45);

    if (widget.toLanguage == "Pashto") {
      await flutterTts.setLanguage("ps-AF");
    } else if (widget.toLanguage == "Arabic") {
      await flutterTts.setLanguage("ar-SA");
    } else if (widget.toLanguage == "Spanish") {
      await flutterTts.setLanguage("es-ES");
    } else if (widget.toLanguage == "French") {
      await flutterTts.setLanguage("fr-FR");
    } else {
      await flutterTts.setLanguage("en-US");
    }

    await flutterTts.speak(translatedText);
  }

  Future<void> listen() async {
    if (!isListening) {
      final bool available = await speech.initialize();

      if (!available) {
        setState(() {
          spokenText = "Speech recognition is not available.";
        });
        return;
      }

      setState(() {
        isListening = true;
        spokenText = "Listening...";
        translatedText = "Waiting for translation...";
      });

      speech.listen(
        onResult: (result) async {
          final String words = result.recognizedWords;

          setState(() {
            spokenText = words;
          });

          if (words.trim().isNotEmpty && result.finalResult) {
            final String translation = await translateText(words);

            if (mounted) {
              setState(() {
                translatedText = translation;
                history.add(
                  MessageItem(
                    original: words,
                    translated: translation,
                  ),
                );
              });

              await speakTranslation();
            }
          }
        },
      );
    } else {
      await speech.stop();
      setState(() {
        isListening = false;
      });
    }
  }

  void clearText() {
    setState(() {
      spokenText = "Your spoken words will appear here.";
      translatedText = "Translated text will appear here.";
      history.clear();
      isListening = false;
    });
  }

  void swapLanguages() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationPage(
          fromLanguage: widget.toLanguage,
          toLanguage: widget.fromLanguage,
        ),
      ),
    );
  }

  Widget translationBox({
    required String title,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget historyBubble(MessageItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(item.original),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 18, left: 40),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.deepPurpleAccent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(item.translated),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: Text("${widget.fromLanguage} → ${widget.toLanguage}"),
        centerTitle: true,
        backgroundColor: const Color(0xFF050505),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            translationBox(title: "Original Speech", text: spokenText),
            const SizedBox(height: 18),
            translationBox(title: "AI Translation", text: translatedText),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: swapLanguages,
              icon: const Icon(Icons.swap_horiz),
              label: const Text("Swap Languages"),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: history.isEmpty
                  ? const Center(
                      child: Text(
                        "Conversation history will appear here.",
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        return historyBubble(history[index]);
                      },
                    ),
            ),
            FloatingActionButton(
              backgroundColor:
                  isListening ? Colors.redAccent : Colors.deepPurpleAccent,
              onPressed: listen,
              child: Icon(
                isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: speakTranslation,
              icon: const Icon(Icons.volume_up),
              label: const Text("Speak Translation"),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: clearText,
              icon: const Icon(Icons.clear),
              label: const Text("Clear"),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
