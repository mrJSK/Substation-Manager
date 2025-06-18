// lib/screens/connectivity_wrapper.dart

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:substation_manager/screens/no_internet_screen.dart';
import 'dart:async';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final bool currentlyOffline =
        !results.contains(ConnectivityResult.mobile) &&
        !results.contains(ConnectivityResult.wifi) &&
        !results.contains(ConnectivityResult.ethernet);

    if (currentlyOffline != _isOffline) {
      setState(() {
        _isOffline = currentlyOffline;
      });

      if (_isOffline) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Check if it's already the NoInternetScreen at the top
          // Prevents pushing it multiple times if user navigates back and forth
          bool isNoInternetRoutePresent = false;
          Navigator.of(context).popUntil((route) {
            if (route.settings.name == '/noInternet') {
              isNoInternetRoutePresent = true;
              return true; // Stop popping
            }
            return true; // Keep popping
          });

          if (!isNoInternetRoutePresent) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                settings: const RouteSettings(
                  name: '/noInternet',
                ), // Set a name for detection
                builder: (context) => NoInternetScreen(
                  onRetry: () {
                    Navigator.of(context).pop(); // Pops itself on retry
                  },
                ),
              ),
              (route) => false, // Clear all routes below it
            );
          }
        });
      } else {
        // If back online, try to pop the NoInternetScreen if it's currently displayed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Navigator.of(context).canPop() &&
              ModalRoute.of(context)?.settings.name == '/noInternet') {
            Navigator.of(context).pop();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
