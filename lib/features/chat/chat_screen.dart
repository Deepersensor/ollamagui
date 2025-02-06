import 'package:flutter/material.dart';
import '../../core/models/message.dart';
import '../../shared/widgets/responsive_layout.dart';
import '../../core/services/ollama_service.dart';
import '../../core/models/ollama_message.dart';
import '../../shared/widgets/error_dialog.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final OllamaService _ollamaService = OllamaService();
  bool _isLoading = false;
  String _selectedModel = 'llama3.2'; // Default model
  String _selectedEndpoint = 'http://localhost:11434'; // Default endpoint
  final TextEditingController _endpointController =
      TextEditingController(text: 'http://localhost:11434');

  void _addMessage(String text, bool isUserMessage) {
    setState(() {
      _messages.add(Message(text: text, isUserMessage: isUserMessage));
    });
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              return _buildChatMessage(_messages[index]);
            },
          ),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildChatMessage(Message message) {
    return Align(
      alignment:
          message.isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: message.isUserMessage ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(message.text),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (text) {
                _sendMessage(text);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              _sendMessage(_textController.text);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.isNotEmpty) {
      _addMessage(text, true);
      _textController.clear();
      setState(() {
        _isLoading = true;
      });

      try {
        // Convert local messages to OllamaMessage
        List<OllamaMessage> ollamaMessages = _messages.map((msg) {
          return OllamaMessage(
            role: msg.isUserMessage ? 'user' : 'assistant',
            content: msg.text,
          );
        }).toList();

        final response = await _ollamaService.generateResponse(
          ollamaMessages,
          _selectedModel,
          endpoint: _selectedEndpoint,
        );
        _addMessage(response, false);
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(message: e.toString()),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSettingsPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Select Model:'),
          DropdownButton<String>(
            value: _selectedModel,
            onChanged: (String? newValue) {
              setState(() {
                _selectedModel = newValue!;
              });
            },
            items: <String>['llama3.2', 'mistral'] // Add more models as needed
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Endpoint URL:'),
          TextField(
            controller: _endpointController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _selectedEndpoint = value;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ollama GUI'),
      ),
      body: Stack(
        children: [
          ResponsiveLayout(
            mobile: _buildChatInterface(),
            tablet: Row(
              children: [
                Expanded(flex: 2, child: _buildChatInterface()),
                Expanded(flex: 1, child: _buildSettingsPanel()),
              ],
            ),
            desktop: Row(
              children: [
                SizedBox(width: 300, child: _buildSettingsPanel()),
                Expanded(child: _buildChatInterface()),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
