import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/app_state.dart';

class ProgressPanel extends StatelessWidget {
  const ProgressPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        if (state.progressState == ProgressState.idle) {
          return const SizedBox.shrink();
        }

        final progressColor = _getProgressColor(state.progressState);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: state.progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(progressColor),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${(state.progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        state.statusMessage,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                if (_showResetButton(state.progressState))
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: ElevatedButton(
                      onPressed: () => state.reset(),
                      child: const Text('重置'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getProgressColor(ProgressState state) {
    switch (state) {
      case ProgressState.completed:
        return Colors.green;
      case ProgressState.error:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  bool _showResetButton(ProgressState state) {
    return state == ProgressState.completed || state == ProgressState.error;
  }
}
