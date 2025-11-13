import 'package:flutter/material.dart';
import '../../../../utils/program_state.dart';

class BuildProgramPage extends StatefulWidget {
  const BuildProgramPage({super.key});

  @override
  State<BuildProgramPage> createState() => _BuildProgramPageState();
}

class _BuildProgramPageState extends State<BuildProgramPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Build Program')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Program name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final name = _controller.text.trim().isEmpty
                    ? 'Custom Program'
                    : _controller.text.trim();
                await ProgramState.saveActiveProgramName(name);
                if (context.mounted) Navigator.pop(context, name);
              },
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
