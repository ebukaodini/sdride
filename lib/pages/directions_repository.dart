import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sdride/pages/directions_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsRepository {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json?';

  final Dio _dio;

  DirectionsRepository({Dio? dio}) : _dio = dio ?? Dio();

  Future<Directions> getDirections({
    @required LatLng? origin,
    @required LatLng? destination,
  }) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'origin': '${origin!.latitude},${origin.longitude}',
          'destination': '${destination!.latitude},${destination.longitude}',
          'key': dotenv.env['GOOGLE_API_KEY'],
        },
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        return Directions.fromMap(response.data);
      } else {
        throw new Exception(response.statusMessage);
      }
    } catch (e) {
      throw e;
    }
  }
}
