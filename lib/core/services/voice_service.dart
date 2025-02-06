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

  // Modified: Return the Process so caller can cancel it.
  Future<Process> speakText(String text) async {
    // Check for flite installation.
    final fliteResult = await Process.run('flite', ['-version']);
    if (fliteResult.exitCode != 0) {
      throw Exception('flite is not installed. Please install flite.');
    }
    // Execute flite CLI to speak text.
    final process = await Process.start('flite', ['-t', text]);
    // Optionally listen to process.exit
    return process;
  }
}
