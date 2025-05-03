import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poster_app/widgets/animated_input_field.dart';
import 'package:poster_app/widgets/textarea.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../providers/cart_provider.dart';
import '../providers/spot_provider.dart';
import '../models/spot_model.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import '../helpers/index.dart';
import '../core/api_service.dart';
import '../services/order_service.dart';
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
  final _bonusController = TextEditingController();
  final _maskFormatter = MaskTextInputFormatter(
    mask: '+998 (##) ### ## ##',
    filter: {"#": RegExp(r'[0-9]')},
    type:
        MaskAutoCompletionType
            .eager, // Changed to eager for better auto-completion
  );
  bool _isLoading = false;
  String _paymentMethod = 'card'; // Default to card payment
  String _userName = '';
  String _userPhone = '';
  bool _isLoggedIn = false;
  SpotModel? _selectedSpot;
  final ApiService _apiService = ApiService();
  final Dio _dio = Dio();
  final OrderService _orderService = OrderService();

  // Bonus functionality variables
  bool _showBonusInput = false;
  int _availableBonus = 0; // Stored as raw value (already multiplied by 100)
  int _appliedBonus =
      0; // To be used in calculations (already multiplied by 100)
  int _displayBonus = 0; // For display purposes (divided by 100)

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Initialize spot provider if takeaway is selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load spots if takeaway is selected
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      if (!cartProvider.isDelivery) {
        _loadSpots();
      }

      // Ensure delivery fee is loaded
      if (cartProvider.isDelivery) {
        cartProvider.refreshDeliveryFee();
      }
    });
  }

  // Load spots data
  void _loadSpots() {
    final spotProvider = Provider.of<SpotProvider>(context, listen: false);
    spotProvider.loadSpots();
  }

  String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // If the number is too short, return as is
    if (digitsOnly.length < 9) return phoneNumber;

    // If the number starts with country code, extract it properly
    String countryCode = '';
    String operatorCode = '';
    String subscriberNumber = '';

    // Check if the number starts with 998 (country code)
    if (digitsOnly.startsWith('998')) {
      countryCode = '998';
      // Extract operator code (2 digits after country code)
      if (digitsOnly.length >= 5) {
        operatorCode = digitsOnly.substring(3, 5);
        // Extract the rest of the number
        if (digitsOnly.length >= 12) {
          subscriberNumber = digitsOnly.substring(5);
        } else {
          subscriberNumber = digitsOnly.substring(5);
        }
      }
    } else {
      // If no country code, assume it's a local number
      // Get the first 2 digits as operator code
      if (digitsOnly.length >= 2) {
        operatorCode = digitsOnly.substring(0, 2);
        subscriberNumber = digitsOnly.substring(2);
      }
    }

    // Format the number properly
    if (operatorCode.isNotEmpty) {
      // Ensure subscriberNumber is exactly 7 digits (if longer, take the first 7)
      if (subscriberNumber.length > 7) {
        subscriberNumber = subscriberNumber.substring(0, 7);
      }

      // Add padding if shorter than 7 digits (shouldn't normally happen)
      while (subscriberNumber.length < 7) {
        subscriberNumber = subscriberNumber + '0';
      }

      // Format: +998 (XX) XXX XX XX
      return '+998 (${operatorCode}) ${subscriberNumber.substring(0, 3)} ${subscriberNumber.substring(3, 5)} ${subscriberNumber.substring(5)}';
    } else {
      return phoneNumber;
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (loggedIn) {
        // Try to get data from the new userData format first
        final String? userDataJson = prefs.getString('userData');

        if (userDataJson != null && userDataJson.isNotEmpty) {
          // Parse the complete response structure
          Map<String, dynamic> userData = {};

          try {
            final parsedData = json.decode(userDataJson);

            // Check if we have the expected response format
            if (parsedData != null &&
                parsedData['response'] != null &&
                parsedData['response'] is List &&
                parsedData['response'].isNotEmpty) {
              // Get the first client from the response array
              userData = parsedData['response'][0];

              setState(() {
                _isLoggedIn = true;

                // Get user name - use lastname as the primary name field
                _userName = userData['lastname'] ?? '';

                // Get phone - preferably use phone_number field which has the raw format
                _userPhone =
                    userData['phone_number'] ?? userData['phone'] ?? '';

                // Format the phone number using our helper function
                if (_userPhone.isNotEmpty) {
                  _phoneController.text = _formatPhoneNumber(_userPhone);
                  debugPrint(
                    '📱 Phone formatted from: $_userPhone to: ${_phoneController.text}',
                  );
                }

                // Load user's available bonus from the response
                final bonusStr = userData['bonus'] ?? '0';
                _availableBonus = int.tryParse(bonusStr) ?? 0;

                // Calculate display value (divided by 100)
                _displayBonus = (_availableBonus / 100).round();

                debugPrint(
                  '📊 Loaded user data from userData: Name: $_userName, Phone: $_userPhone, Bonus: $_availableBonus',
                );
              });

              return; // Successfully loaded from userData
            }
          } catch (e) {
            debugPrint('Error parsing userData JSON: $e');
            // Continue to try legacy format
          }
        }

        // Fallback to legacy format if userData format failed
        setState(() {
          _isLoggedIn = true;
          _userName = prefs.getString('name') ?? '';
          _userPhone = prefs.getString('phone') ?? '';

          // Format the phone number using our helper function
          if (_userPhone.isNotEmpty) {
            _phoneController.text = _formatPhoneNumber(_userPhone);
            debugPrint(
              '📱 Phone formatted from: $_userPhone to: ${_phoneController.text}',
            );
          }

          // Load user's available bonus
          final bonusStr = prefs.getString('bonus') ?? '0';
          _availableBonus = int.tryParse(bonusStr) ?? 0;

          // Calculate display value (divided by 100)
          _displayBonus = (_availableBonus / 100).round();

          debugPrint(
            '📊 Loaded user data from legacy format: Name: $_userName, Phone: $_userPhone, Bonus: $_availableBonus',
          );
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
    _bonusController.dispose();
    super.dispose();
  }

  // Method to toggle bonus input visibility
  void _toggleBonusInput() {
    setState(() {
      _showBonusInput = !_showBonusInput;

      // Clear bonus input when hiding
      if (!_showBonusInput) {
        _bonusController.clear();
        _appliedBonus = 0;
      }
    });
  }

  // Method to validate and apply bonus
  void _applyBonus() {
    if (_bonusController.text.isEmpty) {
      setState(() {
        _appliedBonus = 0;
      });
      return;
    }

    // Parse the input bonus (this is the display value)
    final enteredDisplayBonus = int.tryParse(_bonusController.text) ?? 0;

    // Convert to raw value for comparison (multiply by 100)
    final enteredRawBonus = enteredDisplayBonus * 100;

    // Validate against available bonus
    if (enteredRawBonus > _availableBonus) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('У вас недостаточно бонусов. Доступно: $_displayBonus'),
          backgroundColor: Colors.red,
        ),
      );

      // Reset to maximum available display value
      setState(() {
        _bonusController.text = _displayBonus.toString();
        _appliedBonus = _availableBonus; // Store as raw value
      });
    } else {
      setState(() {
        _appliedBonus = enteredRawBonus; // Store as raw value
      });
    }
  }

  // When submitting order, update the calculation:
  Future<void> _submitOrder() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // IMPORTANT: Ensure delivery fee is properly loaded before proceeding
      await cartProvider.prepareForCheckout();

      // Get spot information if takeaway is selected
      String? spotId;
      String? spotName;
      if (!cartProvider.isDelivery) {
        // If takeaway, check if spot is selected
        if (_selectedSpot == null) {
          final spotProvider = Provider.of<SpotProvider>(
            context,
            listen: false,
          );
          _selectedSpot = spotProvider.selectedSpot;
        }

        if (_selectedSpot != null) {
          spotId = _selectedSpot!.id;
          spotName = _selectedSpot!.name;
        } else {
          // Show error if no spot is selected for takeaway
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Пожалуйста, выберите точку самовывоза'),
              backgroundColor: Colors.red,
            ),
          );

          return;
        }
      }
      // Use the new OrderService to submit the order
      final orderResult = await _orderService.submitOrder(
        cartItems: cartProvider.cartItems,
        phone: _phoneController.text,
        deliveryType: cartProvider.isDelivery ? "delivery" : "take away",
        appliedBonus: _appliedBonus.toInt() ~/ 100,
        address:
            cartProvider.isDelivery
                ? _addressController.text
                : _selectedSpot?.address ?? '',
        paymentMethod: _paymentMethod,
        comment: _noteController.text,
        deliveryFee: cartProvider.deliveryFee,
        spotId: spotId,
      );

      if (orderResult != null) {
        num calBonus = _appliedBonus.toInt() ~/ 100;
        // Calculate final total with bonus applied
        final int totalAfterBonus = cartProvider.total > calBonus
            ? cartProvider.total - calBonus.toInt()
            : 0;

        // Order was successful, navigate to confirmation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => OrderConfirmationPage(
                  orderId:
                      int.tryParse(orderResult) ??
                      DateTime.now().millisecondsSinceEpoch % 1000,
                  items: cartProvider.cartItems,
                  total: totalAfterBonus > 0 ? totalAfterBonus : 0,
                  // Ensure it's not negative
                  subtotal: cartProvider.subtotal,
                  deliveryFee: cartProvider.deliveryFee,
                  appliedBonus: _appliedBonus,
                  address:
                      cartProvider.isDelivery
                          ? _addressController.text
                          : _selectedSpot?.address ?? '',
                  isDelivery: cartProvider.isDelivery,
                  paymentMethod: _paymentMethod,
                  spotId: spotId,
                  spotName: spotName,
                ),
          ),
        );

        // Clear the cart
        cartProvider.clearCart();

        // If bonus was applied, deduct it from the user's available bonus
        if (_appliedBonus > 0) {
          try {
            final prefs = await SharedPreferences.getInstance();
            // Calculate and save the new raw bonus amount
            final newRawBonus = _availableBonus - _appliedBonus;
            await prefs.setString('bonus', newRawBonus.toString());
          } catch (e) {
            debugPrint('❌ Error updating user bonus: $e');
          }
        }
      } else {
        // Order submission failed
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка при отправке заказа. Пожалуйста, попробуйте еще раз.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
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

    // If takeaway is selected, spot is required
    if (!cartProvider.isDelivery) {
      if (_selectedSpot == null) {
        // Try to get selected spot from provider
        final spotProvider = Provider.of<SpotProvider>(context, listen: false);
        _selectedSpot = spotProvider.selectedSpot;
      }

      if (_selectedSpot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Пожалуйста, выберите точку самовывоза'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
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

  // Widget to display spot selection
  Widget _buildSpotSelection() {
    return Consumer<SpotProvider>(
      builder: (context, spotProvider, child) {
        if (spotProvider.isLoading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  ColorUtils.accentColor,
                ),
              ),
            ),
          );
        }

        if (spotProvider.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ошибка загрузки точек самовывоза',
                style: TextStyle(color: ColorUtils.errorColor),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => spotProvider.refreshSpots(),
                child: Text('Повторить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorUtils.accentColor,
                ),
              ),
            ],
          );
        }

        if (spotProvider.spots.isEmpty) {
          return Text(
            'Нет доступных точек самовывоза',
            style: TextStyle(
              fontSize: Constants.fontSizeRegular,
              color: Colors.grey[700],
            ),
          );
        }

        // Get selected spot from provider if not already selected
        if (_selectedSpot == null && spotProvider.selectedSpot != null) {
          _selectedSpot = spotProvider.selectedSpot;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Выберите точку самовывоза',
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
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: spotProvider.spots.length,
                itemBuilder: (context, index) {
                  final spot = spotProvider.spots[index];
                  final isSelected = _selectedSpot?.id == spot.id;

                  return RadioListTile<SpotModel>(
                    title: Text(
                      spot.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: ColorUtils.secondaryColor,
                      ),
                    ),
                    subtitle: Text(
                      spot.address,
                      style: TextStyle(
                        fontSize: Constants.fontSizeSmall,
                        color: Colors.grey[600],
                      ),
                    ),
                    value: spot,
                    groupValue: _selectedSpot,
                    onChanged: (SpotModel? value) {
                      setState(() {
                        _selectedSpot = value;
                      });
                      spotProvider.setSelectedSpot(value);
                    },
                    activeColor: ColorUtils.accentColor,
                    dense: false,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
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
    // Calculate the final total with bonuses applied
    final int totalAfterBonus =
        cartProvider.total > _appliedBonus
            ? cartProvider.total - _appliedBonus
            : 0;

    // When delivery type changes, load spots if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!cartProvider.isDelivery) {
        final spotProvider = Provider.of<SpotProvider>(context, listen: false);
        spotProvider.loadSpots();
      }
    });

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
                          // Show delivery fee directly without loader
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

                  // Show applied bonus if any
                  if (_appliedBonus > 0)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Применено бонусов',
                            style: TextStyle(
                              fontSize: Constants.fontSizeRegular,
                              color: Colors.green[800],
                            ),
                          ),
                          Text(
                            '- ${formatPrice(_appliedBonus)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: Constants.fontSizeRegular,
                              color: Colors.green[800],
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
                        formatPrice(totalAfterBonus),
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
            SizedBox(height: 10),
            AnimatedInputField(
              controller: _phoneController,
              labelText: 'Телефон',
              hintText: '+998 (90) 123 45 67',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [_maskFormatter],
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
              // Address field replacement
              AnimatedInputField(
                controller: _addressController,
                labelText: 'Адрес',
                prefixIcon: Icons.location_on,
              ),
              SizedBox(height: 24),
            ] else ...[
              // Spot selection for takeaway
              SizedBox(height: 8),
              _buildSpotSelection(),
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
            WebTextareaField(
              controller: _noteController,
              labelText: 'Комментарий к заказу',
              hintText: 'Введите дополнительную информацию о вашем заказе...',
              maxLines: 4,
              maxLength: 200, // Optional: set a character limit
            ),

            SizedBox(height: 32),

            // Apply bonus section
            if (_availableBonus > 0) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bonus button
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _toggleBonusInput,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color:
                              _showBonusInput
                                  ? Colors.red
                                  : ColorUtils.accentColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _showBonusInput ? 'Отмена' : 'Использовать бонусы',
                        style: TextStyle(
                          color:
                              _showBonusInput
                                  ? Colors.red
                                  : ColorUtils.accentColor,
                          fontSize: Constants.fontSizeRegular,
                        ),
                      ),
                    ),
                  ),

                  // Available bonus info - show display value (divided by 100)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Доступно бонусов: ${formatPrice(_availableBonus, subtract: true)}',
                      style: TextStyle(
                        fontSize: Constants.fontSizeSmall,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),

                  // Bonus input field (conditionally displayed)
                  if (_showBonusInput) ...[
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedInputField(
                            controller: _bonusController,
                            labelText: 'Количество бонусов',
                            hintText: 'Введите сумму бонусов',
                            keyboardType: TextInputType.number,
                            suffixText: 'сум',
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              TextInputFormatter.withFunction((
                                oldValue,
                                newValue,
                              ) {
                                if (newValue.text.isEmpty) return newValue;
                                final int? value = int.tryParse(newValue.text);
                                if (value != null && value > _displayBonus) {
                                  return oldValue;
                                }
                                return newValue;
                              }),
                            ],
                            onChanged: (value) {
                              // Apply bonus on change - convert input to raw value (multiply by 100)
                              final inputValue = int.tryParse(value) ?? 0;
                              setState(() {
                                _appliedBonus = inputValue * 100;
                                _bonusController.value = TextEditingValue(
                                  text: formatPrice(
                                    inputValue,
                                    type: 'space',
                                    showCurrency: false,
                                  ),
                                  selection: TextSelection.collapsed(
                                    offset:
                                        formatPrice(
                                          inputValue,
                                          type: 'space',
                                          showCurrency: false,
                                        ).length,
                                  ),
                                );
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        SizedBox(
                          height: 50.0, // Set your desired height
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _bonusController.text =
                                    _displayBonus.toString();
                                _appliedBonus = _availableBonus;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorUtils.accentColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Макс'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              SizedBox(height: 16),
            ],

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
