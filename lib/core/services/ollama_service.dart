import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ollama_message.dart';

class OllamaService {
  final String _baseUrl = 'http://localhost:11434'; // Default Ollama API URL

  Future<String> generateResponse(
    List<OllamaMessage> messages,
    String model, {
    String? endpoint,
  }) async {
    final baseUrl = endpoint ?? _baseUrl;
    final url = Uri.parse('$baseUrl/api/chat');
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

  Future<List<String>> getAvailableModels() async {
    try {
      final process = await Process.run('ollama', ['list']);
      if (process.exitCode == 0) {
        final output = process.stdout;
        final models = <String>[];
        final lines = output.split('\n');
        for (final line in lines) {
          if (line.isNotEmpty && !line.startsWith('NAME')) {
            // Split each line by spaces and take the first element (model name)
            final parts = line.split(RegExp(r'\s+'));
            if (parts.isNotEmpty) {
              final modelName = parts[0];
              models.add(modelName);
            }
          }
        }
        return models;
      } else {
        throw Exception('Failed to execute ollama list: ${process.stderr}');
      }
    } catch (e) {
      throw Exception('Error getting available models: $e');
    }
  }
}
