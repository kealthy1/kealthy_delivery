import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:kealthy_delivery/Pages/LandingPages/SearchOrders.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Pages/LandingPages/OrderList.dart';
import '../Pages/Login/login_page.dart';

class OrderStatusChecker {
  final DatabaseReference databaseRef;

  OrderStatusChecker(this.databaseRef);

Future<void> checkOrderStatus(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final id = prefs.getString('ID');

  if (id != null) {
    final ordersRef = databaseRef.child('orders');
    final snapshot = await ordersRef.orderByChild('assignedto').equalTo(id).get();

    if (snapshot.exists && snapshot.children.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        CupertinoModalPopupRoute(
          builder: (context) => const OrdersAssignedPage(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        CupertinoModalPopupRoute(
          builder: (context) => const OnlinePage(),
        ),
      );
    }
  } else {
    Navigator.pushReplacement(
      context,
      CupertinoModalPopupRoute(
        builder: (context) => const LoginFields(),
      ),
    );
  }
}

}
