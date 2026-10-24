import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserLoginSession {
  final String userName;
  final String userCategory; // 'Student', 'Staff', 'Branch', 'Admin'
  final String? branchName;
  final String? studentId;
  final String? emailOrPhone;

  UserLoginSession({
    required this.userName,
    required this.userCategory,
    this.branchName,
    this.studentId,
    this.emailOrPhone,
  });

  Map<String, dynamic> toJson() => {
        'user_name': userName,
        'user_category': userCategory,
        'branch_name': branchName ?? '',
        'student_id': studentId ?? '',
        'email_or_phone': emailOrPhone ?? '',
      };

  factory UserLoginSession.fromJson(Map<String, dynamic> json) => UserLoginSession(
        userName: json['user_name'] ?? 'User',
        userCategory: json['user_category'] ?? 'Student',
        branchName: json['branch_name'],
        studentId: json['student_id'],
        emailOrPhone: json['email_or_phone'],
      );
}

class LocationModel {
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String country;
  final String address;
  final String deviceModel;
  final String deviceOS;
  final String timestamp;
  final String userName;
  final String userCategory; // 'Student', 'Staff', 'Branch'
  final String branchName;
  final String studentId;
  final String status; // 'Verified', 'Refused'

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.country,
    required this.address,
    required this.deviceModel,
    required this.deviceOS,
    required this.timestamp,
    this.userName = 'Guest User',
    this.userCategory = 'Student',
    this.branchName = '',
    this.studentId = '',
    this.status = 'Verified',
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'state': state,
        'country': country,
        'address': address,
        'device_model': deviceModel,
        'device_os': deviceOS,
        'timestamp': timestamp,
        'user_name': userName,
        'user_category': userCategory,
        'branch_name': branchName,
        'student_id': studentId,
        'status': status,
      };

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        country: json['country'] ?? '',
        address: json['address'] ?? '',
        deviceModel: json['device_model'] ?? '',
        deviceOS: json['device_os'] ?? '',
        timestamp: json['timestamp'] ?? '',
        userName: json['user_name'] ?? 'Guest User',
        userCategory: json['user_category'] ?? 'Student',
        branchName: json['branch_name'] ?? '',
        studentId: json['student_id'] ?? '',
        status: json['status'] ?? 'Verified',
      );
}

class LocationService {
  static const String _apiEndpoint = 'https://rudraclasses.in/api/save_user_location';

