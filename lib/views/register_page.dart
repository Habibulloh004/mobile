import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });

    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Заполните все поля")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await Dio().post(
        "https://joinposter.com/api/clients.createClient",
        queryParameters: {
          "token": "373820:33612612cbfe22576fbd715454ae78d2",
        },
        data: {
          "client_name": name,
          "phone": phone,
          "comment": "{password: \"$password\"}",
          "client_groups_id_client": 1,
        },
      );
      print(response.data);

      if (response.statusCode == 200 && response.data["response"] != null) {
        // ✅ Сохранение данных пользователя
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("phone", phone);
        await prefs.setBool("isLoggedIn", true);

        // 🔹 Переход на главную страницу
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка регистрации. Попробуйте снова.")),
        );
      }
    } catch (e) {
      print("Ошибка регистрации: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка сети. Проверьте подключение.")),
      );
    }

    setState(() {
      _isLoading = false;
    });
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
                  Text("Регистрация", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: "Имя"),
                  ),
                  SizedBox(height: 10),
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
                  SizedBox(height: 10),
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 48),
                    ),
                    child: Text("Зарегистрироваться"),
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
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
                      },
                      child: Text(
                        "Войти в аккаунт  ➚",
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
