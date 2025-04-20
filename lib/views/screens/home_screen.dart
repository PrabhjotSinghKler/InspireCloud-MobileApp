// lib/views/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/quote_controller.dart';
import 'saved_quotes_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  String _selectedCategory = 'Motivation';
  bool _isGenerating = false;
  String? _generatedQuote;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = [
    'Motivation',
    'Success',
    'Life',
    'Happiness',
    'Wisdom',
    'Love',
    'Friendship',
    'Inspiration',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _shareQuote() {
    if (_generatedQuote == null || _generatedQuote!.isEmpty) {
      _showSnackBar('No quote to share', isError: true);
      return;
    }

    try {
      final quoteController = Provider.of<QuoteController>(
        context,
        listen: false,
      );
      quoteController.shareQuote(_generatedQuote!, _selectedCategory);
      _showSnackBar('Quote shared successfully');
    } catch (e) {
      _showSnackBar('Error sharing quote: ${e.toString()}', isError: true);
    }
  }

  Future<void> _generateQuote() async {
    if (_promptController.text.isEmpty && _selectedCategory.isEmpty) {
      _showSnackBar(
        'Please enter a prompt or select a category',
        isError: true,
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final quoteController = Provider.of<QuoteController>(
        context,
        listen: false,
      );
      final quote = await quoteController.generateQuote(
        prompt: _promptController.text,
        category: _selectedCategory,
      );

      setState(() {
        _generatedQuote = quote;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      _showSnackBar('Error generating quote: ${e.toString()}', isError: true);
    }
  }

  Future<void> _saveQuote() async {
    if (_generatedQuote == null || _generatedQuote!.isEmpty) {
      _showSnackBar('No quote to save', isError: true);
      return;
    }

    try {
      final quoteController = Provider.of<QuoteController>(
        context,
        listen: false,
      );
      await quoteController.saveQuote(
        content: _generatedQuote!,
        category: _selectedCategory,
      );

      _showSnackBar('Quote saved successfully');
    } catch (e) {
      _showSnackBar('Error saving quote: ${e.toString()}', isError: true);
    }
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
    final authController = Provider.of<AuthController>(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final backgroundColor = colorScheme.background;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('AI Quote Generator'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            tooltip: 'Saved Quotes',
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          const SavedQuotesScreen(),
                  transitionsBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          const ProfileScreen(),
                  transitionsBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome section with enhanced styling
              Container(
                margin: const EdgeInsets.only(bottom: 24.0),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.8),
                      primaryColor.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const ProfileScreen(),
                            transitionsBuilder: (
                              context,
                              animation,
                              secondaryAnimation,
                              child,
                            ) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'profile_avatar',
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white.withOpacity(0.9),
                            child: Text(
                              authController.user?.displayName?.isNotEmpty ==
                                      true
                                  ? authController.user!.displayName![0]
                                      .toUpperCase()
                                  : (authController.user?.email != null
                                      ? authController.user!.email[0]
                                          .toUpperCase()
                                      : 'U'),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${authController.user?.displayName ?? authController.user?.email.split('@').first ?? 'User'}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'What quote would you like to generate today?',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Input section with enhanced styling
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Your Quote',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generate a quote by entering a prompt or selecting a category',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Prompt input with enhanced styling
                      _buildTextField(
                        controller: _promptController,
                        label: 'Enter your prompt (optional)',
                        hint: 'E.g., A quote about overcoming challenges',
                        icon: Icons.edit,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),

                      // Category dropdown with enhanced styling
                      _buildDropdown(
                        value: _selectedCategory,
                        label: 'Select Category',
                        icon: Icons.category,
                        items:
                            _categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 32),

                      // Generate button with enhanced styling
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _generateQuote,
                          icon:
                              _isGenerating
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                  : const Icon(Icons.auto_awesome),
                          label: Text(
                            _isGenerating ? 'Generating...' : 'Generate Quote',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            shadowColor: primaryColor.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Generated quote display with enhanced styling
              if (_generatedQuote != null) ...[
                const SizedBox(height: 32),
                AnimatedOpacity(
                  opacity: _generatedQuote != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.format_quote,
                                color: primaryColor,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Your Generated Quote',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 24,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '"$_generatedQuote"',
                              style: TextStyle(
                                fontSize: 20,
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                                color: colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.label_outline,
                                size: 18,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _selectedCategory,
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(
                                onPressed: _generateQuote,
                                icon: Icons.refresh,
                                label: 'Regenerate',
                                color: Colors.blue,
                                isOutlined: true,
                              ),
                              _buildActionButton(
                                onPressed: _saveQuote,
                                icon: Icons.favorite_outline,
                                label: 'Save',
                                color: Colors.pink.shade700,
                              ),
                              _buildActionButton(
                                onPressed: _shareQuote,
                                icon: Icons.share,
                                label: 'Share',
                                color: Colors.green.shade700,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // Random quote suggestion with enhanced styling
              if (_generatedQuote == null) ...[
                const SizedBox(height: 32),
                Card(
                  elevation: 1,
                  color: primaryColor.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: primaryColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory =
                            _categories[DateTime.now().millisecond %
                                _categories.length];
                        _promptController.clear();
                      });
                      _generateQuote();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber.shade700,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Need inspiration?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Generate a random quote in a random category',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: colorScheme.onSurface.withOpacity(0.4),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.4),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline, width: 1.5),
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
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline, width: 1.5),
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
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items: items,
      onChanged: onChanged,
      icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
      dropdownColor: colorScheme.surface,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isOutlined = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style:
          isOutlined
              ? ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: color,
                elevation: 0,
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              )
              : ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
    );
  }
}
