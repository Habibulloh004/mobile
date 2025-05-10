import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      setState(() {
        _isLoggedIn = isLoggedIn;
        if (isLoggedIn) {
          _userName = prefs.getString('name') ?? "Пользователь";
        } else {
          _userName = "Гость";
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
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
              child: SvgPicture.asset(
                'assets/images/appLogo.svg',
                width: 30,
                height: 30, // Optional colorization
                fit: BoxFit.cover,
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
            _buildMenuItemSvg(
              context,
              iconPath: 'assets/images/profile.svg',
              title: "Мой профиль",
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            _buildMenuItemSvg(
              context,
              iconPath: 'assets/images/time.svg',
              title: "История заказов",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrderHistoryPage()),
                );
              },
            ),
            // _buildMenuItemSvg(
            //   context,
            //   iconPath: 'assets/images/bonus.svg',
            //   title: "Бонусы",
            //   onTap: () {
            //     Navigator.pop(context);
            //     // TODO: Navigate to bonuses page
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       SnackBar(content: Text("Бонусы скоро будут доступны")),
            //     );
            //   },
            // ),
            _buildMenuItemSvg(
              context,
              iconPath: 'assets/images/about-us.svg',
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
            _buildMenuItemSvg(
              context,
              iconPath:
                  _isLoggedIn
                      ? 'assets/images/logout.svg'
                      : 'assets/images/login.svg',
              title: _isLoggedIn ? "Выйти из аккаунта" : "Войти",
              onTap: () async {
                if (_isLoggedIn) {
                  // Logout functionality
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool("isLoggedIn", false);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
                  );
                } else {
                  // Login functionality
                  Navigator.pop(context);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
                  );
                }
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemSvg(
    BuildContext context, {
    required String iconPath,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 22,
        height: 22,
        child: SvgPicture.asset(
          iconPath,
          color: ColorUtils.secondaryColor,
          fit: BoxFit.contain,
        ),
      ),
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

  // Keep the original method as a fallback in case you need it
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
