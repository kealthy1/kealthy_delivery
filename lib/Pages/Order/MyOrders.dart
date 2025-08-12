import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kealthy_delivery/Pages/Login/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bills.dart';
import 'package:http/http.dart' as http;

enum _OverflowAction { logout }

class Order {
  final String orderId;
  final String name;
  final DateTime date;
  final String distance;
  final List<OrderItem> orderItems;
  final double totalAmountToPay;

  Order({
    required this.orderId,
    required this.name,
    required this.distance,
    required this.orderItems,
    required this.totalAmountToPay,
    required this.date,
  });
}

class OrderItem {
  final String itemName;
  final double itemPrice;
  final int itemQuantity;

  OrderItem({
    required this.itemName,
    required this.itemPrice,
    required this.itemQuantity,
  });
}

class OrdersNotifier extends StateNotifier<List<Order>> {
  OrdersNotifier() : super([]);

  String selectedDateText = 'Today';
  bool loading = false;

  Future<void> fetchOrders({String? filterDate}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final assignedId = prefs.getString('ID');

    if (assignedId != null) {
      final apiUrl =
          "https://api-jfnhkjk4nq-uc.a.run.app/assignedTo/$assignedId";

      loading = true;
      state = [];
      try {
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final List<dynamic> responseData =
              jsonDecode(response.body)['orders'];

          final fetchedOrders =
              responseData
                  .where((data) {
                    if (filterDate != null) {
                      return data['date'] == filterDate;
                    }
                    return true;
                  })
                  .map((data) {
                    try {
                      final items =
                          (data['orderItems'] as List<dynamic>? ?? []).map((
                            item,
                          ) {
                            return OrderItem(
                              itemName:
                                  item['item_name']?.toString() ??
                                  'Unknown Item',
                              itemPrice:
                                  (item['item_price'] as num?)?.toDouble() ??
                                  0.0,
                              itemQuantity:
                                  (item['item_quantity'] as num?)?.toInt() ?? 0,
                            );
                          }).toList();

                      final totalAmountToPay =
                          (data['totalAmountToPay'] as num?)?.toDouble() ?? 0.0;
                      final name = data['Name']?.toString() ?? 'Unknown Name';

                      final orderDate =
                          data['date']?.toString() != null
                              ? DateFormat(
                                'dd-MM-yyyy',
                              ).parse(data['date'].toString())
                              : DateTime.now();

                      return Order(
                        orderId: data['orderId']?.toString() ?? 'Unknown Order',
                        distance: data['distance']?.toString() ?? 'N/A',
                        orderItems: items,
                        totalAmountToPay: totalAmountToPay,
                        name: name,
                        date: orderDate,
                      );
                    } catch (e) {
                      print('Error parsing order: $e');
                      return null;
                    }
                  })
                  .where((order) => order != null)
                  .toList()
                  .cast<Order>();

          state = fetchedOrders;
        } else if (response.statusCode == 404) {
          state = [];
        } else {
          throw Exception("Failed to fetch orders: ${response.body}");
        }
      } catch (e) {
        print('Error fetching orders: $e');
        state = [];
      } finally {
        loading = false;
      }
    }
  }

  Future<void> setSelectedDate(DateTime date) async {
    selectedDateText = DateFormat('dd-MM-yyyy').format(date);
    await fetchOrders(filterDate: selectedDateText);
  }

  Future<void> fetchTodayOrders() async {
    final today = DateFormat('dd-MM-yyyy').format(DateTime.now());
    selectedDateText = 'Today';
    await fetchOrders(filterDate: today);
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>((
  ref,
) {
  final notifier = OrdersNotifier();
  notifier.fetchTodayOrders();
  return notifier;
});

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final notifier = ref.read(ordersProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Text(
              notifier.selectedDateText,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              CupertinoIcons.calendar_today,
              color: Colors.black,
            ),
            onPressed: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (selectedDate != null) {
                notifier.setSelectedDate(selectedDate);
              }
            },
          ),
          Tooltip(
            message: 'Logout',
            child: PopupMenuButton<_OverflowAction>(
              
              icon: const Icon(Icons.power_settings_new, color: Colors.black),
              itemBuilder:
                  (context) => const [
                    PopupMenuItem<_OverflowAction>(
                      
                      value: _OverflowAction.logout,
                      child: Text('Logout'),
                    ),
                  ],
              onSelected: (value) async {
                if (value == _OverflowAction.logout) {
                  final confirmed =
                      await showCupertinoDialog<bool>(
                        context: context,
                        builder:
                            (ctx) => CupertinoAlertDialog(
                              title: const Text('Logout'),
                              content: const Text('Do you want to logout?'),
                              actions: [
                                CupertinoDialogAction(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                      ) ??
                      false;

                  if (confirmed) {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.clear();
                    Navigator.pushReplacement(
                      context,
                      CupertinoModalPopupRoute(
                        builder: (context) => const LoginFields(),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body:
          notifier.loading
              ? const Center(child: CircularProgressIndicator())
              : orders.isEmpty
              ? const Center(
                child: Text(
                  'No data available for the selected date.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
              : ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Card(
                    color: Colors.white,
                    elevation: 10,
                    shadowColor: Colors.black,
                    margin: const EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Order ${order.orderId}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      fontFamily: "poppins",
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(
                                    CupertinoIcons.doc,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                              Text(
                                notifier.selectedDateText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.person_alt_circle,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    order.name,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                              Text('${order.distance} km'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  side: const BorderSide(color: Colors.black38),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => BillPage(order: order),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "See Details",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
