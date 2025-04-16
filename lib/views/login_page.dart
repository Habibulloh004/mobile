import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // Подключаем dio для API-запросов
import 'package:shared_preferences/shared_preferences.dart';
import 'main_page.dart';
import 'profile_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false; // Индикатор загрузки

  Future<void> _login() async {
    setState(() {
      _isLoading = true; // Показываем индикатор загрузки
    });

    final dio = Dio();
    final url = 'https://joinposter.com/api/clients.getClients?token=373820:33612612cbfe22576fbd715454ae78d2';

    try {
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        List<dynamic> clients = response.data["response"];

        // Убираем `+` в начале номера телефона
        String phoneNumber = _phoneController.text.replaceAll("+", "").trim();

        // Ищем клиента с таким номером телефона
        var client = clients.firstWhere(
              (c) => c["phone_number"] == phoneNumber,
          orElse: () => null,
        );

        if (client != null) {
          // ✅ Получаем пароль из JSON-объекта `comment`
          String? comment = client["comment"];
          String extractedPassword = "";

          // Парсим пароль из формата `{password: "qwertyui"}`
          RegExp regExp = RegExp(r'password:\s*"?([^"}]+)"?');
          Match? match = regExp.firstMatch(comment ?? "");

          if (match != null) {
            extractedPassword = match.group(1) ?? "";
          }

          print(client);

          if (extractedPassword == _passwordController.text) {
            // ✅ Авторизация успешна - сохраняем данные
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool("isLoggedIn", true);
            await prefs.setString("phone", client["phone_number"]);
            await prefs.setString("name", client["lastname"] ?? "Без имени");
            await prefs.setString("bonus", client["bonus"] ?? "0");

            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
          } else {
            _showError("Неверный пароль");
          }
        } else {
          _showError("Клиент не найден");
        }
      } else {
        _showError("Ошибка сервера");
      }
    } catch (e) {
      _showError("Ошибка подключения");
    } finally {
      setState(() {
        _isLoading = false; // Скрываем индикатор загрузки
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            SizedBox(height: 80),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: "Foo", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 28)),
                  TextSpan(text: "dery", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28)),
                ],
              ),
            ),
            SizedBox(height: 40),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Войти", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(labelText: "Номер телефона"),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Пароль",
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  _isLoading
                      ? Center(child: CircularProgressIndicator()) // Показываем индикатор загрузки
                      : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 48),
                    ),
                    child: Text("Войти"),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: Divider(thickness: 1, color: Colors.grey[400])),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("ИЛИ"),
                      ),
                      Expanded(child: Divider(thickness: 1, color: Colors.grey[400])),
                    ],
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterPage()),
                        );
                      },
                      child: Text(
                        "Создать новый аккаунт  ➚",
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
