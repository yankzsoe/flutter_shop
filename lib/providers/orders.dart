import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import './cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    @required this.id,
    @required this.amount,
    @required this.products,
    @required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];
  final String authToken;
  final String userId;

  Orders(this.authToken, this.userId, this._orders);

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> fetchAndSetOrders() async {
    var url = Uri.parse(
        'https://flutter-auth-ce5c5-default-rtdb.firebaseio.com/orders/$userId.json?auth=$authToken');
    final response = await http.get(url);
    List<OrderItem> _loadedOrders = [];
    final extractedData = json.decode(response.body) as Map<String, dynamic>;
    if (extractedData == null) {
      _orders = [];
      notifyListeners();
      return;
    }
    extractedData.forEach((orderId, orderItem) {
      _loadedOrders.add(OrderItem(
        id: orderId,
        amount: orderItem['amount'],
        dateTime: DateTime.parse(orderItem['dateTime']),
        products: (orderItem['products'] as List<dynamic>)
            .map((e) => CartItem(
                id: e['id'],
                title: e['title'],
                quantity: e['quantity'],
                price: e['price']))
            .toList(),
      ));
    });
    _orders = _loadedOrders.reversed.toList();
    notifyListeners();
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    var url = Uri.parse(
        'https://flutter-auth-ce5c5-default-rtdb.firebaseio.com/orders/$userId.json?auth=$authToken');
    try {
      final timestamp = DateTime.now();
      final response = await http.post(url,
          body: json.encode({
            'amount': double.parse(total.toStringAsFixed(2)),
            'dateTime': timestamp.toIso8601String(),
            'products': cartProducts
                .map((cp) => {
                      'id': cp.id,
                      'title': cp.title,
                      'price': double.parse(cp.price.toStringAsFixed(2)),
                      'quantity': cp.quantity
                    })
                .toList(),
          }));
      if (response.statusCode >= 400) {}
      _orders.insert(
        0,
        OrderItem(
          id: json.decode(response.body)['name'],
          amount: total,
          dateTime: timestamp,
          products: cartProducts,
        ),
      );

      notifyListeners();
    } catch (error) {
      throw error;
    }
  }
}
