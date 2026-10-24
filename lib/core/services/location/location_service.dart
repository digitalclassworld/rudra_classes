import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      );
}

class LocationService {
  static const String _apiEndpoint = 'https://rudraclasses.in/api/save_user_location';

  /// Request permissions, fetch device GPS position & info, and upload to server
  static Future<LocationModel?> captureAndSyncLocation() async {
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
            place.postalCode
          ].where((s) => s != null && s.isNotEmpty).join(', ');
        }
      } catch (e) {
        debugPrint('[LocationService] Reverse geocode error: $e');
      }

      // Get Device Info
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

      // Package / App Version
      String appVersion = '1.0.0';
      try {
        PackageInfo pkg = await PackageInfo.fromPlatform();
        appVersion = '${pkg.version}+${pkg.buildNumber}';
      } catch (_) {}

      final locModel = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        state: state,
        country: country,
        address: fullAddress,
        deviceModel: deviceModel,
        deviceOS: '$deviceOS (App v$appVersion)',
        timestamp: DateTime.now().toIso8601String(),
      );

      debugPrint('''
╔════════════════════════════════════════════════════════════════╗
║ 📍 APP LOCATION CAPTURED SUCCESSFULLY                          ║
╠════════════════════════════════════════════════════════════════╣
║ City        : ${locModel.city.isNotEmpty ? locModel.city : 'N/A'}, ${locModel.state}
║ Coordinates : ${locModel.latitude}, ${locModel.longitude}
║ Address     : ${locModel.address.isNotEmpty ? locModel.address : 'N/A'}
║ Device      : ${locModel.deviceModel} (${locModel.deviceOS})
║ Timestamp   : ${locModel.timestamp}
╚════════════════════════════════════════════════════════════════╝''');

      // Save locally
      await _saveLocally(locModel);

      // Sync to backend asynchronously (fire and forget / handled gracefully)
      _syncToBackend(locModel);

      return locModel;
    } catch (e) {
      debugPrint('[LocationService] captureAndSyncLocation error: $e');
      return null;
    }
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
      debugPrint('[LocationService] Backend sync response: ${response.statusCode}');
    } catch (e) {
      debugPrint('[LocationService] Failed to sync location to backend: $e');
    }
  }
}
