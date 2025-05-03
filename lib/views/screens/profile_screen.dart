// lib/views/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/quote_controller.dart';
import 'auth/login_screen.dart';
import '../../services/logging_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEditingName = false;
  bool _isUpdatingProfile = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

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

    Future.microtask(() {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );
      if (authController.user?.displayName != null) {
        _displayNameController.text = authController.user!.displayName!;
      }

      final loggingService = Provider.of<LoggingService>(
        context,
        listen: false,
      );
      loggingService.log(
        type: 'page_view',
        event: 'viewed_ProfileScreen',
        metadata: {},
      );

      Provider.of<QuoteController>(context, listen: false).refreshStatistics();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Reduce image size to improve upload performance
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _profileImage = File(pickedFile.path);
          _isUpdatingProfile = true; // Show loading indicator right away
        });

        // Upload the profile image
        await _uploadProfileImage();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error picking image: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProfile = false;
        });
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;

    try {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );
      final loggingService = Provider.of<LoggingService>(
        context,
        listen: false,
      );

      await authController.updateProfilePhoto(_profileImage!);

      // ✅ Log profile photo update
      await loggingService.log(
        type: 'activity',
        event: 'updated_profile_photo',
        metadata: {'timestamp': DateTime.now().toIso8601String()},
      );

      if (mounted) {
        _showSnackBar('Profile photo updated successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Error updating profile photo: ${e.toString()}',
          isError: true,
        );

        // Reset profile image on error
        setState(() {
          _profileImage = null;
        });
      }
    }
  }

  Future<void> _updateDisplayName() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdatingProfile = true;
    });

    try {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );

      await authController.updateDisplayName(
        _displayNameController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isEditingName = false;
          _isUpdatingProfile = false;
        });

        _showSnackBar('Display name updated successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingProfile = false;
        });

        _showSnackBar(
          'Error updating display name: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final authController = Provider.of<AuthController>(context, listen: false);

    try {
      await authController.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar('Error signing out: ${e.toString()}', isError: true);
      }
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final backgroundColor = colorScheme.surface;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Your Profile'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () async {
            final loggingService = Provider.of<LoggingService>(
              context,
              listen: false,
            );
            await loggingService.log(
              type: 'navigation',
              event: 'navigated_profile_to_home',
              metadata: {'method': 'appbar_back_button'},
            );
            Navigator.pop(context);
          },
        ),
      ),
      body: Consumer<AuthController>(
        builder: (context, authController, _) {
          if (authController.isLoading || _isUpdatingProfile) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          final user = authController.user;
          if (user == null) {
            return Center(
              child: Text(
                'No user logged in',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            );
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Header
                  _buildProfileHeader(user, primaryColor),
                  const SizedBox(height: 32),

                  // Profile Info Section
                  Text(
                    'Account Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Display Name
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child:
                        _isEditingName
                            ? _buildNameEditForm(primaryColor)
                            : _buildInfoCard(
                              icon: Icons.person_outline,
                              title: 'Display Name',
                              value:
                                  user.displayName?.isNotEmpty == true
                                      ? user.displayName!
                                      : 'Set a display name',
                              hasValue: user.displayName?.isNotEmpty == true,
                              onTap: () {
                                setState(() {
                                  _isEditingName = true;
                                });
                              },
                              iconColor: primaryColor,
                            ),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  _buildInfoCard(
                    icon: Icons.email_outlined,
                    title: 'Email Address',
                    value: user.email,
                    hasValue: true,
                    onTap: null, // Email is not editable
                    iconColor: primaryColor,
                  ),

                  const SizedBox(height: 32),

                  // Stats Section
                  _buildStatsSection(primaryColor),

                  const SizedBox(height: 32),

                  // Action Buttons
                  _buildActionButtons(primaryColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(user, Color primaryColor) {
    return Column(
      children: [
        // Profile Avatar with Upload Option
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              Hero(
                tag: 'profile_avatar',
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: primaryColor.withOpacity(0.2),
                    backgroundImage:
                        _profileImage != null
                            ? FileImage(_profileImage!)
                            : (user.photoUrl != null &&
                                    user.photoUrl!.isNotEmpty
                                ? NetworkImage(user.photoUrl!) as ImageProvider
                                : null),
                    child:
                        (_profileImage == null &&
                                (user.photoUrl == null ||
                                    user.photoUrl!.isEmpty))
                            ? Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  user.displayName?.isNotEmpty == true
                                      ? user.displayName![0].toUpperCase()
                                      : user.email[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 42,
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_isUpdatingProfile)
                                  CircularProgressIndicator(
                                    color: primaryColor,
                                    strokeWidth: 3,
                                  ),
                              ],
                            )
                            : _isUpdatingProfile
                            ? CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            )
                            : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // User Name
        Text(
          user.displayName?.isNotEmpty == true
              ? user.displayName!
              : user.email.split('@').first,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        // Account Type Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            'Cloud App User',
            style: TextStyle(
              fontSize: 13,
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required bool hasValue,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontStyle:
                            hasValue ? FontStyle.normal : FontStyle.italic,
                        color:
                            hasValue
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.edit_outlined,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameEditForm(Color primaryColor) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primaryColor.withOpacity(0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_outline, color: primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Edit Display Name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  hintText: 'Enter your display name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a display name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditingName = false;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _updateDisplayName,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'SAVE',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(Color primaryColor) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<QuoteController>(
      builder: (context, quoteController, _) {
        final savedQuoteCount = quoteController.savedQuotes.length;
        final generatedQuoteCount = quoteController.generatedQuotesCount;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Activity Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh_outlined,
                        size: 20,
                        color: primaryColor,
                      ),
                      onPressed: () {
                        quoteController.refreshStatistics();
                        _showSnackBar('Statistics refreshed');
                      },
                      tooltip: 'Refresh statistics',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.bookmark_border,
                        value: savedQuoteCount.toString(),
                        label: 'Saved Quotes',
                        color: primaryColor,
                      ),
                    ),
                    Container(
                      height: 60,
                      width: 1,
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.auto_awesome,
                        value: generatedQuoteCount.toString(),
                        label: 'Generated',
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            final loggingService = Provider.of<LoggingService>(
              context,
              listen: false,
            );
            await loggingService.log(
              type: 'navigation',
              event: 'navigated_profile_to_home',
              metadata: {},
            );
            Navigator.pop(context);
          },

          icon: const Icon(Icons.home_outlined, size: 20),
          label: const Text('Back to Quote Generator'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _signOut(context),
          icon: const Icon(Icons.logout_outlined, size: 20),
          label: const Text('Sign Out'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            foregroundColor: Colors.red.shade800,
            side: BorderSide(color: Colors.red.shade200),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
