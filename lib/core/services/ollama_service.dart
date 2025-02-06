import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/ollama_message.dart';

class OllamaService {
  final String _baseUrl = dotenv.env['OLLAMA_API_URL'] ??
      'http://localhost:11434'; // Default Ollama API URL

  Future<String> generateResponse(
      List<OllamaMessage> messages, String model) async {
    final url = Uri.parse('$_baseUrl/api/chat');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model,
          'messages': messages.map((m) => m.toJson()).toList(),
          'stream': false, // Set stream to false for a single response
        }),
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return decodedResponse['message']['content'] ?? 'No response';
      } else {
        throw Exception('Failed to generate response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error communicating with Ollama API: $e');
    }
  }
}
