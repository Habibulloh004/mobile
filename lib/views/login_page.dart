import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import 'register_page.dart';
import 'main_page.dart';

// Custom formatter for +998 phone numbers
class UzbekPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Always ensure the phone number starts with +998
    if (!newValue.text.startsWith('+998')) {
      return oldValue;
    }

    // Handle backspace
    if (oldValue.text.length > newValue.text.length) {
      return newValue;
    }

    // Get only digits after +998
    String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.startsWith('998')) {
      digitsOnly = digitsOnly.substring(3); // Remove 998 from the digits
    }

    // Build formatted number
    String formatted = '+998';

    // Add spacing and formatting based on the length of the digits
    if (digitsOnly.isNotEmpty) {
      // Add the area code with parentheses if we have it
      if (digitsOnly.length > 0) {
        // Add opening parenthesis and space after +998
        formatted += ' (';
        formatted += digitsOnly.substring(0, min(2, digitsOnly.length));

        // Add closing parenthesis
        if (digitsOnly.length > 2) {
          formatted += ') ';

          // Add the next 3 digits with spacing
          formatted += digitsOnly.substring(2, min(5, digitsOnly.length));

          if (digitsOnly.length > 5) {
            formatted += ' ';
            formatted += digitsOnly.substring(5, min(7, digitsOnly.length));

            if (digitsOnly.length > 7) {
              formatted += ' ';
              formatted += digitsOnly.substring(7, min(9, digitsOnly.length));
            }
          }
        }
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  int min(int a, int b) {
    return a < b ? a : b;
  }
}

// Function to get raw phone number without formatting
String getRawPhoneNumber(String formattedNumber) {
  return formattedNumber.replaceAll(RegExp(r'\D'), '');
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController(text: '+998');
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
          String savedPhone = prefs.getString('savedPhone') ?? '';

          // Format the phone number if it's a raw number
          if (savedPhone.isNotEmpty && !savedPhone.contains('(')) {
            _phoneController.text = formatSavedPhoneNumber(savedPhone);
          } else {
            _phoneController.text = savedPhone.isEmpty ? '+998' : savedPhone;
          }

          _passwordController.text = prefs.getString('savedPassword') ?? '';
          _rememberMe = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  // Helper method to format saved phone number
  String formatSavedPhoneNumber(String rawPhone) {
    if (rawPhone.startsWith('+998') && rawPhone.length >= 13) {
      String digitsAfterCode = rawPhone.substring(4);
      String formatted =
          '+998 (${digitsAfterCode.substring(0, 2)}) ${digitsAfterCode.substring(2, 5)} ${digitsAfterCode.substring(5, 7)} ${digitsAfterCode.substring(7, 9)}';
      return formatted;
    }
    return rawPhone;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Get raw phone number without formatting
    String rawPhoneNumber = getRawPhoneNumber(_phoneController.text);

    // Validate inputs
    if (rawPhoneNumber.length < 12 || _passwordController.text.isEmpty) {
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
        rawPhoneNumber, // Use raw phone number for API call
        _passwordController.text.trim(),
      );

      if (clientData != null) {
        // Save credentials if "Remember me" is checked
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('rememberMe', true);
          await prefs.setString(
            'savedPhone',
            rawPhoneNumber,
          ); // Save raw number
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
                SvgPicture.asset(
                  'assets/images/appLogo.svg',
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
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
                        inputFormatters: [UzbekPhoneFormatter()],
                        decoration: InputDecoration(
                          labelText: "Номер телефона",
                          hintText: "+998 (XX) XXX XX XX",
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
