import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/cart_provider.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import '../helpers/index.dart';
import 'order_confirmation_page.dart';
import 'login_page.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  String _paymentMethod = 'card'; // Default to card payment
  String _userName = '';
  String _userPhone = '';
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (loggedIn) {
        setState(() {
          _isLoggedIn = true;
          _userName = prefs.getString('name') ?? '';
          _userPhone = prefs.getString('phone') ?? '';
          _phoneController.text = _userPhone;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Submit order
  Future<void> _submitOrder() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // Simulate a network request
      await Future.delayed(Duration(seconds: 2));

      // Order was successful, navigate to confirmation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => OrderConfirmationPage(
                orderId: DateTime.now().millisecondsSinceEpoch % 1000,
                items: cartProvider.cartItems,
                total: cartProvider.total,
                subtotal: cartProvider.subtotal,
                deliveryFee: cartProvider.deliveryFee,
                address: _addressController.text,
                isDelivery: cartProvider.isDelivery,
                paymentMethod: _paymentMethod,
              ),
        ),
      );

      // Clear the cart
      cartProvider.clearCart();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при оформлении заказа: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Validate form fields
  bool _validateForm() {
    // If delivery is selected, address is required
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    if (cartProvider.isDelivery && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Пожалуйста, укажите адрес доставки'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Phone is always required
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Пожалуйста, укажите номер телефона'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    if (cartProvider.cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Оплата заказа'),
          backgroundColor: ColorUtils.bodyColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: ColorUtils.secondaryColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Text(
            'Ваша корзина пуста',
            style: TextStyle(
              fontSize: Constants.fontSizeMedium,
              color: ColorUtils.secondaryColor,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ColorUtils.bodyColor,
      appBar: AppBar(
        backgroundColor: ColorUtils.bodyColor,
        elevation: 0,
        title: Text(
          'Оплата заказа',
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
          _isLoggedIn ? _buildCheckoutForm(cartProvider) : _buildLoginPrompt(),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle, size: 64, color: ColorUtils.accentColor),
          SizedBox(height: 16),
          Text(
            'Необходимо войти в аккаунт',
            style: TextStyle(
              fontSize: Constants.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: ColorUtils.secondaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Чтобы продолжить оформление заказа,\nвойдите в свой аккаунт',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Constants.fontSizeRegular,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorUtils.accentColor,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Войти'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutForm(CartProvider cartProvider) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorUtils.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Товары',
                        style: TextStyle(
                          fontSize: Constants.fontSizeRegular,
                          color: ColorUtils.secondaryColor,
                        ),
                      ),
                      Text(
                        formatPrice(cartProvider.subtotal),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: Constants.fontSizeRegular,
                          color: ColorUtils.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (cartProvider.isDelivery)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Доставка',
                            style: TextStyle(
                              fontSize: Constants.fontSizeRegular,
                              color: ColorUtils.secondaryColor,
                            ),
                          ),
                          Text(
                            formatPrice(cartProvider.deliveryFee),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: Constants.fontSizeRegular,
                              color: ColorUtils.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Divider(height: 24, color: Colors.grey[300]),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Общая сумма',
                        style: TextStyle(
                          fontSize: Constants.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: ColorUtils.secondaryColor,
                        ),
                      ),
                      Text(
                        formatPrice(cartProvider.total),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: Constants.fontSizeMedium,
                          color: ColorUtils.accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Contact information
            Text(
              'Контактная информация',
              style: TextStyle(
                fontSize: Constants.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: ColorUtils.secondaryColor,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Телефон',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),

            SizedBox(height: 24),

            // Delivery information (if applicable)
            if (cartProvider.isDelivery) ...[
              Text(
                'Информация о доставке',
                style: TextStyle(
                  fontSize: Constants.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: ColorUtils.secondaryColor,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Адрес',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              SizedBox(height: 24),
            ],

            // Payment method
            Text(
              'Способ оплаты',
              style: TextStyle(
                fontSize: Constants.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: ColorUtils.secondaryColor,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(Icons.credit_card),
                        SizedBox(width: 8),
                        Text('Оплата картой'),
                      ],
                    ),
                    value: 'card',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                    activeColor: ColorUtils.accentColor,
                  ),
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(Icons.money),
                        SizedBox(width: 8),
                        Text('Наличными'),
                      ],
                    ),
                    value: 'cash',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                    activeColor: ColorUtils.accentColor,
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Additional notes
            Text(
              'Комментарий к заказу',
              style: TextStyle(
                fontSize: Constants.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: ColorUtils.secondaryColor,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Комментарий к заказу (необязательно)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),

            SizedBox(height: 32),

            // Apply bonus
            Container(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Функция бонусов скоро будет доступна'),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ColorUtils.accentColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Использовать бонусы',
                  style: TextStyle(
                    color: ColorUtils.accentColor,
                    fontSize: Constants.fontSizeRegular,
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Place order button
            SizedBox(
              width: double.infinity,
              height: 50,
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ColorUtils.accentColor,
                          ),
                        ),
                      )
                      : ElevatedButton(
                        onPressed: _submitOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorUtils.buttonColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Оплатить заказ',
                          style: TextStyle(
                            fontSize: Constants.fontSizeMedium,
                            fontWeight: FontWeight.bold,
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
