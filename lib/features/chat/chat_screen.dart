import 'package:flutter/material.dart';
import '../../core/models/message.dart';
import '../../shared/widgets/responsive_layout.dart';
import '../../core/services/ollama_service.dart';
import '../../core/models/ollama_message.dart';
import '../../shared/widgets/error_dialog.dart';
import '../../shared/widgets/animated_chat_message.dart';
import '../../core/services/voice_service.dart';
import 'settings_page.dart';

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
  List<String> _availableModels = ['llama3.2', 'mistral'];
  final VoiceService _voiceService = VoiceService();

  @override
  void initState() {
    super.initState();
    _loadAvailableModels();
  }

  Future<void> _loadAvailableModels() async {
    try {
      final models = await _ollamaService.getAvailableModels();
      setState(() {
        _availableModels = models;
        if (!models.contains(_selectedModel) && models.isNotEmpty) {
          _selectedModel = models.first;
        }
      });
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(message: e.toString()),
      );
    }
  }

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
            itemBuilder: (context, index) => GestureDetector(
              // Long-press a message to trigger voice output.
              onLongPress: () => _voiceOutput(_messages[index].text),
              child: _buildChatMessage(_messages[index]),
            ),
          ),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildChatMessage(Message message) {
    return AnimatedChatMessage(
      message: message.text,
      isUser: message.isUserMessage,
      onEdit: (updatedText) {
        setState(() {
          final index = _messages.indexOf(message);
          if (index != -1) {
            _messages[index] = Message(
                text: updatedText, isUserMessage: message.isUserMessage);
          }
        });
      },
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
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: _startVoiceInput,
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_textController.text),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(2, 2))
                ],
              ),
              child: const Icon(Icons.send, color: Colors.white),
            ),
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

  Future<void> _startVoiceInput() async {
    try {
      // For example purposes, assume an audio file path.
      const audioFilePath = '/path/to/audio.wav';
      final transcription = await _voiceService.transcribeVoice(audioFilePath);
      _sendMessage(transcription);
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(message: e.toString()),
      );
    }
  }

  Future<void> _voiceOutput(String text) async {
    try {
      await _voiceService.speakText(text);
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(message: e.toString()),
      );
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
            items:
                _availableModels.map<DropdownMenuItem<String>>((String value) {
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
    bool isMobile = MediaQuery.of(context).size.width < 800;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ollama GUI'),
        actions: isMobile
            ? [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(
                          selectedModel: _selectedModel,
                          selectedEndpoint: _selectedEndpoint,
                          availableModels: _availableModels,
                          onModelChanged: (newModel) =>
                              setState(() => _selectedModel = newModel),
                          onEndpointChanged: (newEndpoint) =>
                              setState(() => _selectedEndpoint = newEndpoint),
                        ),
                      ),
                    );
                  },
                )
              ]
            : null,
      ),
      body: Stack(
        children: [
          isMobile
              ? _buildChatInterface()
              : ResponsiveLayout(
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
      floatingActionButton: !isMobile
          ? FloatingActionButton(
              onPressed: _startVoiceInput,
              child: const Icon(Icons.mic),
            )
          : null,
    );
  }
}
