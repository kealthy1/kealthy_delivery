import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:map_launcher/map_launcher.dart';
import '../Cod_page.dart/COD.dart';
import '../Order/OrderItem.dart';
import 'Deliver_Button.dart';

class DeliverNow extends StatelessWidget {
  final Order order;

  const DeliverNow({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> orderItems = order.orderItems;
    orderItems.sort((a, b) {
      double distanceA = a['distance'] ?? double.infinity;
      double distanceB = b['distance'] ?? double.infinity;
      return distanceA.compareTo(distanceB);
    });

    final ValueNotifier<bool> isCodConfirmed = ValueNotifier(false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 10,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      order.status,
                      style: GoogleFonts.poppins(
                        fontSize: 45,
                      ),
                    ),
                    Text(
                      "ORDER ID",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      order.orderId.length > 6
                          ? order.orderId.substring(order.orderId.length - 10)
                          : order.orderId,
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 50),
                    if (order.paymentmethod == "Cash on Delivery")
                      ValueListenableBuilder<bool>(
                        valueListenable: isCodConfirmed,
                        builder: (context, value, _) {
                          return ConfirmationButton(
                            label:
                                value ? "COD Received" : "Confirm COD Received",
                            isChecked: value,
                            onConfirmed: (bool isConfirmed) {
                              isCodConfirmed.value = isConfirmed;
                            },
                            totalAmount: order.totalAmountToPay,
                          );
                        },
                      ),
                    const SizedBox(height: 50),
                    _buildOrderDetails(context, order),
                    const SizedBox(height: 50),
                    _buildCustomerInfo(context, order),
                  ],
                ),
              ),
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: DeliverNowButton(order: order))
        ],
      ),
    );
  }
}

Widget _buildOrderDetails(BuildContext context, Order order) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 2,
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
      borderRadius: BorderRadius.circular(8.0),
    ),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(
          Icons.shopify_outlined,
          color: Color(0xFF273847),
        ),
        title: Text(
          'Order Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w300,
          ),
        ),
        children: [
          ..._buildOrderItems(order.orderItems),
          if (order.orderItems.length > 3)
            TextButton(
              onPressed: () {},
              child: Text(
                'Show More',
                style: GoogleFonts.poppins(
                  color: Colors.blueGrey,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Icon(
                  Icons.message_outlined,
                  color: Color(0xFF273847),
                ),
              ),
              Expanded(
                  child: Text(
                order.cookinginstrcutions,
                style: GoogleFonts.poppins(),
              )),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

Widget _buildCustomerInfo(BuildContext context, Order order) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 2,
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
      borderRadius: BorderRadius.circular(8.0),
    ),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(
          Icons.person_2_sharp,
          color: Color(0xFF273847),
        ),
        title: Text(
          'Customer Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w300,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.name,
                      style: GoogleFonts.poppins(
                          color: Colors.black, fontSize: 20),
                    ),
                    IconButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black12),
                      onPressed: () async {
                        await FlutterPhoneDirectCaller.callNumber(
                            order.phoneNumber);
                      },
                      icon: const Icon(
                        Icons.call,
                        color: Color(0xFF273847),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(order.selectedRoad,
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                    )),
                const SizedBox(height: 30),
                if (order.deliveryInstructions.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order.deliveryInstructions.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.message_outlined),
                            const SizedBox(width: 5),
                            Text(
                              'Delivery Instructions:',
                              style: GoogleFonts.poppins(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      const SizedBox(height: 5),
                      if (order.deliveryInstructions.isNotEmpty)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth),
                              child: Text(
                                order.deliveryInstructions,
                                style: GoogleFonts.poppins(fontSize: 14),
                                textAlign: TextAlign.start,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 150,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF273847),
                  ),
                  onPressed: () async {
                    final availableMaps = await MapLauncher.installedMaps;
                    if (availableMaps.isNotEmpty) {
                      await availableMaps.first.showDirections(
                        destination: Coords(
                          order.selectedLatitude,
                          order.selectedLongitude,
                        ),
                      );
                    } else {
                      throw 'No map applications are installed.';
                    }
                  },
                  icon: const Icon(Icons.map, color: Colors.white),
                  label: Text(
                    'Map',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    ),
  );
}

List<Widget> _buildOrderItems(List<dynamic> items) {
  return items.map((item) {
    return ListTile(
      title: Text(
        '${item['item_quantity']} x ${item['item_name']}',
        style: GoogleFonts.poppins(),
      ),
    );
  }).toList();
}
