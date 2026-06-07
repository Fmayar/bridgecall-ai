import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF050505),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String errorMessage = "";

  Future<void> login() async {
    setState(() {
      loading = true;
      errorMessage = "";
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? "Login failed.";
      });
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      setState(() {
        errorMessage = "Enter your email first.";
      });
      return;
    }

    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: emailController.text.trim(),
    );

    setState(() {
      errorMessage = "Password reset email sent.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050509),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.translate,
                size: 80,
                color: Colors.deepPurpleAccent,
              ),
              const SizedBox(height: 20),
              const Text(
                "BridgeCall AI",
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Login to continue",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 35),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : login,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text("Login"),
                ),
              ),
              TextButton(
                onPressed: resetPassword,
                child: const Text("Forgot Password?"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpPage()),
                  );
                },
                child: const Text("Create New Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String errorMessage = "";

  Future<void> signUp() async {
    setState(() {
      loading = true;
      errorMessage = "";
    });

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "email": user.email,
          "name": "",
          "accountType": "free",
          "preferredFromLanguage": "English",
          "preferredToLanguage": "Pashto",
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? "Sign up failed.";
      });
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050509),
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: const Color(0xFF050509),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.redAccent),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : signUp,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Sign Up"),
              ),
            ),
          ],
        ),
      ),
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

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Widget languageSelector({
    required String title,
    required String value,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF17171C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: Colors.white60)),
          const SizedBox(width: 18),
          Expanded(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF17171C),
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white, fontSize: 16),
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
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "User";

    return Scaffold(
      backgroundColor: const Color(0xFF050509),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050509),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "BridgeCall AI",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6D5DF6), Color(0xFF9B5CFF)],
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.record_voice_over, size: 70),
                  const SizedBox(height: 18),
                  const Text(
                    "AI Live Interpreter",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Translate speech instantly between languages using AI.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Logged in: $userEmail",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            languageSelector(
              title: "From",
              value: fromLanguage,
              onChanged: (value) => setState(() => fromLanguage = value!),
            ),
            const SizedBox(height: 16),
            languageSelector(
              title: "To",
              value: toLanguage,
              onChanged: (value) => setState(() => toLanguage = value!),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        final temp = fromLanguage;
                        fromLanguage = toLanguage;
                        toLanguage = temp;
                      });
                    },
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text("Swap"),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TranslationHistoryPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text("History"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.mic),
                label: const Text(
                  "Start Live Conversation",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 22),
            const Text(
              "BridgeCall AI helps users communicate across languages in real time.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
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

  MessageItem({required this.original, required this.translated});
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

  Future<void> saveTranslationHistory({
    required String original,
    required String translated,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("translations")
        .add({
      "original": original,
      "translated": translated,
      "fromLanguage": widget.fromLanguage,
      "toLanguage": widget.toLanguage,
      "createdAt": FieldValue.serverTimestamp(),
    });
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
                history.add(MessageItem(original: words, translated: translation));
              });

              await saveTranslationHistory(
                original: words,
                translated: translation,
              );

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

  Widget translationBox({required String title, required String text}) {
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

class TranslationHistoryPage extends StatelessWidget {
  const TranslationHistoryPage({super.key});

  Future<void> deleteTranslation(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("translations")
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF050505),
        body: Center(child: Text("Please log in to view history.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: const Text("Translation History"),
        centerTitle: true,
        backgroundColor: const Color(0xFF050505),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("translations")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No translation history yet.",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          final translations = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: translations.length,
            itemBuilder: (context, index) {
              final doc = translations[index];
              final data = doc.data() as Map<String, dynamic>;

              final original = data["original"] ?? "";
              final translated = data["translated"] ?? "";
              final fromLanguage = data["fromLanguage"] ?? "";
              final toLanguage = data["toLanguage"] ?? "";

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.translate,
                          color: Colors.deepPurpleAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "$fromLanguage → $toLanguage",
                            style: const TextStyle(
                              color: Colors.deepPurpleAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => deleteTranslation(doc.id),
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Original",
                      style: TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 6),
                    Text(original),
                    const SizedBox(height: 12),
                    const Text(
                      "Translation",
                      style: TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      translated,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
