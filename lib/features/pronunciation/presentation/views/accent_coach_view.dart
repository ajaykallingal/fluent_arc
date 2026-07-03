import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/score_card.dart';
import '../view_models/accent_coach_view_model.dart';
import '../../domain/services/pronunciation_analyzer.dart';

class AccentCoachView extends ConsumerWidget {
  const AccentCoachView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(accentCoachNotifierProvider);
    final notifier = ref.read(accentCoachNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Accent Coach')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Target text box card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Target Practice Phrase',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              state.isPlayingTts
                                  ? Icons.volume_up
                                  : Icons.volume_mute,
                              color: theme.colorScheme.primary,
                            ),
                            tooltip: 'Hear pronunciation',
                            onPressed: state.isListening || state.isAnalyzing
                                ? null
                                : () => notifier.speakPrompt(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.targetText,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showPresetDialog(context, notifier),
                        icon: const Icon(Icons.playlist_add_rounded),
                        label: const Text('Choose Another Phrase'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 40),
                          backgroundColor: theme.colorScheme.secondary
                              .withOpacity(0.1),
                          foregroundColor: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Recording Hub
              Center(
                child: Column(
                  children: [
                    Text(
                      state.isListening
                          ? 'Listening... Tap to finish'
                          : state.isAnalyzing
                          ? 'Analyzing accents...'
                          : 'Tap mic and read the phrase aloud',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: state.isListening
                            ? theme.colorScheme.error
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMicButton(context, theme, state, notifier),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Analysis Result Report
              if (state.isAnalyzing) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ] else if (state.result != null) ...[
                _buildAnalysisReport(context, theme, state.result!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton(
    BuildContext context,
    ThemeData theme,
    AccentCoachState state,
    AccentCoachNotifier notifier,
  ) {
    final isListening = state.isListening;
    final isAnalyzing = state.isAnalyzing;

    final micColor = isListening
        ? theme.colorScheme.error
        : isAnalyzing
        ? theme.colorScheme.onSurface.withOpacity(0.1)
        : theme.colorScheme.primary;

    return GestureDetector(
      onTap: isAnalyzing
          ? null
          : () {
              if (isListening) {
                notifier.stopRecordingAndAnalyze();
              } else {
                notifier.startRecording();
              }
            },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: micColor.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: micColor, width: 2),
        ),
        child: Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: micColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: micColor.withOpacity(0.4),
                  blurRadius: isListening ? 24 : 8,
                  spreadRadius: isListening ? 4 : 0,
                ),
              ],
            ),
            child: Icon(
              isListening
                  ? Icons.stop_rounded
                  : isAnalyzing
                  ? Icons.sync_rounded
                  : Icons.mic_none_rounded,
              color: isListening
                  ? Colors.white
                  : isAnalyzing
                  ? theme.colorScheme.onSurface
                  : Colors.white,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisReport(
    BuildContext context,
    ThemeData theme,
    PronunciationAnalysisResult result,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pronunciation Accuracy',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ScoreCard(
          title: 'Speaking Fluency Rating',
          score: result.overallScore,
          description: result.generalFeedback,
        ),
        const SizedBox(height: 20),

        // Phoneme segment card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap any word to view coach advice:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: result.words.map((wordObj) {
                    final isCorrect = wordObj.score >= 80;
                    final isWarning = wordObj.score >= 50 && wordObj.score < 80;

                    final chipBg = isCorrect
                        ? theme.colorScheme.tertiary.withOpacity(0.1)
                        : isWarning
                        ? Colors.orange.withOpacity(0.1)
                        : theme.colorScheme.error.withOpacity(0.1);

                    final chipColor = isCorrect
                        ? theme.colorScheme.tertiary
                        : isWarning
                        ? Colors.orange[800]!
                        : theme.colorScheme.error;

                    return ActionChip(
                      backgroundColor: chipBg,
                      side: BorderSide(color: chipColor, width: 1),
                      label: Text(
                        wordObj.word,
                        style: TextStyle(
                          color: chipColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () => _showWordFeedback(context, wordObj),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showWordFeedback(BuildContext context, PronunciationWord wordObj) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Feedback for "${wordObj.word}"',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Pronunciation Score: '),
                  Text(
                    '${wordObj.score}/100',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: wordObj.score >= 80
                          ? theme.colorScheme.tertiary
                          : wordObj.score >= 50
                          ? Colors.orange
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                wordObj.feedback,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Got It',
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPresetDialog(BuildContext context, AccentCoachNotifier notifier) {
    final presets = [
      'I would like to acquire native fluency in speaking.',
      'Consistency is the key to mastering English grammar.',
      'Can you recommend a nice restaurant near the central plaza?',
      'Exploring new vocabulary helps express complex ideas clearly.',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Practice Phrase'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: presets.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(presets[index]),
                  onTap: () {
                    notifier.updateTargetText(presets[index]);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
