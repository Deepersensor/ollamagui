import 'package:flutter/material.dart';
import '../../core/models/message.dart';
import '../../shared/widgets/responsive_layout.dart';
import '../../core/services/ollama_service.dart';
import '../../core/models/ollama_message.dart';
import '../../shared/widgets/error_dialog.dart';
import '../../shared/widgets/animated_chat_message.dart';
import '../../core/services/voice_service.dart';
import 'settings_page.dart';
import 'package:flutter/services.dart';

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
  Process? _voiceProcess; // Added to track voice output process

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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: _buildChatMessage(_messages[index]),
              ),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatMessage(Message message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: message.isUserMessage
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            decoration: BoxDecoration(
              color:
                  message.isUserMessage ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(message.text),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedChatMessageActions(
                message: message,
                onEdit: (updatedText) {
                  setState(() {
                    final index = _messages.indexOf(message);
                    if (index != -1) {
                      _messages[index] = Message(
                          text: updatedText,
                          isUserMessage: message.isUserMessage);
                    }
                  });
                },
                onVoiceOutput: () => _voiceOutput(message.text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    // Determine if mobile to conditionally include the mic in the TextField.
    final isMobile = MediaQuery.of(context).size.width < 800;
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
                // Only show the mic if on mobile.
                suffixIcon: isMobile
                    ? IconButton(
                        icon: const Icon(Icons.mic),
                        onPressed: _startVoiceInput,
                      )
                    : null,
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
    // If already speaking, kill the process to stop voice output.
    if (_voiceProcess != null) {
      _voiceProcess!.kill();
      setState(() {
        _voiceProcess = null;
      });
      return;
    }
    try {
      _voiceProcess = await _voiceService.speakText(text);
      // When process exits, clear the reference.
      _voiceProcess!.exitCode.then((_) {
        if (mounted) {
          setState(() {
            _voiceProcess = null;
          });
        }
      });
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
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _buildChatInterface(),
                        ),
                      ),
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

class AnimatedChatMessageActions extends StatelessWidget {
  final Message message;
  final Function(String) onEdit;
  final VoidCallback onVoiceOutput;

  const AnimatedChatMessageActions({
    super.key,
    required this.message,
    required this.onEdit,
    required this.onVoiceOutput,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            // Trigger edit mode in the parent widget
          },
        ),
        IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: message.text));
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')));
          },
        ),
        IconButton(
          icon: const Icon(Icons.record_voice_over),
          onPressed: onVoiceOutput,
        ),
      ],
    );
  }
}
