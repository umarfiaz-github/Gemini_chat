import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:hive/hive.dart';

import 'chat_message_adapter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  final List<ChatMessage> _messages = [];
  XFile? _attachedImage;
  final TextEditingController _textController = TextEditingController();

  late Gemini _gemini;
  int _selectedIndex = 0;
  String _currentChatId = '';

  @override
  void initState() {
    super.initState();
    _gemini = Gemini.instance;
    _startNewChat(); // Start for new chatting
  }

  void _loadMessages() async {
    var box = await Hive.openBox('chat_history');
    List<dynamic> storedMessages = box.get(_currentChatId, defaultValue: []);
    setState(() {
      _messages.addAll(
        storedMessages.cast<HiveChatMessage>().map((item) => item.toChatMessage()).toList(),
      );
    });
  }

  void _saveMessages() async {
    var box = await Hive.openBox('chat_history');
    List<HiveChatMessage> hiveMessages = _messages.map((msg) => HiveChatMessage.fromChatMessage(msg)).toList();
    box.put(_currentChatId, hiveMessages);

    // Saving my chat ID separately
    var idsBox = await Hive.openBox('chat_ids');
    if (!idsBox.containsKey(_currentChatId)) {
      idsBox.put(_currentChatId, true);
    }
  }

  void _startNewChat() {
    setState(() {
      _currentChatId = DateTime.now().toIso8601String();
      _messages.clear();
    });
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _attachedImage == null) return;

    final ChatMessage userMessage = ChatMessage(
      user: ChatUser(id: '1'),
      createdAt: DateTime.now(),
      text: text.isEmpty ? 'Image attached' : text,
      customProperties: _attachedImage != null
          ? {
        'imagePath': _attachedImage!.path,
        'text': text,
      }
          : null,
    );

    setState(() {
      _messages.add(userMessage);
    });

    _saveMessages(); // Save message after sending

    if (_attachedImage != null) {
      final file = File(_attachedImage!.path);
      final responseText = await _sendImageToAPI(file, text);
      _addResponseMessage(responseText);
      _attachedImage = null;
    } else if (text.isNotEmpty) {
      final responseText = await _sendTextToAPI(text);
      _addResponseMessage(responseText);
    }

    _textController.clear();
  }

  Future<String> _sendImageToAPI(File image, String text) async {
    try {
      final response = await _gemini.textAndImage(
        text: text,
        images: [image.readAsBytesSync()],
      );
      return response?.content?.parts?.last.text ?? 'No response';
    } catch (error) {
      log('Error during image processing: $error');
      return 'Error: $error';
    }
  }

  Future<String> _sendTextToAPI(String text) async {
    try {
      final response = await _gemini.text(text);
      return response?.content?.parts?.last.text ?? 'No response';
    } catch (error) {
      return 'Error: $error';
    }
  }

  void _attachImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _attachedImage = image;
      });
    }
  }

  void _addResponseMessage(String responseText) {
    final ChatUser botUser = ChatUser(
      id: '2',
      firstName: 'Gemini',
      profileImage: "https://seeklogo.com/images/G/google-gemini-logo-A5787B2669-seeklogo.com.png",
    );

    final ChatMessage responseMessage = ChatMessage(
      user: botUser,
      createdAt: DateTime.now(),
      text: responseText,
    );

    setState(() {
      _messages.add(responseMessage);
    });

    _saveMessages(); // Save the response message
  }

  void _loadChatFromHistory(String chatId) async {
    setState(() {
      _currentChatId = chatId;
      _messages.clear(); // Clear current messages before loading new ones
    });

    var box = await Hive.openBox('chat_history');
    List<dynamic>? storedMessages = box.get(_currentChatId);

    if (storedMessages != null && storedMessages.isNotEmpty) {
      setState(() {
        _messages.addAll(
          storedMessages.cast<HiveChatMessage>().map((item) => item.toChatMessage()).toList(),
        );
      });
    }
  }

  Widget _buildChatMessage(ChatMessage message) {
    bool isUserMessage = message.user.id == '1';
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUserMessage) ...[
              CircleAvatar(
                backgroundImage: NetworkImage(message.user.profileImage ?? ''),
                radius: 20,
              ),
              const SizedBox(width: 8.0),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: isUserMessage ? Colors.blue : Colors.grey[300],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                    bottomLeft: isUserMessage ? Radius.circular(16.0) : Radius.zero,
                    bottomRight: isUserMessage ? Radius.zero : Radius.circular(16.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (message.customProperties != null &&
                        message.customProperties!['imagePath'] != null) ...[
                      Image.file(
                        File(message.customProperties!['imagePath']),
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                      if (message.customProperties!['text'] != null &&
                          message.customProperties!['text'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            message.customProperties!['text'],
                            style: TextStyle(
                              color: isUserMessage ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                    ] else ...[
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isUserMessage ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (isUserMessage) const SizedBox(width: 8.0),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPage() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: false,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              return _buildChatMessage(_messages[index]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.photo),
                onPressed: _attachImage,
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Enter a prompt...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerItem(String chatId) {
    var box = Hive.box('chat_history');
    List<dynamic> storedMessages = box.get(chatId, defaultValue: []);
    List<HiveChatMessage> messages = storedMessages.cast<HiveChatMessage>();

    String previewText = messages.isNotEmpty ? messages.first.text : 'No messages';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ListTile(
          title: Text(
            previewText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            _loadChatFromHistory(chatId);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: FutureBuilder(
        future: Hive.openBox('chat_ids'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            var box = Hive.box('chat_ids');
            List<String> chatIds = box.keys.cast<String>().toList();

            return ListView.builder(
              itemCount: chatIds.length,
              itemBuilder: (context, index) {
                return _buildDrawerItem(chatIds[index]);
              },
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gemini Chat'),
        actions:[
          IconButton(
              icon: Icon(Icons.add),
              onPressed: _startNewChat,
          )
        ]
      ),
      drawer: _buildDrawer(),
      body: _buildChatPage(),
    );
  }
}
