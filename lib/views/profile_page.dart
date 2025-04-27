import 'package:flutter/material.dart';
import 'package:poster_app/helpers/index.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import '../core/api_service.dart';
import 'login_page.dart';
import 'order_history_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = "";
  String _phone = "";
  String _formattedPhone = "";
  int _bonus = 0;
  String _discount = "0";
  List<String> _addresses = [];
  bool _isLoading = true;
  Map<String, dynamic>? _fullClientData;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // First try to get client data from API service
      final clientData = await _apiService.getLoggedInClientData();

      if (clientData != null) {
        _updateClientDataFromResponse(clientData);
      } else {
        // Fallback to basic data from preferences if API fetch fails
        final prefs = await SharedPreferences.getInstance();
        final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

        if (isLoggedIn) {
          setState(() {
            _name = prefs.getString('name') ?? "Без имени";
            _phone = prefs.getString('phone') ?? "";
            _bonus = int.tryParse(prefs.getString('bonus') ?? "0") ?? 0;
            _discount = prefs.getString('discount') ?? "0";
            _addresses = prefs.getStringList('addresses') ?? [];
            _isLoading = false;
          });

          // Format the phone number
          _formatPhoneNumber();
        } else {
          // If not logged in, redirect to login page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка загрузки данных: $e")));
    }
  }

  void _updateClientDataFromResponse(Map<String, dynamic> clientData) {
    setState(() {
      _fullClientData = clientData;
      _name = clientData["lastname"] ?? clientData["firstname"] ?? "Без имени";
      _phone = clientData["phone_number"] ?? "";
      _bonus = int.tryParse(clientData["bonus"] ?? "0") ?? 0;
      _discount = clientData["discount_per"] ?? "0";

      // Extract addresses from the response
      if (clientData["addresses"] != null && clientData["addresses"] is List) {
        _addresses =
            (clientData["addresses"] as List)
                .map((addr) => addr["address1"]?.toString() ?? "")
                .where((addr) => addr.isNotEmpty)
                .toList();
      }

      _isLoading = false;
    });

    // Format the phone number
    _formatPhoneNumber();
  }

  void _formatPhoneNumber() {
    if (_phone.isEmpty) return;

    // Try to format the phone number for display
    try {
      String cleaned = _phone.replaceAll(RegExp(r'\D'), '');

      // Format as +XXX XX XXX XX XX
      if (cleaned.length >= 12) {
        _formattedPhone =
            "+${cleaned.substring(0, 3)} ${cleaned.substring(3, 5)} ${cleaned.substring(5, 8)} ${cleaned.substring(8, 10)} ${cleaned.substring(10)}";
      } else {
        _formattedPhone = _phone; // Fallback to original
      }
    } catch (e) {
      _formattedPhone = _phone; // Fallback to original
    }
  }

  Future<void> _logout() async {
    try {
      await _apiService.logoutUser();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка при выходе: $e")));
    }
  }

  Future<void> _refreshProfile() async {
    await _loadClientData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorUtils.bodyColor,
      appBar: AppBar(
        backgroundColor: ColorUtils.bodyColor,
        elevation: 0,
        title: Text(
          "Профиль",
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: ColorUtils.secondaryColor),
            onPressed: _refreshProfile,
          ),
        ],
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
              : RefreshIndicator(
                onRefresh: _refreshProfile,
                color: ColorUtils.accentColor,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User profile header
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: ColorUtils.primaryColor,
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: ColorUtils.accentColor,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _name,
                                    style: TextStyle(
                                      fontSize: Constants.fontSizeLarge,
                                      fontWeight: FontWeight.bold,
                                      color: ColorUtils.secondaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _formattedPhone.isNotEmpty
                                        ? _formattedPhone
                                        : _phone,
                                    style: TextStyle(
                                      fontSize: Constants.fontSizeRegular,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 24),

                        // Bonus and discount cards
                        Row(
                          children: [
                            // Bonus card
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: ColorUtils.primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.card_giftcard,
                                          color: ColorUtils.accentColor,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Бонусы",
                                          style: TextStyle(
                                            fontSize: Constants.fontSizeSmall,
                                            fontWeight: FontWeight.bold,
                                            color: ColorUtils.secondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      formatPrice(_bonus),
                                      // formatPrice(10000),
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: ColorUtils.accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 24),

                        // Menu options
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                icon: Icons.history,
                                title: "История заказов",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderHistoryPage(),
                                    ),
                                  );
                                },
                              )
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

                        // Logout button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _logout,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Выйти из аккаунта",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: Constants.fontSizeRegular,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: ColorUtils.secondaryColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: Constants.fontSizeRegular,
          color: ColorUtils.secondaryColor,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  void _showAddressesList() {
    if (_addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("У вас пока нет сохраненных адресов")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Сохраненные адреса",
                style: TextStyle(
                  fontSize: Constants.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: ColorUtils.secondaryColor,
                ),
              ),
              SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _addresses.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Icon(
                        Icons.location_on,
                        color: ColorUtils.accentColor,
                      ),
                      title: Text(_addresses[index]),
                      trailing: Icon(Icons.edit, color: Colors.grey[400]),
                      onTap: () {
                        // TODO: Implement address editing
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Редактирование адреса скоро будет доступно",
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorUtils.buttonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text("Закрыть"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
