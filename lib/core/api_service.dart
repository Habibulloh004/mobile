import 'package:dio/dio.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "https://joinposter.com/api"));

  Future<List<CategoryModel>> fetchCategories(String token) async {
    try {
      final response = await _dio.get('/menu.getCategories', queryParameters: {'token': token});
      if (response.statusCode == 200 && response.data["response"] != null) {
        final List<dynamic> data = response.data["response"];
        print(response.data["response"]);
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception("❌ Ошибка загрузки категорий: $e");
    }
  }

  Future<List<ProductModel>> fetchProducts(String token, int categoryId) async {
    try {
      final response = await _dio.get('/menu.getProducts', queryParameters: {'token': token, 'category_id': categoryId});
      if (response.statusCode == 200 && response.data["response"] != null) {
        print(response.data["response"]);
        final List<dynamic> data = response.data["response"];
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception("❌ Ошибка загрузки товаров: $e");
    }
  }
}
