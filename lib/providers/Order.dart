import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sdride/models/driver.model.dart';
import 'package:sdride/models/order.model.dart';
import 'package:sdride/models/rider.model.dart';
import 'package:sdride/providers/Driver.dart';
import 'package:sdride/utils/request.dart';

class Order extends ChangeNotifier {
  OrderModel? order;

  Future createOrder(
      RiderModel rider, LatLng origin, Map<String, Object> destination) async {
    try {
      dynamic response = await new Request().post('/api/orders/create', body: {
        'id': rider.id,
        'originLat': origin.latitude,
        'originLng': origin.longitude,
        'destLat': destination['lat'],
        'destLng': destination['lng'],
        'destName': destination['name'],
        'destAddress': destination['address'],
      });

      order = OrderModel.fromMap(response['data']['order']);

      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future isOrderAccepted(Driver pDriver) async {
    try {
      dynamic response =
          await new Request().get('/api/orders/${order?.id}/status/accepted');

      if (response['data']['accepted'] == true) {
        // order?.isPending = false;
        // order?.isAccepted = true;
        order?.driverId = response['data']['driver']['_id'];
        pDriver.driver = DriverModel.fromMap(response['data']['driver']);
      }

      notifyListeners();
      return response['data']['accepted'];
    } catch (e) {
      throw e;
    }
  }
}
