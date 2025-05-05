import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:poster_app/core/api_service.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import '../models/restaurant_info_model.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  RestaurantInfoModel? _restaurantInfo;
  String _errorMessage = '';
  String _formattedPhone = '';

  @override
  void initState() {
    super.initState();
    _loadRestaurantInfo();
  }

  Future<void> _loadRestaurantInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final info = await _apiService.getRestaurantInfo();

      setState(() {
        _restaurantInfo = info;
        _isLoading = false;

        // Format phone number if available
        if (_restaurantInfo?.contacts?.phone != null &&
            _restaurantInfo!.contacts!.phone!.isNotEmpty) {
          _formatPhoneNumber(_restaurantInfo!.contacts!.phone!);
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load restaurant information: $e';
        _isLoading = false;
      });
    }
  }

  // Phone number formatter
  void _formatPhoneNumber(String phone) {
    if (phone.isEmpty) return;

    // Try to format the phone number for display in the format +998 (93) 520 40 50
    try {
      String cleaned = phone.replaceAll(RegExp(r'\D'), '');

      // Ensure we have enough digits to format properly
      if (cleaned.length >= 12) {
        // Format as +998 (93) 520 40 50
        _formattedPhone =
            "+${cleaned.substring(0, 3)} (${cleaned.substring(3, 5)}) ${cleaned.substring(5, 8)} ${cleaned.substring(8, 10)} ${cleaned.substring(10, 12)}";
      } else {
        _formattedPhone = phone; // Fallback to original
      }
    } catch (e) {
      _formattedPhone = phone; // Fallback to original
    }
  }

  // Helper method to ensure URL has correct format
  String _ensureValidUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    } else {
      return 'https://$url';
    }
  }

  // Helper method to launch social media URL directly in browser
  Future<void> _launchSocialMedia(String url, String platform) async {
    if (url.isEmpty) return;

    debugPrint('Attempting to launch $platform URL: $url');

    try {
      // Format URL properly based on the platform
      String formattedUrl = _formatSocialMediaUrl(url, platform);
      final Uri uri = Uri.parse(formattedUrl);

      // Try to launch in app first
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      // If that fails, try launching in browser
      if (!launched && mounted) {
        // Try browser as fallback
        final browserUri = Uri.parse(_ensureValidUrl(url));
        await launchUrl(browserUri, mode: LaunchMode.externalApplication).then((
          success,
        ) {
          if (!success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open $platform: $url')),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error launching $platform URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening $platform: $e')));
      }
    }
  }

  // New helper method to format social media URLs correctly
  String _formatSocialMediaUrl(String url, String platform) {
    // Remove any http/https prefix for consistent formatting
    String cleanUrl = url.replaceAll(RegExp(r'https?://'), '');

    switch (platform.toLowerCase()) {
      case 'telegram':
        // Handle Telegram URLs
        if (cleanUrl.startsWith('t.me/') ||
            cleanUrl.startsWith('telegram.me/')) {
          return 'https://$cleanUrl';
        } else if (!cleanUrl.contains('t.me/') &&
            !cleanUrl.contains('telegram.me/')) {
          // If it's just a username without domain
          if (cleanUrl.startsWith('@')) {
            cleanUrl = cleanUrl.substring(1);
          }
          return 'https://t.me/$cleanUrl';
        }
        return _ensureValidUrl(url);

      case 'instagram':
        // Handle Instagram URLs
        if (cleanUrl.startsWith('instagram.com/') ||
            cleanUrl.startsWith('www.instagram.com/')) {
          return 'https://$cleanUrl';
        } else if (!cleanUrl.contains('instagram.com/')) {
          // If it's just a username without domain
          if (cleanUrl.startsWith('@')) {
            cleanUrl = cleanUrl.substring(1);
          }
          return 'https://instagram.com/$cleanUrl';
        }
        return _ensureValidUrl(url);

      case 'facebook':
        // Handle Facebook URLs
        if (cleanUrl.startsWith('facebook.com/') ||
            cleanUrl.startsWith('www.facebook.com/') ||
            cleanUrl.startsWith('fb.com/')) {
          return 'https://$cleanUrl';
        } else if (!cleanUrl.contains('facebook.com/') &&
            !cleanUrl.contains('fb.com/')) {
          // If it's just a username without domain
          if (cleanUrl.startsWith('@')) {
            cleanUrl = cleanUrl.substring(1);
          }
          return 'https://facebook.com/$cleanUrl';
        }
        return _ensureValidUrl(url);

      default:
        // For other platforms, ensure URL has http/https
        return _ensureValidUrl(url);
    }
  }

  // Helper method to handle URL launch
  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;

    debugPrint('Attempting to launch URL: $url');

    try {
      // Parse URL
      final Uri uri = Uri.parse(url);

      // Launch directly in external app/browser
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening link: $e')));
      }
      debugPrint('Error launching URL: $e');
    }
  }

  // Helper method to launch phone call
  Future<void> _launchPhoneCall(String phone) async {
    final String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanPhone);

    try {
      await launchUrl(phoneUri);
    } catch (e) {
      debugPrint('Error launching phone call: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error making phone call: $e')));
      }
    }
  }

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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: ColorUtils.secondaryColor),
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await _apiService.refreshRestaurantInfo();
              _loadRestaurantInfo();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRestaurantInfo,
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ColorUtils.accentColor,
                    ),
                  ),
                )
                : _errorMessage.isNotEmpty
                ? _buildErrorView()
                : _restaurantInfo == null
                ? _buildEmptyView()
                : _buildAboutContent(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: ColorUtils.errorColor),
          SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: Constants.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: ColorUtils.secondaryColor,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Constants.fontSizeRegular,
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadRestaurantInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorUtils.accentColor,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No information available',
            style: TextStyle(
              fontSize: Constants.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: ColorUtils.secondaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Restaurant information is not available at the moment',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Constants.fontSizeRegular,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App logo and name
            Center(
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/images/appLogo.svg',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
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
                    _restaurantInfo?.text ?? "Информация отсутствует",
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

            // Contact information - only show if at least one contact is available
            if (_restaurantInfo?.contacts != null &&
                _restaurantInfo!.contacts!.hasAnyContact)
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

                    // Phone - only show if available
                    if (_restaurantInfo?.contacts?.phone != null &&
                        _restaurantInfo!.contacts!.phone!.isNotEmpty)
                      _buildContactItem(
                        context,
                        icon: Icons.phone,
                        title:
                            _formattedPhone.isNotEmpty
                                ? _formattedPhone
                                : _restaurantInfo!.contacts!.phone!,
                        onTap: () {
                          final phone = _restaurantInfo!.contacts!.phone!;
                          Clipboard.setData(ClipboardData(text: phone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Номер телефона скопирован"),
                            ),
                          );
                        },
                        onLongPress: () {
                          _launchPhoneCall(_restaurantInfo!.contacts!.phone!);
                        },
                      ),

                    // Email - only show if available
                    if (_restaurantInfo?.contacts?.gmail != null &&
                        _restaurantInfo!.contacts!.gmail!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top:
                              _restaurantInfo?.contacts?.phone != null ? 12 : 0,
                        ),
                        child: _buildContactItem(
                          context,
                          icon: Icons.email,
                          title: _restaurantInfo!.contacts!.gmail!,
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: _restaurantInfo!.contacts!.gmail!,
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Email скопирован")),
                            );
                          },
                          onLongPress: () {
                            _launchUrl(
                              "mailto:${_restaurantInfo!.contacts!.gmail!}",
                            );
                          },
                        ),
                      ),

                    // Address - only show if available
                    if (_restaurantInfo?.contacts?.location != null &&
                        _restaurantInfo!.contacts!.location!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: _buildContactItem(
                          context,
                          icon: Icons.location_on,
                          title: _restaurantInfo!.contacts!.location!,
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: _restaurantInfo!.contacts!.location!,
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Адрес скопирован")),
                            );
                          },
                          onLongPress: () {
                            // Open Google Maps with the location
                            _launchUrl(
                              "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_restaurantInfo!.contacts!.location!)}",
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

            SizedBox(height: 24),

            // Social media - only show if at least one social media is available
            if (_restaurantInfo?.socialMedia != null &&
                _restaurantInfo!.socialMedia!.hasAnySocialMedia)
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
                        // Telegram - only show if available
                        if (_restaurantInfo?.socialMedia?.telegram != null &&
                            _restaurantInfo!.socialMedia!.telegram!.isNotEmpty)
                          _buildSocialButton(
                            context,
                            icon: Icons.telegram,
                            title: "Telegram",
                            onTap: () {
                              _launchSocialMedia(
                                _restaurantInfo!.socialMedia!.telegram!,
                                "Telegram",
                              );
                            },
                          ),

                        // Facebook - only show if available
                        if (_restaurantInfo?.socialMedia?.facebook != null &&
                            _restaurantInfo!.socialMedia!.facebook!.isNotEmpty)
                          _buildSocialButton(
                            context,
                            icon: Icons.facebook,
                            title: "Facebook",
                            onTap: () {
                              _launchSocialMedia(
                                _restaurantInfo!.socialMedia!.facebook!,
                                "Facebook",
                              );
                            },
                          ),

                        // Instagram - only show if available
                        if (_restaurantInfo?.socialMedia?.instagram != null &&
                            _restaurantInfo!.socialMedia!.instagram!.isNotEmpty)
                          _buildSocialButton(
                            context,
                            icon: Icons.camera_alt,
                            title: "Instagram",
                            onTap: () {
                              _launchSocialMedia(
                                _restaurantInfo!.socialMedia!.instagram!,
                                "Instagram",
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

            // Add bottom padding for better scrolling experience
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
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
