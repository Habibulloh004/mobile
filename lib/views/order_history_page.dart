import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import '../helpers/index.dart';
import '../models/order_model.dart';
import 'order_details_page.dart';

class OrderHistoryPage extends StatefulWidget {
  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<OrderModel> _orders = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final orders = await _apiService.fetchOrderHistory();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки истории заказов: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorUtils.bodyColor,
      appBar: AppBar(
        backgroundColor: ColorUtils.bodyColor,
        elevation: 0,
        title: Text(
          "История заказов",
          style: TextStyle(
            color: ColorUtils.secondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorUtils.secondaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorUtils.accentColor,
                  ),
                ),
              )
              : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _orders.isEmpty
              ? _buildEmptyView()
              : _buildOrdersList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Ошибка',
            style: TextStyle(
              fontSize: Constants.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: ColorUtils.secondaryColor,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Constants.fontSizeRegular,
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorUtils.accentColor,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'У вас пока нет заказов',
            style: TextStyle(
              fontSize: Constants.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: ColorUtils.secondaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Здесь будет отображаться история ваших заказов',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Constants.fontSizeRegular,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: ColorUtils.accentColor,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsPage(order: order),
          ),
        ).then((_) {
          // Refresh orders when returning from order details
          _loadOrders();
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: ColorUtils.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Заказ №${order.id}',
                        style: TextStyle(
                          fontSize: Constants.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: ColorUtils.secondaryColor,
                        ),
                      ),
                    ],
                  ),

                  // Order date
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      order.date,
                      style: TextStyle(
                        fontSize: Constants.fontSizeSmall,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),

                  Divider(height: 24),

                  // Order details
                  Row(
                    children: [
                      Icon(
                        order.deliveryType == 'delivery'
                            ? Icons.delivery_dining
                            : Icons.storefront,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.deliveryType == 'delivery'
                                  ? 'Доставка'
                                  : 'Самовывоз',
                              style: TextStyle(
                                fontSize: Constants.fontSizeRegular,
                                color: Colors.grey[600],
                              ),
                            ),
                            // Show spot name for pickup orders
                            if (order.deliveryType != 'delivery' &&
                                order.spotName != null)
                              Text(
                                order.spotName!,
                                style: TextStyle(
                                  fontSize: Constants.fontSizeSmall,
                                  fontWeight: FontWeight.bold,
                                  color: ColorUtils.accentColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        formatPrice(order.total),
                        style: TextStyle(
                          fontSize: Constants.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: ColorUtils.accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Footer button
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  'Подробнее',
                  style: TextStyle(
                    fontSize: Constants.fontSizeRegular,
                    fontWeight: FontWeight.bold,
                    color: ColorUtils.accentColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
