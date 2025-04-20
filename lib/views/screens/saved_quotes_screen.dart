// lib/views/screens/saved_quotes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/quote_controller.dart';
import '../../models/saved_quote_model.dart';

class SavedQuotesScreen extends StatefulWidget {
  const SavedQuotesScreen({super.key});

  @override
  State<SavedQuotesScreen> createState() => _SavedQuotesScreenState();
}

class _SavedQuotesScreenState extends State<SavedQuotesScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Fetch saved quotes when screen loads
    Future.microtask(
      () =>
          Provider.of<QuoteController>(
            context,
            listen: false,
          ).fetchSavedQuotes(),
    );
  }

  @override
  void dispose() {
    // When leaving the saved quotes screen, refresh statistics to update counters
    if (mounted) {
      Future.microtask(() {
        if (context.mounted) {
          final quoteController = Provider.of<QuoteController>(
            context,
            listen: false,
          );
          quoteController.refreshStatistics();
        }
      });
    }

    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<SavedQuoteModel> _filterQuotes(List<SavedQuoteModel> quotes) {
    if (_searchQuery.isEmpty) return quotes;

    return quotes.where((quote) {
      return quote.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          quote.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Quotes'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search quotes by content or category',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Quote List
          Expanded(
            child: Consumer<QuoteController>(
              builder: (context, quoteController, child) {
                if (quoteController.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final quotes = _filterQuotes(quoteController.savedQuotes);

                if (quotes.isEmpty) {
                  // Show different empty states based on search or no saved quotes
                  return Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty
                                ? Icons.bookmark_border
                                : Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No saved quotes yet'
                                : 'No quotes match "$_searchQuery"',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Generate and save quotes to see them here'
                                : 'Try a different search term',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: ListView.builder(
                    key: ValueKey<int>(quotes.length),
                    padding: const EdgeInsets.all(16),
                    itemCount: quotes.length,
                    itemBuilder: (context, index) {
                      final quote = quotes[index];
                      return _buildQuoteCard(
                        context,
                        quote,
                        quoteController,
                        index,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(
    BuildContext context,
    SavedQuoteModel quote,
    QuoteController quoteController,
    int index,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Staggered animation for each card
        final delay = index * 0.2;
        final startTime = delay;
        final endTime = 1.0;

        final animationValue = _animationController.value;
        final opacity =
            animationValue < startTime
                ? 0.0
                : (animationValue - startTime) / (endTime - startTime);

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - opacity.clamp(0.0, 1.0))),
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${quote.content}"',
                style: const TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Category and date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category: ${quote.category}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Saved: ${_formatDate(quote.savedAt)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  // Action Buttons
                  Row(
                    children: [
                      // Share button
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.blue),
                        onPressed: () {
                          _shareQuote(quote);
                        },
                      ),
                      // Delete button
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          // Confirm deletion
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Delete Quote'),
                                  content: const Text(
                                    'Are you sure you want to delete this quote?',
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text('CANCEL'),
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                    ),
                                    TextButton(
                                      child: const Text('DELETE'),
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                    ),
                                  ],
                                ),
                          );

                          if (confirmed == true && context.mounted) {
                            await quoteController.deleteQuote(quote.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Quote deleted'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareQuote(SavedQuoteModel quote) {
    try {
      final quoteController = Provider.of<QuoteController>(
        context,
        listen: false,
      );
      quoteController.shareQuote(quote.content, quote.category);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing quote: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
