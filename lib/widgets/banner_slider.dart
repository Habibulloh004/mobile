// lib/widgets/banner_slider.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../providers/banner_provider.dart';
import '../models/banner_model.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import 'banner_detail_sheet.dart';
import 'infinite_banner_page_view.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({Key? key}) : super(key: key);

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  Timer? _autoPlayTimer;
  int _currentPage = 0;
  bool _autoPlayEnabled = false;

  @override
  void initState() {
    super.initState();
    // Check for available banners after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAutoScroll();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-check auto-scroll when dependencies change (like provider updates)
    _initAutoScroll();
  }

  void _initAutoScroll() {
    if (!mounted) return;

    final bannerProvider = Provider.of<BannerProvider>(context, listen: false);

    // Enable auto-play if there's more than one banner
    if (bannerProvider.banners.length > 1) {
      _startAutoPlay();
    } else {
      _stopAutoPlay();
    }
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    if (!mounted) return;

    // Don't restart if already running
    if (_autoPlayTimer != null && _autoPlayTimer!.isActive) {
      return;
    }

    // Get current banner count
    final bannerProvider = Provider.of<BannerProvider>(context, listen: false);
    if (bannerProvider.banners.length <= 1) {
      return; // Don't auto-play for 0 or 1 banners
    }

    _stopAutoPlay(); // Cancel any existing timer first
    _autoPlayEnabled = true;

    // Auto-play every 5 seconds
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        _stopAutoPlay();
        return;
      }

      // Log to verify timer is firing
      debugPrint('Auto-play timer fired');

      // Check if we can scroll
      if (!_pageController.hasClients) {
        debugPrint('PageController has no clients');
        return;
      }

      // Directly advance to next page - forcing a real page change
      final nextPageIndex = _pageController.page!.round() + 1;

      // Log the page change attempt
      debugPrint(
        'Auto-scrolling from page ${_pageController.page!.round()} to $nextPageIndex',
      );

      _pageController.animateToPage(
        nextPageIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });

    debugPrint('Auto-play timer started');
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    _autoPlayEnabled = false;
    debugPrint('Auto-play timer stopped');
  }

  void _showBannerDetails(BuildContext context, BannerModel banner) {
    // Temporarily stop auto-play while details are shown
    _stopAutoPlay();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BannerDetailSheet(banner: banner),
    ).then((_) {
      if (!mounted) return;

      // Resume auto-play when bottom sheet is closed, only if there are multiple banners
      final bannerProvider = Provider.of<BannerProvider>(
        context,
        listen: false,
      );
      if (bannerProvider.banners.length > 1) {
        _startAutoPlay();
      }
    });
  }

  Widget _buildSingleBanner(BannerModel banner) {
    return GestureDetector(
      onTap: () => _showBannerDetails(context, banner),
      child: _buildBannerItem(banner, true),
    );
  }

  Widget _buildBannerItem(BannerModel banner, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[300],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Banner image with parallax effect
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: isActive ? -10 : 0,
              right: isActive ? -10 : 0,
              top: 0,
              bottom: 0,
              child: Hero(
                tag: 'banner_${banner.id}',
                child: Image.network(
                  banner.image,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Image.asset(
                        "assets/images/no_image.png",
                        fit: BoxFit.cover,
                      ),
                ),
              ),
            ),

            // Title overlay with animated opacity
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isActive ? 1.0 : 0.7,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isActive)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: 1.0,
                          child: Text(
                            banner.body.length > 50
                                ? banner.body.substring(0, 50) + '...'
                                : banner.body,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // "Learn More" indicator
            if (isActive)
              Positioned(
                right: 16,
                bottom: 10,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: ColorUtils.accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Подробнее",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BannerProvider>(
      builder: (context, bannerProvider, child) {
        if (bannerProvider.isLoading) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  ColorUtils.accentColor,
                ),
              ),
            ),
          );
        }

        if (bannerProvider.hasError) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: ColorUtils.errorColor),
                  const SizedBox(height: 8),
                  Text(
                    bannerProvider.errorMessage,
                    style: TextStyle(color: ColorUtils.errorColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (bannerProvider.banners.isEmpty) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                "No banners available",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: Constants.fontSizeRegular,
                ),
              ),
            ),
          );
        }

        // Check if we need to enable auto-play (when banners.length changes)
        if (bannerProvider.banners.length > 1 && !_autoPlayEnabled) {
          // Schedule auto-play after this frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _startAutoPlay();
          });
        } else if (bannerProvider.banners.length <= 1 && _autoPlayEnabled) {
          // Schedule auto-play stop after this frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _stopAutoPlay();
          });
        }

        debugPrint(
          "Building BannerSlider with ${bannerProvider.banners.length} banners",
        );

        return Column(
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child:
                  bannerProvider.banners.length == 1
                      ? _buildSingleBanner(bannerProvider.banners.first)
                      : InfiniteBannerPageView(
                        controller: _pageController,
                        itemCount: bannerProvider.banners.length,
                        onPageChanged: (index) {
                          if (mounted) {
                            setState(() {
                              _currentPage = index;
                              bannerProvider.setCurrentIndex(index);
                            });
                          }
                        },
                        itemBuilder: (context, index) {
                          final banner = bannerProvider.banners[index];

                          // Calculate animation values for parallax effect
                          final pageOffset = (index - _currentPage).abs();
                          final scale =
                              1.0 - (pageOffset * 0.1).clamp(0.0, 0.3);
                          final opacity =
                              1.0 - (pageOffset * 0.5).clamp(0.0, 0.5);

                          return TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 300),
                            tween: Tween<double>(begin: 0.85, end: scale),
                            curve: Curves.easeOutCubic,
                            builder: (context, double scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: Opacity(
                                  opacity: opacity,
                                  child: GestureDetector(
                                    onTap:
                                        () =>
                                            _showBannerDetails(context, banner),
                                    child: _buildBannerItem(
                                      banner,
                                      index == _currentPage,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
            ),

            // Only show page indicators when there are multiple banners
            if (bannerProvider.banners.length > 1) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  bannerProvider.banners.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _currentPage == index ? 16 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color:
                          _currentPage == index
                              ? ColorUtils.accentColor
                              : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
