// lib/screens/waiting_for_approval_screen.dart

import 'package:flutter/material.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';
import 'package:substation_manager/services/auth_service.dart';
import 'package:substation_manager/screens/sign_in_screen.dart';
import 'package:substation_manager/models/user_profile.dart';

class WaitingForApprovalScreen extends StatefulWidget {
  final UserProfile userProfile;

  const WaitingForApprovalScreen({super.key, required this.userProfile});

  @override
  State<WaitingForApprovalScreen> createState() =>
      _WaitingForApprovalScreenState();
}

class _WaitingForApprovalScreenState extends State<WaitingForApprovalScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    String titleText = '';
    String messageText = '';
    IconData displayIcon = Icons.hourglass_empty;
    Color iconColor = colorScheme.tertiary;
    bool showRefreshButton = true;

    switch (widget.userProfile.status) {
      case 'pending':
        titleText = 'Account Pending Approval';
        messageText =
            'Your account is awaiting approval from an administrator. Once approved, you will gain full access to the app features.';
        displayIcon = Icons.hourglass_empty;
        iconColor = colorScheme.tertiary;
        break;
      case 'rejected':
        titleText = 'Account Rejected';
        messageText =
            'Unfortunately, your account has been rejected by an administrator. Please contact support for more information.';
        displayIcon = Icons.cancel;
        iconColor = colorScheme.error;
        showRefreshButton = false;
        break;
      default:
        titleText = 'Account Status Unknown';
        messageText =
            'An unexpected account status was encountered. Please contact support.';
        displayIcon = Icons.help_outline;
        iconColor = Colors.grey;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(displayIcon, size: 80, color: iconColor),
              const SizedBox(height: 20),
              Text(
                titleText,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                messageText,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (showRefreshButton)
                ElevatedButton.icon(
                  onPressed: () async {
                    if (mounted) {
                      SnackBarUtils.showSnackBar(
                        context,
                        'Re-checking account status...',
                      );
                    }
                    await _authService.signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const SignInScreen(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-check Status (Requires Sign Out)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
