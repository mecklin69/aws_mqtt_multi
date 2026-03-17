import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationData {
  final Position position;
  final String locationName;

  LocationData(this.position, this.locationName);
}

class LocationService {

  static Future<LocationData> loadLocation() async {
    final position = await _determinePosition();
    final locationName =
    await getLocationName(position.latitude, position.longitude);

    return LocationData(position, locationName);
  }

  static Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  static Future<String> getLocationName(double lat, double lon) async {
    try {
      final url = Uri.parse(
          "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=10&addressdetails=1");

      final response = await http.get(
        url,
        headers: {"User-Agent": "FlutterApp"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final address = data["address"];

        String city =
            address["city"] ??
                address["town"] ??
                address["village"] ??
                "";

        String state = address["state"] ?? "";
        String country = address["country"] ?? "";

        return "$city, $state, $country";
      }

      return "Unknown Location";
    } catch (e) {
      return "Location Lookup Failed";
    }
  }
}