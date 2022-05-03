import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sdride/models/rider.model.dart';
import 'package:sdride/utils/request.dart';

class Rider extends ChangeNotifier {
  RiderModel? rider;

  Future createRider() async {
    try {
      dynamic response = await new Request().post('/api/riders/create');
      rider = RiderModel.fromMap(response['data']);

      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future updateLocation(LatLng location) async {
    try {
      await new Request().post('/api/riders/update/location', body: {
        'lat': location.latitude,
        'lng': location.longitude,
        'id': rider!.id
      });

      rider?.location = location;
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future getLocation() async {
    try {
      dynamic response =
          await new Request().get('/api/riders/${rider?.id}/location');
      dynamic location = response['data']['location'];
      rider?.location = LatLng(location['lat'], location['lng']);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }
}
