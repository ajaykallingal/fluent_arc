import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/score_card.dart';
import '../view_models/grammar_view_model.dart';

class GrammarView extends ConsumerStatefulWidget {
  const GrammarView({super.key});

  @override
  ConsumerState<GrammarView> createState() => _GrammarViewState();
}

class _GrammarViewState extends ConsumerState<GrammarView> {
  final _inputController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ref
        .read(grammarNotifierProvider.notifier)
        .checkGrammar(_inputController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grammarState = ref.watch(grammarNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Grammar Coach')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Check Your English',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter any sentence or paragraph, and the AI coach will analyze it for grammatical corrections and explain rules.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),

              // Form field
              Form(
                key: _formKey,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          controller: _inputController,
                          labelText: 'Type sentence here...',
                          hintText: 'e.g. He go to school yesterday.',
                          keyboardType: TextInputType.multiline,
                          prefixIcon: Icons.edit_note_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please write something to check';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          text: 'Analyze Sentence',
                          isLoading: grammarState.isLoading,
                          icon: Icons.check_circle_outline_rounded,
                          onPressed: grammarState.isLoading ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Loading / Error state
              if (grammarState.errorMessage != null) ...[
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      grammarState.errorMessage!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ],

              // Results Section
              if (grammarState.report != null) ...[
                Text(
                  'Analysis Results',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Score card
                ScoreCard(
                  title: 'Grammar Rating',
                  score: grammarState.report!.score.toDouble(),
                  description: grammarState.report!.score >= 90
                      ? 'Excellent accuracy! Keep it up.'
                      : grammarState.report!.score >= 70
                      ? 'Decent phrasing, but minor errors detected.'
                      : 'Major corrections suggested to improve clarity.',
                ),
                const SizedBox(height: 16),

                // Comparison card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Original Phrase',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          grammarState.report!.originalText,
                          style: const TextStyle(fontSize: 15),
                        ),
                        const Divider(height: 24),
                        Text(
                          'Corrected Phrase',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          grammarState.report!.correctedText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Explanation card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Coach Explanation',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          grammarState.report!.explanation,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Reset button
                SecondaryButton(
                  text: 'Check Another Sentence',
                  icon: Icons.refresh_rounded,
                  onPressed: () {
                    ref.read(grammarNotifierProvider.notifier).reset();
                    _inputController.clear();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
