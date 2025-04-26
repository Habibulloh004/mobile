import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:poster_app/models/product_model.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../utils/color_utils.dart';
import '../constant/index.dart';
import '../helpers/index.dart';
import '../widgets/search_bar_widget.dart';
import 'product_page.dart';
import 'product_detail_page.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;

  const SearchPage({Key? key, this.initialQuery}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showCategoriesOnly = false;
  bool _showProductsOnly = false;

  @override
  void initState() {
    super.initState();

    // Set initial query if provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;

      // Schedule the search after the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    searchProvider.globalSearch(_searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorUtils.bodyColor,
      appBar: AppBar(
        backgroundColor: ColorUtils.bodyColor,
        elevation: 0,
        title: Text(
          "Поиск",
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
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(16),
            child: SearchBarWidget(
              controller: _searchController,
              onChanged: (value) => _performSearch(),
              hintText: "Найти категории и товары...",
              autoFocus: widget.initialQuery == null,
              onClear: () {
                Provider.of<SearchProvider>(
                  context,
                  listen: false,
                ).clearSearch();
              },
            ),
          ),

          // Filter chips
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Consumer<SearchProvider>(
                    builder: (context, searchProvider, child) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: Text('Все'),
                              selected:
                                  !_showCategoriesOnly && !_showProductsOnly,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _showCategoriesOnly = false;
                                    _showProductsOnly = false;
                                  });
                                  _performSearch();
                                }
                              },
                              backgroundColor: ColorUtils.primaryColor,
                              selectedColor: ColorUtils.accentColor.withOpacity(
                                0.2,
                              ),
                              checkmarkColor: ColorUtils.accentColor,
                            ),
                            SizedBox(width: 8),
                            FilterChip(
                              label: Text('Категории'),
                              selected: _showCategoriesOnly,
                              onSelected: (selected) {
                                setState(() {
                                  _showCategoriesOnly = selected;
                                  if (selected) _showProductsOnly = false;
                                });
                                _performSearch();
                              },
                              backgroundColor: ColorUtils.primaryColor,
                              selectedColor: ColorUtils.accentColor.withOpacity(
                                0.2,
                              ),
                              checkmarkColor: ColorUtils.accentColor,
                            ),
                            SizedBox(width: 8),
                            FilterChip(
                              label: Text('Товары'),
                              selected: _showProductsOnly,
                              onSelected: (selected) {
                                setState(() {
                                  _showProductsOnly = selected;
                                  if (selected) _showCategoriesOnly = false;
                                });
                                _performSearch();
                              },
                              backgroundColor: ColorUtils.primaryColor,
                              selectedColor: ColorUtils.accentColor.withOpacity(
                                0.2,
                              ),
                              checkmarkColor: ColorUtils.accentColor,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Results counter
          Consumer<SearchProvider>(
            builder: (context, searchProvider, child) {
              if (searchProvider.query.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Введите запрос для поиска",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: Constants.fontSizeRegular,
                    ),
                  ),
                );
              }

              // Filter results based on selected chips
              List<SearchResult> filteredResults = searchProvider.searchResults;
              if (_showCategoriesOnly) {
                filteredResults =
                    filteredResults
                        .where(
                          (result) => result.type == SearchResultType.category,
                        )
                        .toList();
              } else if (_showProductsOnly) {
                filteredResults =
                    filteredResults
                        .where(
                          (result) => result.type == SearchResultType.product,
                        )
                        .toList();
              }

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Результаты поиска",
                      style: TextStyle(
                        fontSize: Constants.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        color: ColorUtils.secondaryColor,
                      ),
                    ),
                    Text(
                      "Найдено: ${filteredResults.length}",
                      style: TextStyle(
                        fontSize: Constants.fontSizeRegular,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Results list
          Expanded(
            child: Consumer<SearchProvider>(
              builder: (context, searchProvider, child) {
                if (searchProvider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorUtils.accentColor,
                      ),
                    ),
                  );
                }

                if (searchProvider.query.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/search.svg',
                          width: 32,
                          height: 32, // Optional colorization
                          fit: BoxFit.cover,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Начните вводить запрос\nдля поиска категорий и товаров",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: Constants.fontSizeMedium,
                            color: ColorUtils.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter results based on selected chips
                List<SearchResult> filteredResults =
                    searchProvider.searchResults;
                if (_showCategoriesOnly) {
                  filteredResults =
                      filteredResults
                          .where(
                            (result) =>
                                result.type == SearchResultType.category,
                          )
                          .toList();
                } else if (_showProductsOnly) {
                  filteredResults =
                      filteredResults
                          .where(
                            (result) => result.type == SearchResultType.product,
                          )
                          .toList();
                }

                if (filteredResults.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Ничего не найдено",
                          style: TextStyle(
                            fontSize: Constants.fontSizeMedium,
                            color: ColorUtils.secondaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Попробуйте изменить параметры поиска",
                          style: TextStyle(
                            fontSize: Constants.fontSizeRegular,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredResults.length,
                  itemBuilder: (context, index) {
                    final result = filteredResults[index];
                    return _buildSearchResultItem(result);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(SearchResult result) {
    final bool isCategory = result.type == SearchResultType.category;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (isCategory) {
            // Navigate to category products
            debugPrint(
              '🔍 Navigating to category: ${result.name} (ID: ${result.id})',
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ProductPage(
                      categoryId: result.id,
                      categoryName: result.name,
                    ),
              ),
            ).then((_) => debugPrint('⬅️ Returned from category page'));
          } else {
            // For products, ensure the product data is accessible to ProductProvider
            final productProvider = Provider.of<ProductProvider>(
              context,
              listen: false,
            );
            final product = result.data as ProductModel;

            // Use the new addProduct method to ensure the product is in the provider
            productProvider.addProduct(product);

            // Now navigate to product details
            debugPrint(
              '🔍 Navigating to product: ${result.name} (ID: ${result.id})',
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(productId: result.id),
              ),
            ).then((_) => debugPrint('⬅️ Returned from product detail page'));
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Result image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: ColorUtils.primaryColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    result.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        "assets/images/no_image.png",
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),

              SizedBox(width: 16),

              // Result info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCategory ? result.name : cleanProductName(result.name),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Constants.fontSizeRegular,
                        color: ColorUtils.secondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isCategory
                                    ? ColorUtils.primaryColor
                                    : ColorUtils.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isCategory ? "Категория" : "Товар",
                            style: TextStyle(
                              fontSize: Constants.fontSizeSmall,
                              color:
                                  isCategory
                                      ? ColorUtils.secondaryColor
                                      : ColorUtils.accentColor,
                            ),
                          ),
                        ),

                        if (!isCategory) ...[
                          SizedBox(width: 8),
                          Text(
                            formatPrice((result.data as dynamic).price),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: Constants.fontSizeSmall,
                              color: ColorUtils.accentColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Navigation arrow
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
