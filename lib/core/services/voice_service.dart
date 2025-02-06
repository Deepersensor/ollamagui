import 'dart:io';

class VoiceService {
  Future<String> transcribeVoice(String audioFilePath) async {
    // Check for vosk-transcriber installation.
    final voskResult = await Process.run('vosk-transcriber', ['--version']);
    if (voskResult.exitCode != 0) {
      throw Exception(
          'vosk-transcriber is not installed. Please install via pip.');
    }
    // Execute vosk-transcriber CLI.
    final result = await Process.run('vosk-transcriber', [audioFilePath]);
    if (result.exitCode == 0) {
      return result.stdout.toString();
    } else {
      throw Exception('Transcription failed: ${result.stderr}');
    }
  }

  Future<void> speakText(String text) async {
    // Check for flite installation.
    final fliteResult = await Process.run('flite', ['-version']);
    if (fliteResult.exitCode != 0) {
      throw Exception('flite is not installed. Please install flite.');
    }
    // Execute flite CLI to speak text.
    final result = await Process.run('flite', ['-t', text]);
    if (result.exitCode != 0) {
      throw Exception('Voice output failed: ${result.stderr}');
    }
  }
}
