import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy_delivery/Pages/Order/MyOrders.dart';
import 'package:kealthy_delivery/Riverpod/Loading.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'OrderList.dart';
import '../../Riverpod/NavigationProvider.dart';
import '../../Riverpod/OnlineToggleprovider.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

final assignedOrderProvider = StateProvider<Order?>((ref) => null);

class OnlinePage extends ConsumerWidget {
  const OnlinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationProvider);
    final locationState = ref.watch(locationProvider);
    _listenForOrderAssignment(context);
    // final RequestOverlay requestOverlay = RequestOverlay();

    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   leadingWidth: MediaQuery.of(context).size.width,
      //   // leading: Padding(
      //   //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
      //   //   child: Row(
      //   //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //   //     children: [
      //   //       FlutterSwitch(
      //   //         value: locationState.isOnline,
      //   //         onToggle: (val) async {
      //   //           try {
      //   //             if (!locationState.isOnline) {
      //   //               requestOverlay.startBubble(
      //   //                 BubbleOptions(
      //   //                   bubbleIcon: "bubble",
      //   //                   bubbleSize: 40,
      //   //                   enableClose: false,
      //   //                   distanceToClose: 90,
      //   //                   enableAnimateToEdge: true,
      //   //                   enableBottomShadow: true,
      //   //                   keepAliveWhenAppExit: false,
      //   //                 ),
      //   //                 onTap: () {
      //   //                   requestOverlay.logMessage(message: "Bubble Tapped");
      //   //                 },
      //   //               );
      //   //             } else {
      //   //               await requestOverlay.stopBubble();
      //   //             }
      //   //             await ref
      //   //                 .read(locationProvider.notifier)
      //   //                 .toggleOnlineStatus();
      //   //           } catch (e) {
      //   //             _showOutsideZoneBottomSheet(context, e.toString());
      //   //           }
      //   //         },
      //   //         activeText: 'Online',
      //   //         inactiveText: 'Offline',
      //   //         activeColor: const Color(0xFF273847),
      //   //         inactiveColor: Colors.red,
      //   //         width: 100.0,
      //   //         height: 40.0,
      //   //         toggleSize: 30.0,
      //   //         borderRadius: 30.0,
      //   //         showOnOff: true,
      //   //       ),
      //   //     ],
      //   //   ),
      //   // ),
      // ),
      body: _getSelectedPage(selectedIndex, context, locationState),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (locationState.isOnline)
            Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Searching for Orders...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  LoadingAnimationWidget.hexagonDots(
                    color: const Color(0xFF273847),
                    size: 40,
                  ),
                ],
              ),
            ),
          const SizedBox(
            height: 10,
          ),
          ConvexAppBar(
            items: const [
              TabItem(icon: Icons.home, title: 'Home'),
              TabItem(icon: Icons.shopping_bag_outlined, title: 'My Orders'),
            ],
            backgroundColor: Colors.white,
            activeColor: const Color(0xFF273847),
            color: Colors.grey,
            initialActiveIndex: selectedIndex,
            onTap: (index) {
              ref.read(navigationProvider.notifier).updateIndex(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _getSelectedPage(
      int index, BuildContext context, LocationState locationState) {
    switch (index) {
      case 0:
        return _buildMapPage(locationState);
      case 1:
        return const OrdersPage();
      case 2:
      // return const MyWidget();
      default:
        return const Center(child: Text('Unknown Page'));
    }
  }

  Widget _buildMapPage(LocationState locationState) {
    if (locationState.location == null) {
      return const Center(
        child: LoadingWidget(
          message: "No Orders",
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: locationState.location!,
        initialZoom: 17.0,
      ),
      children: [
        TileLayer(
          urlTemplate:
              "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: locationState.location!,
              width: 40.0,
              height: 40.0,
              child: const Icon(
                Icons.location_on,
                size: 40.0,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _listenForOrderAssignment(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? assignedId = prefs.getString('ID');
    final DatabaseReference orderRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
    ).ref('orders');

    orderRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((orderId, orderData) async {
          final assignedTo = orderData['assignedto'];

          if (assignedTo == assignedId) {
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const OrdersAssignedPage()),
              );
            }
          }
        });
      }
    });
  }

//   void _showOutsideZoneBottomSheet(BuildContext context, String message) {
//     const LatLng destinationCoordinates =
//         LatLng(10.010237165410416, 76.38430958465675);

//     showModalBottomSheet(
//       backgroundColor: Colors.white,
//       context: context,
//       builder: (BuildContext context) {
//         return Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Container(
//             color: Colors.white,
//             width: MediaQuery.of(context).size.width,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   'You’re just outside the service area.',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 10),
//                 Image.asset(
//                     width: MediaQuery.of(context).size.width,
//                     height: 100,
//                     fit: BoxFit.fill,
//                     "assets/zone-removebg-preview.png"),
//                 const SizedBox(height: 20),
//                 SizedBox(
//                   width: MediaQuery.of(context).size.width,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         shape: const BeveledRectangleBorder(
//                             borderRadius:
//                                 BorderRadius.all(Radius.circular(3)))),
//                     onPressed: () async {
//                       await _openMaps(destinationCoordinates);
//                       Navigator.of(context).pop();
//                     },
//                     child: const Text(
//                       'Open Maps',
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Future<void> _openMaps(LatLng coordinates) async {
//     final availableMaps = await MapLauncher.installedMaps;
//     if (availableMaps.isNotEmpty) {
//       await availableMaps[0].showDirections(
//         destination: Coords(coordinates.latitude, coordinates.longitude),
//       );
//     } else {
//       throw 'No map applications are installed.';
//     }
//   }
}
