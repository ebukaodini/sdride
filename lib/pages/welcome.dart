import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sdride/providers/Rider.dart';
import 'package:sdride/utils/functions.dart';
import 'package:sdride/widgets/error.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  Future createRider(Rider pRider) async {
    try {
      await pRider.createRider();
    } catch (e) {
      error(context, e.toString(), seconds: 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Rider>(builder: (BuildContext context, pRider, child) {
      // create a rider
      if (pRider.rider == null) createRider(pRider);

      return Scaffold(
        backgroundColor: Colors.blue,
        body: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: screen(context).height * 0.3,
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.car_detailed,
                    size: 100,
                    color: Colors.blue.shade50,
                  ),
                  Text(
                    'SD Ride',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blue.shade50,
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: screen(context).height * 0.7,
              child: SizedBox(
                width: screen(context).width * 0.8,
                child: pRider.rider == null
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.blue.shade50,
                        ),
                      )
                    : ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.blue.shade50),
                          foregroundColor:
                              MaterialStateProperty.all(Colors.blue),
                        ),
                        onPressed: () => Navigator.pushNamed(context, '/map'),
                        child: Text('Continue'),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
