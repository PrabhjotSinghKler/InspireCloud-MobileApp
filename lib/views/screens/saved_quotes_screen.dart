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

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final backgroundColor = colorScheme.background;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Saved Quotes'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar with enhanced styling
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search quotes by content or category',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search, color: primaryColor),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: colorScheme.onSurface.withOpacity(0.5),
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
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
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                final quotes = _filterQuotes(quoteController.savedQuotes);

                if (quotes.isEmpty) {
                  // Enhanced empty state
                  return Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _searchQuery.isEmpty
                                    ? Icons.bookmark_border
                                    : Icons.search_off,
                                size: 48,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No saved quotes yet'
                                  : 'No quotes match "$_searchQuery"',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onBackground,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Generate and save quotes from the home screen to build your collection'
                                  : 'Try a different search term or clear your search',
                              style: TextStyle(
                                color: colorScheme.onBackground.withOpacity(
                                  0.7,
                                ),
                                fontSize: 15,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            if (_searchQuery.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Clear Search'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            if (_searchQuery.isEmpty)
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Create New Quote'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  side: BorderSide(color: primaryColor),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: ListView.builder(
                    key: ValueKey<int>(quotes.length),
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: quotes.length,
                    itemBuilder: (context, index) {
                      final quote = quotes[index];
                      return _buildQuoteCard(
                        context,
                        quote,
                        quoteController,
                        index,
                        primaryColor,
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
    Color primaryColor,
  ) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Staggered animation for each card
        final delay = index * 0.15; // Reduced delay for smoother animation
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
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.label_outline,
                          size: 16,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          quote.category,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(quote.savedAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quote content with decorative elements
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: primaryColor.withOpacity(0.5),
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  '"${quote.content}"',
                  style: TextStyle(
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Share button
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    color: primaryColor,
                    onPressed: () => _shareQuote(quote),
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: Colors.red.shade700,
                    onPressed: () async {
                      // Confirm deletion with enhanced dialog
                      final confirmed = await _showDeleteConfirmationDialog(
                        quote,
                      );

                      if (confirmed == true && context.mounted) {
                        await quoteController.deleteQuote(quote.id!);
                        _showSnackBar('Quote deleted successfully');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(SavedQuoteModel quote) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text('Delete Quote'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete this quote?',
                  style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '"${quote.content}"',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurface.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('CANCEL'),
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              TextButton(
                child: Text(
                  'DELETE',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: colorScheme.background,
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
      _showSnackBar('Quote shared successfully');
    } catch (e) {
      _showSnackBar('Error sharing quote: ${e.toString()}', isError: true);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
