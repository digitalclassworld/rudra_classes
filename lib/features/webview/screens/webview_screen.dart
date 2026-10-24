import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/location/location_service.dart';

class MainWebViewScreen extends StatefulWidget {
  const MainWebViewScreen({super.key});

  @override
  State<MainWebViewScreen> createState() => _MainWebViewScreenState();
}

class _MainWebViewScreenState extends State<MainWebViewScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  LocationModel? _currentLocation;
  UserLoginSession? _currentSession;
  bool _hasPromptedThisSession = false;

  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone; geolocation",
    iframeAllowFullscreen: true,
    useOnDownloadStart: true,
    useShouldOverrideUrlLoading: true,
    allowFileAccessFromFileURLs: true,
    allowUniversalAccessFromFileURLs: true,
    geolocationEnabled: true,
  );

  bool _isLoading = true;
  final String url = "https://rudraclasses.in/admin/login";

  @override
  void initState() {
    super.initState();
    // Default session until webview detects specific user
    _currentSession = UserLoginSession(
      userName: 'Portal User',
      userCategory: 'Student',
      branchName: 'Main Campus',
    );
  }

  /// Show the Location Permission Popup Dialog when Student, Staff, or Branch logs in
  Future<void> _showLocationPermissionDialog(UserLoginSession user) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0052CC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on, color: Color(0xFF0052CC), size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Location Verification",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(user.userCategory).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "CATEGORY: ${user.userCategory.toUpperCase()}",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getCategoryColor(user.userCategory),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Welcome, ${user.userName}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                "For attendance verification and secure ${user.userCategory} login at Rudra Classes, please allow access to your device location.",
                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _handlePermissionRefused(user);
              },
              child: const Text(
                "Decline / Refuse",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052CC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _handlePermissionGranted(user);
              },
              child: const Text("Allow Location"),
            ),
          ],
        );
      },
    );
  }

  /// Show Warning Dialog when the user refuses location permission
  Future<void> _showLocationWarningDialog(UserLoginSession user) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFFFFBEB), // Soft warning background
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Warning: Access Denied",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF78350F)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Location verification is mandatory for all ${user.userCategory} logins.",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
              ),
              const SizedBox(height: 8),
              Text(
                "Because you refused location permission, your attendance cannot be auto-verified and your session has been logged in the Admin Panel as unverified.",
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF78350F), height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Acknowledge Warning", style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052CC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _showLocationPermissionDialog(user);
              },
              child: const Text("Grant Permission"),
            ),
          ],
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'staff':
      case 'teacher':
        return Colors.purple;
      case 'branch':
        return Colors.teal;
      case 'admin':
        return Colors.red;
      case 'student':
      default:
        return const Color(0xFF0052CC);
    }
  }

  Future<void> _handlePermissionGranted(UserLoginSession user) async {
    final loc = await LocationService.captureAndSyncLocation(userSession: user);
    if (mounted && loc != null) {
      setState(() {
        _currentLocation = loc;
        _currentSession = user;
      });
      await _injectLocationToWebView();
      Get.snackbar(
        "Location Verified ✅",
        "Logged in as ${user.userCategory} (${user.userName}) from ${loc.city}",
        backgroundColor: const Color(0xFF0052CC),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _handlePermissionRefused(UserLoginSession user) async {
    await LocationService.captureAndSyncLocation(
      userSession: user,
      isPermissionRefused: true,
    );
    await _showLocationWarningDialog(user);
  }

  void _onLoginDetected(UserLoginSession session) {
    if (_hasPromptedThisSession && _currentSession?.userName == session.userName) {
      return;
    }
    _hasPromptedThisSession = true;
    _currentSession = session;
    _showLocationPermissionDialog(session);
  }

  Future<void> _injectLocationToWebView() async {
    if (webViewController != null && _currentLocation != null) {
      final safeAddress = _currentLocation!.address
          .replaceAll('"', '\\"')
          .replaceAll('\n', ' ')
          .replaceAll('\r', '');
      final js = """
        window.flutterAppLocation = {
          userName: "${_currentLocation!.userName}",
          userCategory: "${_currentLocation!.userCategory}",
          branch: "${_currentLocation!.branchName}",
          latitude: ${_currentLocation!.latitude},
          longitude: ${_currentLocation!.longitude},
          city: "${_currentLocation!.city}",
          state: "${_currentLocation!.state}",
          address: "$safeAddress",
          device: "${_currentLocation!.deviceModel}",
          timestamp: "${_currentLocation!.timestamp}"
        };
        window.dispatchEvent(new CustomEvent('appLocationReady', { detail: window.flutterAppLocation }));
        console.log("🌐 [LOCATION BRIDGE] Active session: " + JSON.stringify(window.flutterAppLocation));
      """;
      await webViewController!.evaluateJavascript(source: js);
    }
  }

  void _showLocationInfoSheet() {
    final user = _currentSession ??
        UserLoginSession(userName: 'Portal User', userCategory: 'Student');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "📍 Verified Login & Location",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0052CC),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              const Divider(),
              // User and Category Banner
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: _getCategoryColor(user.userCategory),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  user.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text("Role / Category: ${user.userCategory} (${user.branchName ?? 'Main'})"),
              ),
              if (_currentLocation != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_city, color: Colors.blueAccent),
                  title: Text(
                    _currentLocation!.city.isNotEmpty
                        ? "${_currentLocation!.city}, ${_currentLocation!.state}"
                        : "Coordinates captured",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(_currentLocation!.address.isNotEmpty
                      ? _currentLocation!.address
                      : "${_currentLocation!.latitude}, ${_currentLocation!.longitude}"),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_android, color: Colors.green),
                  title: Text(_currentLocation!.deviceModel),
                  subtitle: Text(_currentLocation!.deviceOS),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052CC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final mapUri = Uri.parse(
                        "https://www.google.com/maps/search/?api=1&query=${_currentLocation!.latitude},${_currentLocation!.longitude}",
                      );
                      if (await canLaunchUrl(mapUri)) {
                        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.map),
                    label: const Text("View on Google Maps"),
                  ),
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text("Location not captured yet. Click a test role below to verify:"),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                "🧪 TEST AUDIT LOGS (Simulate Roles):",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _onLoginDetected(UserLoginSession(
                          userName: 'Aarav Patel (STU-104)',
                          userCategory: 'Student',
                          branchName: 'Main Branch',
                        ));
                      },
                      child: const Text("Student", style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _onLoginDetected(UserLoginSession(
                          userName: 'Prof. Sharma',
                          userCategory: 'Staff',
                          branchName: 'Science Dept',
                        ));
                      },
                      child: const Text("Staff", style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _onLoginDetected(UserLoginSession(
                          userName: 'Rudra Classes Surat',
                          userCategory: 'Branch',
                          branchName: 'Surat Central',
                        ));
                      },
                      child: const Text("Branch", style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (webViewController != null && await webViewController!.canGoBack()) {
          await webViewController!.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: true,
          bottom: true,
          left: true,
          right: true,
          child: Stack(
            children: [
              InAppWebView(
                key: webViewKey,
                initialUrlRequest: URLRequest(url: WebUri(url)),
                initialSettings: settings,
                onWebViewCreated: (controller) {
                  webViewController = controller;

                  // Register JavaScript handler to receive login events from WebView
                  controller.addJavaScriptHandler(
                    handlerName: 'onUserLoginDetected',
                    callback: (args) {
                      if (args.isNotEmpty) {
                        try {
                          final data = args[0] is Map ? args[0] as Map : {};
                          final userName = data['userName']?.toString() ?? 'Portal User';
                          final category = data['userCategory']?.toString() ?? 'Student';
                          final branch = data['branch']?.toString() ?? 'Main';

                          final session = UserLoginSession(
                            userName: userName,
                            userCategory: category,
                            branchName: branch,
                          );
                          _onLoginDetected(session);
                        } catch (e) {
                          debugPrint("Error parsing login event: $e");
                        }
                      }
                    },
                  );
                },
                onGeolocationPermissionsShowPrompt: (controller, origin) async {
                  return GeolocationPermissionShowPromptResponse(
                    origin: origin,
                    allow: true,
                    retain: true,
                  );
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    _isLoading = true;
                  });
                },
                onLoadStop: (controller, url) async {
                  setState(() {
                    _isLoading = false;
                  });
                  await _injectLocationToWebView();

                  // Inject login observer into the portal
                  final observerJs = """
                    (function() {
                      function checkAndReportLogin() {
                        try {
                          var userField = document.querySelector('input[type="text"], input[type="email"], input[name*="user"], input[name*="email"], input[name*="login"]');
                          var roleSelect = document.querySelector('select[name*="role"], select[name*="type"], select[name*="category"]');
                          
                          var uname = userField ? userField.value : '';
                          var ucat = roleSelect ? roleSelect.value : '';
                          
                          var path = window.location.pathname.toLowerCase();
                          if (path.indexOf('student') !== -1) {
                            ucat = ucat || 'Student';
                          } else if (path.indexOf('staff') !== -1 || path.indexOf('teacher') !== -1) {
                            ucat = ucat || 'Staff';
                          } else if (path.indexOf('branch') !== -1) {
                            ucat = ucat || 'Branch';
                          } else if (path.indexOf('admin') !== -1) {
                            ucat = ucat || 'Staff';
                          }

                          var profileText = document.querySelector('.user-name, .profile-name, .username, h4.name, span.name');
                          if (profileText && profileText.innerText.trim()) {
                            uname = profileText.innerText.trim();
                          }

                          if (!uname && path.indexOf('login') === -1) {
                            uname = 'Rudra User';
                          }

                          ucat = ucat || 'Student';

                          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                            window.flutter_inappwebview.callHandler('onUserLoginDetected', {
                              userName: uname || 'Portal User',
                              userCategory: ucat,
                              branch: 'Rudra Classes'
                            });
                          }
                        } catch(err) {
                          console.log('Login detection: ' + err);
                        }
                      }

                      // Hook submit buttons
                      var submitButtons = document.querySelectorAll('button[type="submit"], input[type="submit"], .btn-login, #loginBtn, form');
                      submitButtons.forEach(function(el) {
                        el.addEventListener('click', function() {
                          setTimeout(checkAndReportLogin, 800);
                        });
                        el.addEventListener('submit', function() {
                          setTimeout(checkAndReportLogin, 800);
                        });
                      });

                      // Also inspect page if not on login page
                      if (window.location.pathname.indexOf('login') === -1) {
                        setTimeout(checkAndReportLogin, 1200);
                      }
                    })();
                  """;
                  await controller.evaluateJavascript(source: observerJs);
                },
                onDownloadStartRequest: (controller, downloadStartRequest) async {
                  final uri = Uri.parse(downloadStartRequest.url.toString());
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  var uri = navigationAction.request.url!;
                  if (uri.toString().endsWith('.pdf') ||
                      uri.toString().endsWith('.zip') ||
                      uri.toString().contains('download') ||
                      uri.toString().contains('receipt') ||
                      uri.toString().contains('track') ||
                      (!uri.toString().contains('rudraclasses.in') &&
                          !uri.toString().contains('about:blank'))) {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                      return NavigationActionPolicy.CANCEL;
                    }
                  }
                  return NavigationActionPolicy.ALLOW;
                },
                onReceivedError: (controller, request, error) {
                  Get.snackbar(
                    "Error",
                    "Failed to load page: ${error.description}",
                  );
                },
                onConsoleMessage: (controller, consoleMessage) {
                  debugPrint("🖥️ [WEBVIEW CONSOLE]: ${consoleMessage.message}");
                },
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0052CC)),
                ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.small(
          backgroundColor: const Color(0xFF0052CC),
          foregroundColor: Colors.white,
          tooltip: "Location & Role Verification",
          onPressed: _showLocationInfoSheet,
          child: const Icon(Icons.my_location, size: 20),
        ),
      ),
    );
  }
}
