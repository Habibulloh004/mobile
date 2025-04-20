import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorUtils.bodyColor,
      appBar: AppBar(
        backgroundColor: ColorUtils.bodyColor,
        elevation: 0,
        title: Text(
          "О нас",
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App logo and name
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: ColorUtils.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "F",
                                style: TextStyle(
                                  color: ColorUtils.accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 36,
                                ),
                              ),
                              TextSpan(
                                text: "d",
                                style: TextStyle(
                                  color: ColorUtils.secondaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 36,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
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
                    SizedBox(height: 8),
                    Text(
                      "Версия ${Constants.appVersion}",
                      style: TextStyle(
                        fontSize: Constants.fontSizeRegular,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // About us text
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorUtils.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "О нашей компании",
                      style: TextStyle(
                        fontSize: Constants.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        color: ColorUtils.secondaryColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam euismod, nisl eget aliquam ultricies, nunc nisl ultricies nunc, eget ultricies nisl nisl eget nisl. Nullam euismod, nisl eget aliquam ultricies, nunc nisl ultricies nunc, eget ultricies nisl nisl eget nisl.",
                      style: TextStyle(
                        fontSize: Constants.fontSizeRegular,
                        color: ColorUtils.secondaryColor,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam euismod, nisl eget aliquam ultricies, nunc nisl ultricies nunc, eget ultricies nisl nisl eget nisl.",
                      style: TextStyle(
                        fontSize: Constants.fontSizeRegular,
                        color: ColorUtils.secondaryColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Contact information
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorUtils.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Контактная информация",
                      style: TextStyle(
                        fontSize: Constants.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        color: ColorUtils.secondaryColor,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Phone
                    _buildContactItem(
                      context,
                      icon: Icons.phone,
                      title: "+99899 999-99-99",
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: "+998999999999"));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Номер телефона скопирован")),
                        );
                      },
                    ),

                    SizedBox(height: 12),

                    // Email
                    _buildContactItem(
                      context,
                      icon: Icons.email,
                      title: "Foodery@gmail.com",
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: "Foodery@gmail.com"),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Email скопирован")),
                        );
                      },
                    ),

                    SizedBox(height: 12),

                    // Address
                    _buildContactItem(
                      context,
                      icon: Icons.location_on,
                      title: "Город Ташкент Чиланзарский р-н Улица Бунёда 1а",
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                "Город Ташкент Чиланзарский р-н Улица Бунёда 1а",
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Адрес скопирован")),
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Social media and download buttons
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorUtils.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Мы в социальных сетях",
                      style: TextStyle(
                        fontSize: Constants.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        color: ColorUtils.secondaryColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSocialButton(
                          context,
                          icon: Icons.telegram,
                          title: "Telegram",
                          onTap: () {
                            // TODO: Open Telegram channel
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Открытие Telegram будет доступно в следующей версии",
                                ),
                              ),
                            );
                          },
                        ),
                        _buildSocialButton(
                          context,
                          icon: Icons.facebook,
                          title: "Facebook",
                          onTap: () {
                            // TODO: Open Facebook page
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Открытие Facebook будет доступно в следующей версии",
                                ),
                              ),
                            );
                          },
                        ),
                        _buildSocialButton(
                          context,
                          icon: Icons.camera_alt,
                          title: "Instagram",
                          onTap: () {
                            // TODO: Open Instagram page
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Открытие Instagram будет доступно в следующей версии",
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Return button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: ColorUtils.accentColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Вернуться',
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

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: ColorUtils.accentColor, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: Constants.fontSizeRegular,
                  color: ColorUtils.secondaryColor,
                ),
              ),
            ),
            Icon(Icons.content_copy, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: ColorUtils.accentColor, size: 28),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: Constants.fontSizeSmall,
                color: ColorUtils.secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
