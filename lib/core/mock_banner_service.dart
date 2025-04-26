// lib/core/mock_banner_service.dart
import '../models/banner_model.dart';

/// A mock service to provide banner data for testing when API isn't available
class MockBannerService {
  /// Returns a list of mock banners for testing
  static Future<List<BannerModel>> getMockBanners() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    return [
      BannerModel(
        id: 1,
        adminId: 1,
        image: "https://kinsta.com/wp-content/uploads/2020/06/banner-sizes.jpg",
        title: "First banner",
        body:
            "Lorem ipsum dolor sit amet consectetur adipisicing elit. Fuga accusantium eveniet eius tenetur atque impedit, accusamus quidem aspernatur! Labore, quas veniam repellat recusandae omnis ut. Iste quisquam laudantium quidem officiis voluptatem adipisci rem, temporibus reprehenderit facere veritatis excepturi? Magnam, expedita. Laborum fuga iusto quaerat totam? Exercitationem dolorum, ut nobis harum cupiditate distinctio accusamus, sunt delectus ratione, ex veritatis! Quisquam odio iure pariatur magni qui aperiam vero, similique velit cumque enim consequatur voluptatum eum atque mollitia eligendi, deleniti aut, libero blanditiis quia quos laudantium laboriosam. Eveniet doloremque nobis, sed corporis voluptate sit dolore, veniam animi ipsum saepe ducimus magnam, quo itaque.",
        createdAt: "2025-04-26T06:12:17.385854Z",
        updatedAt: "2025-04-26T06:12:17.385854Z",
      ),
      BannerModel(
        id: 2,
        adminId: 1,
        image: "https://www.bannerstack.com/assets/header/examples-hero.jpg",
        title: "Summer Sale",
        body:
            "Enjoy our summer promotions with discounts up to 50% on selected items! Don't miss out on these amazing deals. Visit our store today and discover a wide range of products at incredible prices. Limited time offer, act now before it's too late!",
        createdAt: "2025-04-26T06:42:21.248859Z",
        updatedAt: "2025-04-26T06:42:21.248859Z",
      ),
      BannerModel(
        id: 3,
        adminId: 1,
        image: "https://kinsta.com/wp-content/uploads/2020/06/banner-sizes.jpg",
        title: "New Menu Items",
        body:
            "We're excited to introduce our new menu items! Try our delicious new burgers, fresh salads, and mouthwatering desserts. Our chefs have crafted these recipes with the finest ingredients to ensure an unforgettable dining experience. Come visit us today and treat your taste buds to something special.",
        createdAt: "2025-04-26T07:15:30.248859Z",
        updatedAt: "2025-04-26T07:15:30.248859Z",
      ),
      BannerModel(
        id: 4,
        adminId: 1,
        image:
            "https://blog.hubspot.com/hs-fs/hubfs/Ecommerce%20Banner%20Example%20-%20DSW.png?width=650&name=Ecommerce%20Banner%20Example%20-%20DSW.png",
        title: "Free Delivery",
        body:
            "Enjoy free delivery on all orders over 20! Order your favorite meals from the comfort of your home and have them delivered straight to your door at no extra cost. Take advantage of this special offer today and treat yourself to a hassle-free dining experience.",
        createdAt: "2025-04-26T08:30:15.248859Z",
        updatedAt: "2025-04-26T08:30:15.248859Z",
      ),
    ];
  }

  /// Returns a list of banner data in the format expected from the API
  static Future<Map<String, dynamic>> getMockBannerResponse() async {
    final banners = await getMockBanners();
    return {
      "data": banners.map((banner) => banner.toJson()).toList(),
      "status": "success",
    };
  }
}
