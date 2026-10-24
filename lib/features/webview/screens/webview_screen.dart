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
    geolocationEnabled: true, // Enables HTML5 geolocation in WebView
  );

  bool _isLoading = true;
  final String url = "https://rudraclasses.in/admin/login";

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final loc = await LocationService.captureAndSyncLocation();
    if (mounted && loc != null) {
      setState(() {
        _currentLocation = loc;
      });
      _injectLocationToWebView();
    }
  }

  Future<void> _injectLocationToWebView() async {
    if (webViewController != null && _currentLocation != null) {
      final safeAddress = _currentLocation!.address
          .replaceAll('"', '\\"')
          .replaceAll('\n', ' ')
          .replaceAll('\r', '');
      final js = """
        window.flutterAppLocation = {
          latitude: ${_currentLocation!.latitude},
          longitude: ${_currentLocation!.longitude},
          city: "${_currentLocation!.city}",
          state: "${_currentLocation!.state}",
          address: "$safeAddress",
          device: "${_currentLocation!.deviceModel}",
          timestamp: "${_currentLocation!.timestamp}"
        };
        window.dispatchEvent(new CustomEvent('appLocationReady', { detail: window.flutterAppLocation }));
        console.log("🌐 [LOCATION BRIDGE] window.flutterAppLocation is active: " + JSON.stringify(window.flutterAppLocation));
      """;
      await webViewController!.evaluateJavascript(source: js);
      debugPrint("🚀 [Bridge] Injected window.flutterAppLocation: ${_currentLocation!.city} (${_currentLocation!.latitude}, ${_currentLocation!.longitude})");
    }
  }

  void _showLocationInfoSheet() {
    if (_currentLocation == null) {
      Get.snackbar(
        "Location",
        "Fetching GPS location...",
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
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
                    "📍 App Location Details",
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_city, color: Colors.blueAccent),
                title: Text(
                  _currentLocation!.city.isNotEmpty
                      ? "${_currentLocation!.city}, ${_currentLocation!.state}"
                      : "GPS Coordinates",
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
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                },
                // Handle HTML5 Geolocation prompt automatically inside the app
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
                },
                onPrintRequest: (controller, url, printJobController) async {
                  return false;
                },
                onDownloadStartRequest: (
                  controller,
                  downloadStartRequest,
                ) async {
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
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
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
        floatingActionButton: _currentLocation != null
            ? FloatingActionButton.small(
                backgroundColor: const Color(0xFF0052CC),
                foregroundColor: Colors.white,
                tooltip: "View Location Info",
                onPressed: _showLocationInfoSheet,
                child: const Icon(Icons.my_location, size: 20),
              )
            : null,
      ),
    );
  }
}
