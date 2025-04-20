import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import 'register_page.dart';
import 'main_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _checkSavedCredentials();
  }

  Future<void> _checkSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('rememberMe') == true) {
        setState(() {
          _phoneController.text = prefs.getString('savedPhone') ?? '';
          _passwordController.text = prefs.getString('savedPassword') ?? '';
          _rememberMe = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Validate inputs
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Пожалуйста, заполните все поля';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final clientData = await _apiService.loginUser(
        _phoneController.text.trim(),
        _passwordController.text.trim(),
      );

      if (clientData != null) {
        // Save credentials if "Remember me" is checked
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('rememberMe', true);
          await prefs.setString('savedPhone', _phoneController.text.trim());
          await prefs.setString(
            'savedPassword',
            _passwordController.text.trim(),
          );
        }

        // Navigate to main page and remove login page from stack
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      } else {
        setState(() {
          _errorMessage = 'Неверный номер телефона или пароль';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка при входе: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorUtils.bodyColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 60),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "Foo",
                        style: TextStyle(
                          color: ColorUtils.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: Constants.fontSizeXLarge,
                        ),
                      ),
                      TextSpan(
                        text: "dery",
                        style: TextStyle(
                          color: ColorUtils.secondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: Constants.fontSizeXLarge,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ColorUtils.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Войти",
                        style: TextStyle(
                          fontSize: Constants.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: ColorUtils.secondaryColor,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: "Номер телефона",
                          hintText: "+998 XX XXX XX XX",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Пароль",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: 8),

                      // Remember me checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (bool? value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: ColorUtils.accentColor,
                          ),
                          Text(
                            "Запомнить меня",
                            style: TextStyle(
                              fontSize: Constants.fontSizeSmall,
                              color: ColorUtils.secondaryColor,
                            ),
                          ),
                        ],
                      ),

                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              color: ColorUtils.errorColor,
                              fontSize: Constants.fontSizeSmall,
                            ),
                          ),
                        ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
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
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorUtils.buttonColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text("Войти"),
                                ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 1,
                              color: Colors.grey[300],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "ИЛИ",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: Constants.fontSizeSmall,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 1,
                              color: Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterPage(),
                              ),
                            );
                          },
                          child: Text(
                            "Создать новый аккаунт  ➚",
                            style: TextStyle(
                              color: ColorUtils.secondaryColor,
                              fontSize: Constants.fontSizeRegular,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
