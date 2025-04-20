import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import 'login_page.dart';
import 'main_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptTerms = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Validate inputs
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Пожалуйста, заполните все поля';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Пароли не совпадают';
      });
      return;
    }

    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'Необходимо принять условия соглашения';
      });
      return;
    }

    // Validate phone number format
    String cleanPhone = _phoneController.text.replaceAll(' ', '').trim();
    RegExp phoneRegExp = RegExp(r'^\+?[0-9]{10,13}$');
    if (!phoneRegExp.hasMatch(cleanPhone)) {
      setState(() {
        _errorMessage = 'Введите корректный номер телефона';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final clientId = await _apiService.registerUser(
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _passwordController.text.trim(),
      );

      if (clientId != null) {
        // Navigate to main page and remove all pages from stack
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      } else {
        setState(() {
          _errorMessage =
              'Ошибка при регистрации. Возможно, пользователь с таким номером уже существует.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка при регистрации: $e';
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
                SizedBox(height: 40),
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
                SizedBox(height: 30),
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
                        "Регистрация",
                        style: TextStyle(
                          fontSize: Constants.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: ColorUtils.secondaryColor,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Имя",
                          hintText: "Ваше имя",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      SizedBox(height: 12),
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
                      SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: "Подтвердите пароль",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _acceptTerms,
                              onChanged: (value) {
                                setState(() {
                                  _acceptTerms = value ?? false;
                                });
                              },
                              activeColor: ColorUtils.accentColor,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Я согласен с условиями соглашения",
                              style: TextStyle(
                                fontSize: Constants.fontSizeSmall,
                                color: Colors.grey[700],
                              ),
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
                                  onPressed: _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorUtils.buttonColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text("Зарегистрироваться"),
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
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(),
                              ),
                            );
                          },
                          child: Text(
                            "Войти в аккаунт  ➚",
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
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
