import 'package:flutter/material.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import 'main_page.dart';

class NotFoundPage extends StatelessWidget {
  final String message;

  const NotFoundPage({Key? key, this.message = 'Страница не найдена'})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorUtils.bodyColor,
      appBar: AppBar(
        backgroundColor: ColorUtils.bodyColor,
        elevation: 0,
        title: Text.rich(
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
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorUtils.secondaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 404 Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: ColorUtils.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    "404",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: ColorUtils.secondaryColor,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Error message
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Constants.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: ColorUtils.secondaryColor,
                ),
              ),

              SizedBox(height: 16),

              // Detailed message
              Text(
                'Запрашиваемая страница не существует или была перемещена',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Constants.fontSizeRegular,
                  color: Colors.grey[600],
                ),
              ),

              SizedBox(height: 32),

              // Return to home button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => MainPage()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorUtils.buttonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Вернуться на главную',
                    style: TextStyle(
                      fontSize: Constants.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Go back button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: ColorUtils.accentColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Назад',
                    style: TextStyle(
                      color: ColorUtils.accentColor,
                      fontSize: Constants.fontSizeRegular,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
