import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../view_models/vocabulary_view_model.dart';
import '../../../../core/services/ai/ai_provider.dart';

class VocabularyView extends ConsumerStatefulWidget {
  const VocabularyView({super.key});

  @override
  ConsumerState<VocabularyView> createState() => _VocabularyViewState();
}

class _VocabularyViewState extends ConsumerState<VocabularyView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _topicController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedDifficulty = 'Intermediate';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  void _generate() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ref
        .read(vocabularyNotifierProvider.notifier)
        .generateSuggestions(
          _topicController.text,
          difficulty: _selectedDifficulty,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vocabState = ref.watch(vocabularyNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary Coach'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Discover Words', icon: Icon(Icons.search_rounded)),
            Tab(
              text: 'My Practice Vault',
              icon: Icon(Icons.folder_special_outlined),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Discover Words
          _buildDiscoverTab(theme, vocabState),

          // Tab 2: Saved Vault
          _buildVaultTab(theme, vocabState),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab(ThemeData theme, VocabularyState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Generate Contextual Vocabulary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type a topic of interest (e.g. "business negotiations", "dinosaurs") to learn 3 advanced terms matching your difficulty level.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),

          // Search Form
          Form(
            key: _formKey,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _topicController,
                      labelText: 'Topic / Subject',
                      hintText: 'e.g. Cooking, Space, Coding',
                      prefixIcon: Icons.menu_book_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide a topic';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Difficulty:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'Beginner',
                                label: Text('Beg'),
                              ),
                              ButtonSegment(
                                value: 'Intermediate',
                                label: Text('Int'),
                              ),
                              ButtonSegment(
                                value: 'Advanced',
                                label: Text('Adv'),
                              ),
                            ],
                            selected: {_selectedDifficulty},
                            onSelectionChanged: (newSelection) {
                              setState(() {
                                _selectedDifficulty = newSelection.first;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: 'Generate Words',
                      isLoading: state.isLoadingSuggestions,
                      icon: Icons.auto_awesome_rounded,
                      onPressed: state.isLoadingSuggestions ? null : _generate,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Error state
          if (state.errorMessage != null && state.suggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ),

          // Suggested list
          if (state.isLoadingSuggestions)
            const SizedBox(
              height: 200,
              child: LoadingView(message: 'Generating custom words...'),
            )
          else if (state.suggestions.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Suggested Terms',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${state.suggestions.length} words found',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = state.suggestions[index];
                final isSaved = state.savedWords.any(
                  (w) => w.word.toLowerCase() == suggestion.word.toLowerCase(),
                );
                return _buildSuggestionCard(theme, suggestion, isSaved);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(
    ThemeData theme,
    AiVocabularyWord suggestion,
    bool isSaved,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        suggestion.word,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          suggestion.difficulty,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    suggestion.definition,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Example: "${suggestion.example}"',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isSaved
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                color: isSaved
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.primary,
                size: 28,
              ),
              onPressed: isSaved
                  ? null
                  : () {
                      ref
                          .read(vocabularyNotifierProvider.notifier)
                          .saveWord(suggestion);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Saved "${suggestion.word}" to practice vault.',
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultTab(ThemeData theme, VocabularyState state) {
    if (state.isLoadingSaved) {
      return const LoadingView(message: 'Opening vault...');
    }

    if (state.savedWords.isEmpty) {
      return const EmptyView(
        title: 'Empty Vocabulary Vault',
        message:
            'No terms saved yet. Head over to the Discover tab to add terms by topic!',
        icon: Icons.style_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.savedWords.length,
      itemBuilder: (context, index) {
        final vocab = state.savedWords[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            vocab.word,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              vocab.difficulty,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        vocab.definition,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Example: "${vocab.example}"',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: () {
                    ref
                        .read(vocabularyNotifierProvider.notifier)
                        .deleteWord(vocab.word);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed "${vocab.word}" from vault.'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
