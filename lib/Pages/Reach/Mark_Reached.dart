import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy_delivery/Riverpod/Loading.dart';
import 'package:map_launcher/map_launcher.dart';
import '../Order/OrderItem.dart';
import 'Mark_Reached_Button.dart';

final isCodConfirmedProvider = StateProvider<bool>((ref) => false);

class ReachNow extends ConsumerStatefulWidget {
  final String orderId;

  const ReachNow({super.key, required this.orderId});

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends ConsumerState<ReachNow> {
  List<dynamic> orders = [];
  @override
  void initState() {
    super.initState();
    ref.read(orderProvider.notifier).fetchOrderDetails(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderProvider);
    final showAllItems = ref.watch(showAllItemsProvider);
    ref.watch(isCodConfirmedProvider.notifier);

    if (order != null) {
      orders = order.orderItems;
      orders.sort((a, b) {
        double distanceA = a['distance'] ?? double.infinity;
        double distanceB = b['distance'] ?? double.infinity;
        return distanceA.compareTo(distanceB);
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 10,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
      ),
      body: order == null
          ? const Center(
              child: LoadingWidget(
              message: 'Please Wait',
            ))
          : Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width * 0.04),
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
                                ? order.orderId
                                    .substring(order.orderId.length - 10)
                                : order.orderId,
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 50),
                          _buildOrderDetails(order, showAllItems),
                          const SizedBox(height: 40),
                          _buildCustomerInfo(order),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ),
                ReachNowButton(order: order),
              ],
            ),
    );
  }

  Widget _buildOrderDetails(Order order, bool showAllItems) {
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
            ..._buildOrderItems(order.orderItems, showAllItems),
            if (order.orderItems.length > 3)
              TextButton(
                onPressed: () {
                  ref.read(showAllItemsProvider.notifier).state = !showAllItems;
                },
                child: Text(
                  showAllItems ? 'Show Less' : 'Show More',
                  style: GoogleFonts.poppins(color: Colors.blueGrey),
                ),
              ),
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Icon(
                    Icons.message_outlined,
                    color: Color(0xFF273847),
                  ),
                ),
                Expanded(child: Text(order.cookinginstrcutions)),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo(Order order) {
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
          leading: const Icon(
            Icons.person_3_rounded,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            final phoneNumber = order.phoneNumber;

                            await FlutterPhoneDirectCaller.callNumber(
                                phoneNumber);
                          },
                          icon: const Icon(
                            size: 20,
                            Icons.call,
                            color: Color(0xFF273847),
                          ))
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    order.selectedRoad,
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order.deliveryInstructions.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.message_outlined,
                              color: Color(0xFF273847),
                            ),
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
                  const SizedBox(height: 10),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  child: ElevatedButton.icon(
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.all(const Color(0xFF273847)),
                    ),
                    onPressed: () async {
                      double selectedLatitude = order.selectedLatitude;
                      double selectedLongitude = order.selectedLongitude;

                      final availableMaps = await MapLauncher.installedMaps;
                      if (availableMaps.isNotEmpty) {
                        await availableMaps[0].showDirections(
                          destination:
                              Coords(selectedLatitude, selectedLongitude),
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
            const SizedBox(
              height: 30,
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOrderItems(List<dynamic> items, bool showAllItems) {
    final displayedItems = showAllItems ? items : items.take(3).toList();
    return displayedItems.map((item) {
      return ListTile(
        title: Text(
          '${item['item_quantity']} x ${item['item_name']} ',
          style: GoogleFonts.poppins(),
        ),
      );
    }).toList();
  }
}
