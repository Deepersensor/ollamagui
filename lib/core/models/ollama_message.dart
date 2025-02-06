class OllamaMessage {
  final String role;
  final String content;

  OllamaMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}
