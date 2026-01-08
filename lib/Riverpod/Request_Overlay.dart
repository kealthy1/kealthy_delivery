// import 'dart:developer';
// import 'dart:io';
// import 'package:dash_bubble/dash_bubble.dart';
// import 'package:flutter/material.dart';

// class RequestOverlay {
//   Future<bool> requestOverlay() async {
//     final isGranted = await DashBubble.instance.requestOverlayPermission();
//     if (isGranted == true) {
//       print("Permission Granted");
//       return true;
//     } else {
//       print("Permission Denied");
//       return false;
//     }
//   }

//   Future<void> startBubble(
//     BubbleOptions bubbleOptions, {
//     required VoidCallback onTap,
//   }) async {
//     final hasStarted = await DashBubble.instance.startBubble(
//       bubbleOptions: bubbleOptions,
//       onTap: onTap,
//     );
//     if (hasStarted == true) {
//       print("Bubble Started");
//     } else {
//       print("Bubble Not Started");
//     }
//   }

//   Future<void> stopBubble() async {
//     final hasStopped = await DashBubble.instance.stopBubble();
//     if (hasStopped == true) {
//       print("Bubble Stopped");
//     } else {
//       print("Failed to Stop Bubble");
//     }
//   }

//   void logMessage({required String message}) {
//     log(message);
//   }
// }

// class BubbleControlPage extends StatefulWidget {
//   const BubbleControlPage({super.key});

//   @override
//   _BubbleControlPageState createState() => _BubbleControlPageState();
// }

// class _BubbleControlPageState extends State<BubbleControlPage> {
//   final RequestOverlay requestOverlay = RequestOverlay();

//   @override
//   void initState() {
//     super.initState();
//     _checkOverlayPermission();
//   }

//   Future<void> _checkOverlayPermission() async {
//     final hasPermission = await requestOverlay.requestOverlay();

//     if (!hasPermission && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Overlay permission is required to show bubble.'),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Bubble Control Page')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: () {
//                 requestOverlay.requestOverlay();
//               },
//               child: const Text("Request Overlay Permission"),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () async {
//                 final ok = await requestOverlay.requestOverlay();
//                 if (!ok) return;

//                 await requestOverlay.startBubble(
//                   BubbleOptions(
//                     bubbleIcon: "bubble",
//                     bubbleSize: 80,
//                     enableClose: false,
//                     distanceToClose: 90,
//                     enableAnimateToEdge: true,
//                     enableBottomShadow: true,
//                     keepAliveWhenAppExit: false,
//                   ),
//                   onTap: () {
//                     requestOverlay.logMessage(message: "Bubble Tapped");
//                   },
//                 );
//               },
//               child: const Text("Start Bubble"),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 requestOverlay.stopBubble();
//               },
//               child: const Text("Stop Bubble"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
