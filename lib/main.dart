import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart'; // Import Gemini package
import 'package:hive_flutter/hive_flutter.dart';
import 'chat_message_adapter.dart';
import 'home_page.dart';

Future<void> main() async {
  // Load environment variables from the .env file
  await dotenv.load(fileName: ".env");

  // Initialize Gemini with the API key from the .env file
  Gemini.init(apiKey: dotenv.env['GEMINI_API_KEY']!);

  // Initialize Hive
  await Hive.initFlutter();

  // Register the adapter
  Hive.registerAdapter(HiveChatMessageAdapter());

  // Open the boxes
  await Hive.openBox('chat_history');
  await Hive.openBox('chat_ids');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}
