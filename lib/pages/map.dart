import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sdride/pages/directions_model.dart';
import 'package:sdride/pages/directions_repository.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:sdride/providers/Driver.dart';
import 'package:sdride/providers/Order.dart';
import 'package:sdride/providers/Rider.dart';
import 'package:sdride/utils/functions.dart';
import 'package:sdride/widgets/error.dart';
import 'package:sdride/widgets/success.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static CameraPosition? initialCameraPosition;

  GoogleMapController? _googleMapController;

  Location location = new Location();
  Directions? travelInfo;

  BitmapDescriptor? riderMarker;
  BitmapDescriptor? driverMarker;
  Marker? pickupDriverMarker;
  BitmapDescriptor? originMarker;
  BitmapDescriptor? destinationMarker;
  BitmapDescriptor? travelDriverMarker;
  Set<Marker> driverMarkers = {};

  bool isPageReady = false;

  @override
  initState() {
    super.initState();
    initPage();
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    super.dispose();
  }

  Future initPage() async {
    loadMarkers();
    await getCurrentLocation();
    setInitialCameraLocation();
    // await getChangingLocation();
    showOnlineDriversOnMap();
    setState(() => isPageReady = true);
    // await setTravelInfoForDriversOnMap();
  }

  void setInitialCameraLocation() {
    setState(() {
      initialCameraPosition = CameraPosition(
        target: travelOrigin!,
        zoom: zoomLevel!,
      );
    });
  }

  Future getChangingLocation() async {
    try {
      Rider pRider = context.read<Rider>();
      Driver pDriver = context.read<Driver>();
      location.onLocationChanged.listen((LocationData currentLocation) async {
        setState(() {
          myLocation =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });
        await pRider.updateLocation(myLocation!);

        LatLng pos = await pDriver.getLocation();
        // update the marker
        setState(() {
          pickupDriverMarker = Marker(
            markerId: MarkerId("driver_${pDriver.driver!.id!}"),
            infoWindow: const InfoWindow(title: 'Driver'),
            icon: driverMarker!,
            position: pos,
            zIndex: 999,
          );
        });

        // get travel details
        Directions direction = await getDirection(pos, myLocation);
        setState(() {
          pickupTravelInfo =
              "Driver is ${direction.totalDistance} away, Arriving in ${direction.totalDuration}.";
        });
      });
    } catch (e) {
      error(context, e.toString());
    }
  }

  Future getCurrentLocation() async {
    try {
      // enable background mode
      location.enableBackgroundMode(enable: true);

      bool _serviceEnabled;
      PermissionStatus _permissionGranted;
      LocationData _locationData;

      _serviceEnabled = await location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {
          return;
        }
      }

      _permissionGranted = await location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      _locationData = await location.getLocation();

      setState(
        () {
          myLocation =
              LatLng(_locationData.latitude!, _locationData.longitude!);
          travelOrigin = myLocation;
        },
      );

      Rider pRider = context.read<Rider>();
      await pRider.updateLocation(myLocation!);
    } catch (e) {
      error(context, "Get Location Error: " + e.toString(), seconds: 20);
    }
  }

  void loadMarkers() {
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration.empty,
      'assets/markers/rider.png',
    ).then(
      (value) => setState(() {
        riderMarker = value;
      }),
    );
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration.empty,
      'assets/markers/driver.png',
    ).then(
      (value) => setState(() {
        driverMarker = value;
      }),
    );
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration.empty,
      'assets/markers/travelDriver.png',
    ).then(
      (value) => setState(() {
        travelDriverMarker = value;
      }),
    );
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration.empty,
      'assets/markers/origin.png',
    ).then(
      (value) => setState(() {
        originMarker = value;
      }),
    );
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration.empty,
      'assets/markers/destination.png',
    ).then(
      (value) => setState(() {
        destinationMarker = value;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Rider>(builder: (BuildContext context, pRider, child) {
      return Consumer<Driver>(builder: (BuildContext context, pDriver, child) {
        return Consumer<Order>(builder: (BuildContext context, pOrder, child) {
          return Scaffold(
            body: Stack(
              alignment: Alignment.center,
              children: [
                if (isPageReady == true)
                  GoogleMap(
                    myLocationEnabled: true,
                    indoorViewEnabled: true,
                    zoomControlsEnabled: false,
                    initialCameraPosition: initialCameraPosition!,
                    onMapCreated: (controller) =>
                        _googleMapController = controller,
                    markers: {
                      ...driverMarkers,
                      if (pickupDriverMarker != null) pickupDriverMarker!,
                      if (travelInfo != null && showTravelDirection == true)
                        if (travelOriginMarker != null) travelOriginMarker!,
                      if (travelInfo != null && showTravelDirection == true)
                        if (travelDestinationMarker != null)
                          travelDestinationMarker!,
                    },
                    polylines: {
                      // travel polyline
                      if (travelInfo != null && showTravelDirection == true)
                        Polyline(
                          polylineId: const PolylineId('travel_polyline'),
                          color: Colors.blue.shade900,
                          width: 10,
                          startCap: Cap.roundCap,
                          endCap: Cap.roundCap,
                          jointType: JointType.round,
                          points: travelInfo!.polylinePoints!
                              .map((e) => LatLng(e.latitude, e.longitude))
                              .toList(),
                        ),
                    },
                  ),

                // show loading while page is loading
                if (isPageReady == false)
                  Center(
                    child: CircularProgressIndicator(),
                  ),

                if (isPageReady == true)
                  Positioned(
                    top: 50,
                    left: 20,
                    child: FloatingActionButton(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.black,
                      onPressed: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back_rounded),
                    ),
                  ),

                if (isPageReady == true)
                  // display the info distance and time estimation info
                  if (travelInfo != null && showTravelDirection == true)
                    Positioned(
                      top: 50,
                      right: 20,
                      height: 55,
                      width: screen(context).width * 0.6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 6.0,
                            )
                          ],
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            '${travelInfo!.totalDistance}, ${travelInfo!.totalDuration}',
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                DraggableScrollableSheet(
                  initialChildSize: 0.30,
                  minChildSize: 0.20,
                  maxChildSize: 0.30,
                  builder: (BuildContext context,
                      ScrollController scrollController) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      child: Container(
                        margin: EdgeInsets.only(top: 10),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade300,
                              blurRadius: 5.0,
                              spreadRadius: 5,
                              offset: Offset.zero,
                            ),
                          ],
                          color: Colors.white,
                        ),
                        child: bottomSheetPage ==
                                BottomSheetPage.SELECT_DESTINATION
                            ? showSelectDestination()
                            : bottomSheetPage == BottomSheetPage.CONFIRM_ORDER
                                ? showConfirmOrder()
                                : showPickupDriver(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        });
      });
    });
  }

  void addDriverMarker(LatLng pos, driverId) {
    try {
      setState(() {
        driverMarkers.add(
          Marker(
            markerId: MarkerId("driver_$driverId"),
            infoWindow: const InfoWindow(title: 'Driver'),
            icon: driverMarker!,
            position: pos,
          ),
        );
      });
    } catch (e) {
      error(context, e.toString());
    }
  }

  Future<Directions> getDirection(LatLng? origin, LatLng? destination) async {
    // Get directions
    Directions directions = await DirectionsRepository().getDirections(
      origin: origin,
      destination: destination,
    );

    return directions;
  }

  // Bottom Sheets
  bool showDestination = true;
  bool showDrivers = false;
  double? zoomLevel = 16;

  LatLng? myLocation;
  LatLng? travelOrigin;
  LatLng? travelDestination;
  Marker? travelOriginMarker;
  Marker? travelDestinationMarker;
  bool showTravelDirection = false;
  BottomSheetPage bottomSheetPage = BottomSheetPage.SELECT_DESTINATION;
  dynamic pickupDriver;
  LatLng? pickupDriverLocation;
  String? pickupTravelInfo = '';
  dynamic selectedDestination;

  dynamic onlineDrivers = [
    {
      'id': 12341,
      'car': 'Toyota Camry',
      'lat': 6.515163147958853,
      'lng': 3.31046249717474,
      'travelInfo': '',
      'detailedTravelInfo': ''
    },
    {
      'id': 12342,
      'car': 'Toyota Matrix',
      'lat': 6.513377004308796,
      'lng': 3.3138377219438553,
      'travelInfo': '',
      'detailedTravelInfo': ''
    },
    {
      'id': 12343,
      'car': 'Toyota Corolla',
      'lat': 6.51361151513941,
      'lng': 3.3139265701174736,
      'travelInfo': '',
      'detailedTravelInfo': ''
    },
    {
      'id': 12344,
      'car': 'Honda Accord',
      'lat': 6.51320978203025,
      'lng': 3.3138196170330048,
      'travelInfo': '',
      'detailedTravelInfo': ''
    },
    {
      'id': 12345,
      'car': 'Kia',
      'lat': 6.512523237390371,
      'lng': 3.3140774443745618,
      'travelInfo': '',
      'detailedTravelInfo': ''
    },
  ];

  void showOnlineDriversOnMap() {
    onlineDrivers.forEach((driver) {
      // parse drivers location to latlng values
      LatLng driverPos = LatLng(double.parse(driver['lat'].toString()),
          double.parse(driver['lng'].toString()));

      addDriverMarker(driverPos, driver['id']);
    });
  }

  void setPickupDriverMarker() {
    setState(() {
      driverMarkers.remove(
        driverMarkers.firstWhere(
          (marker) =>
              marker.markerId == MarkerId("driver_${pickupDriver['id']}"),
        ),
      );

      driverMarkers.add(
        Marker(
          markerId: MarkerId("driver_${pickupDriver['id']}"),
          infoWindow: const InfoWindow(title: 'Driver'),
          icon: travelDriverMarker!,
          position: LatLng(pickupDriver['lat'], pickupDriver['lng']),
        ),
      );
    });
  }

  void revertPickupDriverMarker() {
    setState(() {
      driverMarkers.remove(
        driverMarkers.firstWhere(
          (marker) =>
              marker.markerId == MarkerId("driver_${pickupDriver['id']}"),
        ),
      );

      driverMarkers.add(
        Marker(
          markerId: MarkerId("driver_${pickupDriver['id']}"),
          infoWindow: const InfoWindow(title: 'Driver'),
          icon: driverMarker!,
          position: LatLng(pickupDriver['lat'], pickupDriver['lng']),
        ),
      );
    });
  }

  Future choosePickupDriver(driver) async {
    setState(() {
      pickupDriverLocation = LatLng(driver['lat'], driver['lng']);
      pickupDriver = driver;
      bottomSheetPage = BottomSheetPage.SHOW_PICKUP_DRIVER;
    });

    // change driver marker to distinction
    setPickupDriverMarker();

    // set camera to selected driver
    _googleMapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: pickupDriverLocation!,
          zoom: 20,
        ),
      ),
    );
  }

  // Select Destination Sheet
  Widget showSelectDestination() {
    return Column(
      children: <Widget>[
        SizedBox(height: 12),
        Container(
          height: 5,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        SizedBox(height: 16),
        Text(
          "Select Destination",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 24),
        renderCustomDestinations(),
        SizedBox(height: 16),
      ],
    );
  }

  static const defaultDestinations = [
    {
      'name': 'Ikeja City Mall',
      'address': 'Obafemi Awolowo Way, Ikeja, Nigeria',
      'lat': 6.613607021590709,
      'lng': 3.3579758182168002,
    },
    {
      'name': 'Oshodi Market',
      'address': 'Oshodi Market, Oshodi, Nigeria',
      'lat': 6.553138345416473,
      'lng': 3.3369003608822823,
    },
    {
      'name': 'Chevron Drive Lekki',
      'address': 'Chevron Drive, Lekki, Nigeria',
      'lat': 6.441771477695865,
      'lng': 3.53067085146904,
    },
    {
      'name': 'Lagos State Polytechnic',
      'address': 'Lagos State Polytechnic, Isolo, Nigeria',
      'lat': 6.531149882892987,
      'lng': 3.333965353667736,
    },
  ];

  Widget renderCustomDestinations() {
    List<Widget> tiles = [];
    int count = 0;
    defaultDestinations.forEach(
      (destination) {
        tiles.add(locationTile(destination));
        if (count != defaultDestinations.length - 1) tiles.add(Divider());
        count++;
      },
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        children: tiles,
        //to avoid scrolling conflict with the dragging sheet
        physics: NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(0),
        shrinkWrap: true,
      ),
    );
  }

  ListTile locationTile(destination) {
    return ListTile(
      leading: Icon(
        Icons.pin_drop_outlined,
        color: Colors.black54,
        size: 30,
      ),
      title: Text(
        destination['name'],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 20,
          color: Colors.black54,
        ),
      ),
      subtitle: Text(
        destination['address'],
        style: TextStyle(
          fontSize: 16,
          color: Colors.black45,
        ),
      ),
      enableFeedback: true,
      onTap: () => chooseDestination(destination),
    );
  }

  Future chooseDestination(destination) async {
    try {
      setState(() {
        travelDestination = LatLng(destination['lat'], destination['lng']);
        selectedDestination = destination;
      });

      await setTravelDirection();
      addTravelMarker();

      setState(() {
        bottomSheetPage = BottomSheetPage.CONFIRM_ORDER;
      });
    } catch (e) {
      error(context, e.toString());
    }
  }

  Future setTravelDirection() async {
    try {
      // Get travel directions
      if (travelOrigin != null && travelDestination != null) {
        final directions = await DirectionsRepository().getDirections(
          origin: travelOrigin,
          destination: travelDestination,
        );

        setState(() {
          travelInfo = directions;
          showTravelDirection = true;
        });

        _googleMapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: travelDestination!,
              zoom: 12,
            ),
          ),
        );
      }
    } catch (e) {
      error(context, e.toString(), seconds: 50);
    }
  }

  void addTravelMarker() {
    setState(() {
      travelOriginMarker = Marker(
        markerId: const MarkerId('origin'),
        infoWindow: const InfoWindow(title: 'Origin'),
        icon: originMarker!,
        position: travelOrigin!,
        zIndex: 99,
      );
      travelDestinationMarker = Marker(
        markerId: const MarkerId('destination'),
        infoWindow: const InfoWindow(title: 'Destination'),
        icon: destinationMarker!,
        position: travelDestination!,
        zIndex: 99,
      );
    });
  }

  // confirm order
  Widget showConfirmOrder() {
    return Column(
      children: <Widget>[
        SizedBox(height: 12),
        Container(
          height: 5,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        SizedBox(height: 16),
        Container(
          height: 50,
          width: screen(context).width,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                left: 20,
                child: BackButton(
                  color: Colors.black54,
                  onPressed: () {
                    setState(() {
                      bottomSheetPage = BottomSheetPage.SELECT_DESTINATION;
                      travelInfo = null;
                      showTravelDirection = false;
                    });
                  },
                ),
              ),
              Positioned(
                top: 10,
                child: Text(
                  "Confirm Ride",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        ListTile(
          leading: Image.asset(
            'assets/markers/destination.png',
            fit: BoxFit.cover,
            width: 60,
          ),
          title: Text(
            "${selectedDestination['name']}",
            maxLines: 1,
            textAlign: TextAlign.start,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "${selectedDestination['address']}",
            maxLines: 1,
            textAlign: TextAlign.start,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black45,
            ),
          ),
          enableFeedback: true,
        ),
        Text(
          "Journey is ${travelInfo!.totalDistance} far and takes about ${travelInfo!.totalDuration}",
          maxLines: 2,
          overflow: TextOverflow.visible,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black45,
          ),
        ),
        SizedBox(height: 20),
        SizedBox(
          width: screen(context).width * 0.9,
          child: ElevatedButton(
            onPressed: confirmOrder,
            child: Text('Confirm Ride'),
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }

  Future confirmOrder() async {
    try {
      Order pOrder = context.read<Order>();
      Rider pRider = context.read<Rider>();
      await pOrder.createOrder(
          pRider.rider!, travelOrigin!, selectedDestination);
      success(context, 'Order created');

      setState(() {
        bottomSheetPage = BottomSheetPage.SHOW_PICKUP_DRIVER;
      });
    } catch (e) {
      error(context, e.toString());
    }
  }

  // Show Pickup Driver
  Widget showPickupDriver() {
    Order pOrder = context.read<Order>();
    return Column(
      children: <Widget>[
        SizedBox(height: 12),
        Container(
          height: 5,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        SizedBox(height: 16),
        Container(
          width: screen(context).width,
          height: 50,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Positioned(
              //   left: 20,
              //   child: BackButton(
              //     color: Colors.black54,
              //     onPressed: () {
              //       setState(() {
              //         bottomSheetPage = BottomSheetPage.SHOW_PICKUP_DRIVER;
              //         revertPickupDriverMarker();
              //       });
              //     },
              //   ),
              // ),
              Positioned(
                top: 10,
                child: Text(
                  "Pickup Driver",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        if (pOrder.order!.isPending == true) awaitingDriver(),
        if (pOrder.order!.isAccepted == true) ...driverDetails(),
        SizedBox(height: 30),
      ],
    );
  }

  List<Widget> driverDetails() {
    Driver pDriver = context.read<Driver>();
    return [
      ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Image.asset(
              'assets/markers/travelDriver.png',
              fit: BoxFit.cover,
              width: 60,
            ),
            Column(
              children: [
                Text(
                  pDriver.driver!.name!,
                  maxLines: 1,
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  pDriver.driver!.car!,
                  maxLines: 1,
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          ],
        ),
        enableFeedback: true,
      ),
      SizedBox(height: 16),
      Text(
        pickupTravelInfo!,
        maxLines: 2,
        overflow: TextOverflow.visible,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: Colors.black45,
        ),
      ),
    ];
  }

  Widget awaitingDriver() {
    Order pOrder = context.read<Order>();
    Driver pDriver = context.read<Driver>();
    return Container(
      width: screen(context).width * 0.9,
      child: Column(
        children: [
          Text('Fetching your driver...'),
          Text('Click to reload'),
          SizedBox(height: 20),
          SizedBox(
            width: screen(context).width * 0.9,
            child: ElevatedButton(
              onPressed: () async {
                bool status = await pOrder.isOrderAccepted(pDriver);

                if (status == true) {
                  // get the distance / destination details
                  Directions direction =
                      await getDirection(pDriver.driver!.location!, myLocation);
                  setState(() {
                    pickupTravelInfo =
                        "Driver is ${direction.totalDistance} away, Arriving in ${direction.totalDuration}.";
                    pOrder.order?.isPending = false;
                    pOrder.order?.isAccepted = true;
                  });
                }

                pickupDriverMarker = Marker(
                  markerId: MarkerId("driver_${pDriver.driver?.id}"),
                  infoWindow: const InfoWindow(title: 'Pickup Driver'),
                  icon: travelDriverMarker!,
                  position: pDriver.driver!.location!,
                  zIndex: 999,
                );

                // set camera to selected driver
                _googleMapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: pDriver.driver!.location!,
                      zoom: 20,
                    ),
                  ),
                );
              },
              child: Text('Reload'),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // Select Driver Sheet
  Widget selectPickupDriver() {
    return Column(
      children: <Widget>[
        SizedBox(height: 12),
        Container(
          height: 5,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        SizedBox(height: 16),
        Container(
          height: 50,
          width: screen(context).width,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                left: 20,
                child: BackButton(
                  color: Colors.black54,
                  onPressed: () {
                    setState(() {
                      bottomSheetPage = BottomSheetPage.SELECT_DESTINATION;
                      travelInfo = null;
                      showTravelDirection = false;
                    });
                  },
                ),
              ),
              Positioned(
                top: 10,
                child: Text(
                  "Select Pickup Driver",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        renderCustomDrivers(),
        SizedBox(height: 16),
      ],
    );
  }

  Future setTravelInfoForDriversOnMap() async {
    int count = 0;
    onlineDrivers.forEach((driver) async {
      // parse drivers location to latlng values
      LatLng driverPos = LatLng(double.parse(driver['lat'].toString()),
          double.parse(driver['lng'].toString()));

      // get the distance / destination details
      Directions direction = await getDirection(driverPos, travelOrigin);
      onlineDrivers[count]['travelInfo'] =
          "${direction.totalDistance}, ${direction.totalDuration}";
      onlineDrivers[count]['detailedTravelInfo'] =
          "Driver is ${direction.totalDistance} away, Arriving in ${direction.totalDuration}.";

      count++;
    });
  }

  Widget renderCustomDrivers() {
    List<Widget> tiles = [];
    int count = 0;
    onlineDrivers.forEach(
      (element) {
        tiles.add(driverTile(element));
        if (count != onlineDrivers.length - 1) tiles.add(Divider());
        count++;
      },
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        children: tiles,
        //to avoid scrolling conflict with the dragging sheet
        physics: NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(0),
        shrinkWrap: true,
      ),
    );
  }

  ListTile driverTile(driver) {
    return ListTile(
      leading: Image.asset(
        'assets/markers/driver.png',
        fit: BoxFit.cover,
        width: 60,
      ),
      title: Text(
        driver['car'],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 20,
          color: Colors.black54,
        ),
      ),
      subtitle: Text(
        driver['travelInfo'],
        style: TextStyle(
          fontSize: 16,
          color: Colors.black45,
        ),
      ),
      enableFeedback: true,
      onTap: () => choosePickupDriver(driver),
    );
  }
}

enum BottomSheetPage {
  SELECT_DESTINATION,
  CONFIRM_ORDER,
  SHOW_PICKUP_DRIVER,
}
