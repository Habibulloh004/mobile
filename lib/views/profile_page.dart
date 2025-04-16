import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'login_page.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = "";
  String _phone = "";
  int _bonus = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClientData();
  }

  Future<void> _fetchClientData() async {
    final prefs = await SharedPreferences.getInstance();
    String? phoneNumber = prefs.getString("phone"); // Получаем телефон из локального хранилища

    if (phoneNumber == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
      return;
    }

    try {
      final response = await Dio().get(
        "https://joinposter.com/api/clients.getClients",
        queryParameters: {
          "token": "967898:49355888e8e490af3bcca79c5e6b1abf",
        },
      );
      // print(response.data);
      // print(phoneNumber.replaceFirst('+', ''));


      if (response.statusCode == 200) {
        List<dynamic> clients = response.data["response"];
        var client = clients.firstWhere(
              (c) => c["phone_number"] == phoneNumber.replaceFirst('+', ''),
          orElse: () => null,
        );

        if (client != null) {
          setState(() {
            _name = client["lastname"] ?? "Без имени";
            _phone = client["phone"] ?? "";
            _bonus = int.tryParse((client["bonus"]).toString()) ?? 0;
            _isLoading = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Клиент не найден")),
          );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
        }
      }
    } catch (e) {
      print("Ошибка загрузки клиента: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка загрузки данных")),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: "Foo", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 24)),
              TextSpan(text: "dery", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24)),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart, size: 28),
            onPressed: () {
              // TODO: Добавить переход в корзину
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Профиль", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              readOnly: true,
              controller: TextEditingController(text: _name),
              decoration: InputDecoration(
                labelText: "Имя",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              readOnly: true,
              controller: TextEditingController(text: _phone),
              decoration: InputDecoration(
                labelText: "Номер телефона",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Бонусы: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("$_bonus", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[50],
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, 48),
              ),
              child: Text("Выйти с аккаунта"),
            ),
          ],
        ),
      ),
    );
  }
}
