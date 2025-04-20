import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/color_utils.dart';
import '../views/login_page.dart';
import '../views/profile_page.dart';
import '../views/order_history_page.dart';
import '../views/about_page.dart';
import '../constant/index.dart';

class AppSidebar extends StatefulWidget {
  @override
  _AppSidebarState createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  String _userName = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (isLoggedIn) {
        setState(() {
          _userName = prefs.getString('name') ?? "Пользователь";
          _isLoading = false;
        });
      } else {
        setState(() {
          _userName = "Гость";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _userName = "Гость";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: ColorUtils.primaryColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    "Foo",
                    style: TextStyle(
                      color: ColorUtils.accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: Constants.fontSizeXLarge,
                    ),
                  ),
                  Text(
                    "dery",
                    style: TextStyle(
                      color: ColorUtils.secondaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: Constants.fontSizeXLarge,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.withOpacity(0.2),
            ),
            _isLoading
                ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ColorUtils.accentColor,
                    ),
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Привет, $_userName!",
                    style: TextStyle(
                      fontSize: Constants.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: ColorUtils.secondaryColor,
                    ),
                  ),
                ),
            SizedBox(height: 16),
            _buildMenuItem(
              context,
              icon: Icons.person_outline,
              title: "Мой профиль",
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.history,
              title: "История заказов",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrderHistoryPage()),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.card_giftcard,
              title: "Бонусы",
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to bonuses page
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Бонусы скоро будут доступны")),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.info_outline,
              title: "О нас",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutPage()),
                );
              },
            ),
            Spacer(),
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.withOpacity(0.2),
            ),
            _buildMenuItem(
              context,
              icon: Icons.logout,
              title: "Выйти из аккаунта",
              onTap: () async {
                // Clear user data and redirect to login page
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool("isLoggedIn", false);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (route) => false,
                );
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: ColorUtils.secondaryColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: ColorUtils.secondaryColor,
          fontSize: Constants.fontSizeRegular,
        ),
      ),
      onTap: onTap,
    );
  }
}