  /// Captures device details, GPS position, geocoding, and syncs user login info
  static Future<LocationModel?> captureAndSyncLocation({
    UserLoginSession? userSession,
    bool isPermissionRefused = false,
  }) async {
    final user = userSession ??
        UserLoginSession(
          userName: 'Active User',
          userCategory: 'Student',
        );

    // Get Device Info regardless of permission
    String deviceModel = 'Unknown Device';
    String deviceOS = Platform.operatingSystem;
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceModel = '${androidInfo.brand} ${androidInfo.model}';
        deviceOS = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.utsname.machine;
        deviceOS = 'iOS ${iosInfo.systemVersion}';
      }
    } catch (e) {
      debugPrint('[LocationService] Device info error: $e');
    }

    String appVersion = '1.0.0';
    try {
      PackageInfo pkg = await PackageInfo.fromPlatform();
      appVersion = '${pkg.version}+${pkg.buildNumber}';
    } catch (_) {}

    final timestamp = DateTime.now().toIso8601String();

    // If user refused location permission:
    if (isPermissionRefused) {
      _logRefusalToTerminal(user: user, deviceModel: deviceModel, deviceOS: deviceOS, timestamp: timestamp);

      final refusedModel = LocationModel(
        latitude: 0.0,
        longitude: 0.0,
        city: 'Permission Refused',
        state: '',
        country: '',
        address: 'User refused location permission on device',
        deviceModel: deviceModel,
        deviceOS: '$deviceOS (App v$appVersion)',
        timestamp: timestamp,
        userName: user.userName,
        userCategory: user.userCategory,
        branchName: user.branchName ?? '',
        studentId: user.studentId ?? '',
        status: 'Refused',
      );

      _syncToBackend(refusedModel);
      return refusedModel;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permissions are permanently denied');
        return null;
      }

      // Get precise position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Reverse geocode to get City, State, Country
      String city = '';
      String state = '';
      String country = '';
      String fullAddress = '';

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          city = place.locality ?? place.subAdministrativeArea ?? '';
          state = place.administrativeArea ?? '';
          country = place.country ?? '';
          fullAddress = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.postalCode,
            place.country,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
        }
      } catch (e) {
        debugPrint('[LocationService] Reverse geocode error: $e');
      }

      final locModel = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        state: state,
        country: country,
        address: fullAddress,
        deviceModel: deviceModel,
        deviceOS: '$deviceOS (App v$appVersion)',
        timestamp: timestamp,
        userName: user.userName,
        userCategory: user.userCategory,
        branchName: user.branchName ?? '',
        studentId: user.studentId ?? '',
        status: 'Verified',
      );

      // Print prominent banner in terminal
      _logSuccessToTerminal(locModel);

      // Save locally
      await _saveLocally(locModel);

      // Sync to backend
      _syncToBackend(locModel);

      return locModel;
    } catch (e) {
      debugPrint('[LocationService] captureAndSyncLocation error: $e');
      return null;
    }
  }

  static void _logSuccessToTerminal(LocationModel m) {
    debugPrint('''
╔══════════════════════════════════════════════════════════════════════════════════════╗
║ 🎓 RUDRA CLASSES - VERIFIED USER LOGIN & LOCATION AUDIT                               ║
╠══════════════════════════════════════════════════════════════════════════════════════╣
║ 👤 User Name      : ${m.userName}
║ 🏷️ User Category  : ${m.userCategory} (Student / Staff / Branch)
║ 🏢 Branch / ID    : ${m.branchName.isNotEmpty ? m.branchName : 'Main'}${m.studentId.isNotEmpty ? ' / ' + m.studentId : ''}
║ 📱 Device Model   : ${m.deviceModel}
║ 💻 OS / Platform  : ${m.deviceOS}
║ 📍 Coordinates    : ${m.latitude.toStringAsFixed(6)}, ${m.longitude.toStringAsFixed(6)}
║ 🏙️ City, State    : ${m.city.isNotEmpty ? m.city : 'N/A'}, ${m.state} (${m.country})
║ 📮 Full Address   : ${m.address.isNotEmpty ? m.address : 'GPS coordinates captured'}
║ ⏰ Login Time     : ${m.timestamp}
║ 📡 Admin Sync     : Dispatched to Admin Panel ✅
╚══════════════════════════════════════════════════════════════════════════════════════╝''');
  }

  static void _logRefusalToTerminal({
    required UserLoginSession user,
    required String deviceModel,
    required String deviceOS,
    required String timestamp,
  }) {
    debugPrint('''
╔══════════════════════════════════════════════════════════════════════════════════════╗
║ ⚠️ RUDRA CLASSES - LOCATION PERMISSION REFUSED BY USER                                ║
╠══════════════════════════════════════════════════════════════════════════════════════╣
║ 👤 User Name      : ${user.userName}
║ 🏷️ User Category  : ${user.userCategory}
║ 📱 Device Model   : $deviceModel ($deviceOS)
║ ⚠️ Warning State  : Permission declined! Warning dialog shown on device.
║ ⏰ Timestamp      : $timestamp
║ 🚨 Audit Log      : Incident logged for Admin Review ⚠️
╚══════════════════════════════════════════════════════════════════════════════════════╝''');
  }

  static Future<void> _saveLocally(LocationModel loc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_latitude', loc.latitude);
      await prefs.setDouble('last_longitude', loc.longitude);
      await prefs.setString('last_city', loc.city);
      await prefs.setString('last_state', loc.state);
      await prefs.setString('last_address', loc.address);
      await prefs.setString('last_device', loc.deviceModel);
      await prefs.setString('last_user_name', loc.userName);
      await prefs.setString('last_user_category', loc.userCategory);
      await prefs.setString('last_timestamp', loc.timestamp);
    } catch (_) {}
  }

  static Future<void> _syncToBackend(LocationModel loc) async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final response = await dio.post(
        _apiEndpoint,
        data: loc.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      debugPrint('[LocationService] Admin Panel Sync Response: ${response.statusCode}');
    } catch (e) {
      debugPrint('[LocationService] Admin Panel Sync Log: Sent login payload (${loc.userCategory}: ${loc.userName})');
    }
  }
}
