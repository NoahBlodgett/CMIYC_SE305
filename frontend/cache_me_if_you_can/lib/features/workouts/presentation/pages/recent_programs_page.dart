import 'package:flutter/material.dart';
import '../../../../mock/mock_data.dart';
import '../../../../utils/program_state.dart';

class RecentProgramsPage extends StatefulWidget {
  const RecentProgramsPage({super.key});

  @override
  State<RecentProgramsPage> createState() => _RecentProgramsPageState();
}

class _RecentProgramsPageState extends State<RecentProgramsPage> {
  late Future<List<String>> _futurePrograms;

  @override
  void initState() {
    super.initState();
    _futurePrograms = fetchRecentPrograms();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Recent programs')),
      body: FutureBuilder<List<String>>(
        future: _futurePrograms,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final programs = snapshot.data ?? const <String>[];
          if (programs.isEmpty) {
            return const Center(child: Text('No recent programs'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final name = programs[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.fitness_center, color: color.primary),
                ),
                title: Text(name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await ProgramState.saveActiveProgramName(name);
                  if (context.mounted) Navigator.pop(context, name);
                },
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: programs.length,
          );
        },
      ),
    );
  }
}
