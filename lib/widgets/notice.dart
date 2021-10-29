import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sdride_sample/utils/functions.dart';

void notice(BuildContext context, String msg) {
  FToast ftoast = FToast();
  ftoast.init(context);
  ftoast.showToast(
    gravity: ToastGravity.BOTTOM,
    toastDuration: Duration(seconds: 5),
    child: Container(
      width: screen(context).width * 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.blue,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.white,
          ),
          SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  // Fluttertoast.showToast(
  //   msg: msg,
  //   toastLength: Toast.LENGTH_LONG,
  //   gravity: ToastGravity.CENTER,
  //   timeInSecForIosWeb: 5,
  //   backgroundColor: Colors.blue,
  //   textColor: Colors.white,
  // );
}
