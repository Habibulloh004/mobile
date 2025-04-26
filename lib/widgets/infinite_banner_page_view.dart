// lib/widgets/infinite_banner_page_view.dart
import 'package:flutter/material.dart';

/// A custom PageView that creates an illusion of infinite scrolling
/// by duplicating the first item after the last item and the last item
/// before the first item to create a seamless loop
class InfiniteBannerPageView extends StatefulWidget {
  final PageController controller;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Function(int) onPageChanged;
  final bool reverse;
  final Duration animationDuration;
  final Curve animationCurve;

  const InfiniteBannerPageView({
    Key? key,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    required this.onPageChanged,
    this.reverse = false,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  }) : super(key: key);

  @override
  State<InfiniteBannerPageView> createState() => _InfiniteBannerPageViewState();
}

class _InfiniteBannerPageViewState extends State<InfiniteBannerPageView> {
  late int _realItemCount;
  bool _isHandlingScroll = false;
  int _currentPage = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _realItemCount = widget.itemCount;

    // Setup initial position after first frame is built
    if (_realItemCount > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.controller.hasClients && !_isInitialized) {
          // Start at position 1 (first real item)
          widget.controller.jumpToPage(1);
          _isInitialized = true;
          debugPrint("InfiniteBannerPageView initialized at page 1");
        }
      });
    }

    // Add listener to handle looping
    widget.controller.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(InfiniteBannerPageView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle item count changes
    if (oldWidget.itemCount != widget.itemCount) {
      setState(() {
        _realItemCount = widget.itemCount;
        debugPrint(
          "InfiniteBannerPageView item count changed to $_realItemCount",
        );

        // Re-initialize if needed
        if (_realItemCount > 1 &&
            !_isInitialized &&
            widget.controller.hasClients) {
          widget.controller.jumpToPage(1);
          _isInitialized = true;
          debugPrint("InfiniteBannerPageView re-initialized at page 1");
        }
      });
    }

    // Update controller listener if controller changes
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleScroll);
      widget.controller.addListener(_handleScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    if (_isHandlingScroll ||
        _realItemCount <= 1 ||
        !widget.controller.hasClients) {
      return;
    }

    final page = widget.controller.page;
    if (page == null) return;

    final currentPage = page.round();

    // Debug the current page position
    debugPrint("Current page position: $page (rounded: $currentPage)");

    // If we're at the first duplicate page (which shows the last real item)
    if (currentPage == 0) {
      _isHandlingScroll = true;
      debugPrint(
        "Reached first dummy page (0), jumping to last real page ($_realItemCount)",
      );

      // Jump immediately to maintain scroll momentum
      widget.controller.jumpToPage(_realItemCount);
      Future.delayed(Duration.zero, () {
        _isHandlingScroll = false;
      });
    }
    // If we're at the last duplicate page (which shows the first real item)
    else if (currentPage == _realItemCount + 1) {
      _isHandlingScroll = true;
      debugPrint(
        "Reached last dummy page (${_realItemCount + 1}), jumping to first real page (1)",
      );

      // Jump immediately to maintain scroll momentum
      widget.controller.jumpToPage(1);
      Future.delayed(Duration.zero, () {
        _isHandlingScroll = false;
      });
    }
  }

  // Maps the internal page index to the user's item index
  int _getActualIndex(int viewIndex) {
    if (_realItemCount <= 1) return 0;

    if (viewIndex == 0) {
      // First dummy item shows the last real item
      return _realItemCount - 1;
    } else if (viewIndex == _realItemCount + 1) {
      // Last dummy item shows the first real item
      return 0;
    } else {
      // Regular mapping for real items
      return viewIndex - 1;
    }
  }

  // Total number of pages in the PageView (including dummy pages)
  int get _totalItemCount {
    return _realItemCount <= 1 ? _realItemCount : _realItemCount + 2;
  }

  @override
  Widget build(BuildContext context) {
    // For empty list
    if (_realItemCount == 0) {
      return Container();
    }

    // For single item
    if (_realItemCount == 1) {
      return PageView.builder(
        controller: widget.controller,
        itemCount: 1,
        reverse: widget.reverse,
        onPageChanged: (_) => widget.onPageChanged(0),
        itemBuilder: (context, _) => widget.itemBuilder(context, 0),
        physics: const NeverScrollableScrollPhysics(),
      );
    }

    // Debug print to help diagnose issues
    debugPrint(
      "Building carousel with $_realItemCount real items, $_totalItemCount total pages (including dummy pages)",
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          debugPrint("Scroll ended");
          if (_realItemCount > 1 && widget.controller.hasClients) {
            final page = widget.controller.page?.round() ?? 0;
            _currentPage = page;

            // Make sure we handle edge cases after scrolling ends
            if (page == 0 || page == _realItemCount + 1) {
              _handleScroll();
            }
          }
        }
        return false;
      },
      child: PageView.builder(
        controller: widget.controller,
        itemCount: _totalItemCount,
        reverse: widget.reverse,
        onPageChanged: (viewIndex) {
          debugPrint("Page changed to viewIndex: $viewIndex");
          // Only notify about real items' indices
          final userIndex = _getActualIndex(viewIndex);
          debugPrint("Mapped to userIndex: $userIndex");
          widget.onPageChanged(userIndex);
        },
        itemBuilder: (context, viewIndex) {
          // Get the actual index that corresponds to a real item
          final actualIndex = _getActualIndex(viewIndex);
          return widget.itemBuilder(context, actualIndex);
        },
      ),
    );
  }
}
