import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final String selectedModel;
  final String selectedEndpoint;
  final List<String> availableModels;
  final Function(String) onModelChanged;
  final Function(String) onEndpointChanged;

  const SettingsPage({
    super.key,
    required this.selectedModel,
    required this.selectedEndpoint,
    required this.availableModels,
    required this.onModelChanged,
    required this.onEndpointChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Padding(
          key: const ValueKey('settings'),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Model:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: selectedModel,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onModelChanged(newValue);
                  }
                },
                items: availableModels
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text('Endpoint URL:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: TextEditingController(text: selectedEndpoint),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  onEndpointChanged(value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
