

import 'package:geolocator/geolocator.dart';
import 'package:kealthy_delivery/Pages/Order/OrderItem.dart';

class OrderDistanceHelper {
  static const double restaurantLat = 10.010279427438405;
  static const double restaurantLon = 76.38426666931349;

  static double calculateDistance(double startLat, double startLon, double endLat, double endLon) {
    return Geolocator.distanceBetween(startLat, startLon, endLat, endLon);
  }

  static Order findNearestOrder(List<Order> orders) {
    if (orders.isEmpty) {
      throw Exception('Order list is empty');
    }

    orders.sort((a, b) {
      double distanceA = calculateDistance(restaurantLat, restaurantLon, a.selectedLatitude, a.selectedLongitude);
      double distanceB = calculateDistance(restaurantLat, restaurantLon, b.selectedLatitude, b.selectedLongitude);

      return distanceA.compareTo(distanceB);
    });

    return orders.first; 
  }

  static List<Order> sortOrdersByDistance(List<Order> orders) {
    if (orders.isEmpty) {
      return [];
    }

    orders.sort((a, b) {
      double distanceA = calculateDistance(restaurantLat, restaurantLon, a.selectedLatitude, a.selectedLongitude);
      double distanceB = calculateDistance(restaurantLat, restaurantLon, b.selectedLatitude, b.selectedLongitude);

      return distanceA.compareTo(distanceB);
    });

    return orders;
  }
}
