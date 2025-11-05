import 'package:flutter/material.dart';
import '../utils/program_state.dart';

class AiProgramPage extends StatelessWidget {
  const AiProgramPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New AI Program')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This is a placeholder for AI program generation. Configure your goals and tap Generate.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                const name = 'AI Generated Program';
                await ProgramState.saveActiveProgramName(name);
                if (context.mounted) Navigator.pop(context, name);
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }
}
