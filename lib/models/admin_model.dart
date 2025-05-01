// lib/models/admin_model.dart

class AdminModel {
  final int id;
  final String userName;
  final String email;
  final String companyName;
  final int delivery; // Delivery fee
  final String systemId;
  final String systemToken;
  final String systemTokenUpdatedTime;
  final String smsToken;
  final String smsEmail;
  final String smsMessage;
  final String smsPassword;
  final String smsTokenUpdatedTime;
  final String paymentUsername;
  final String paymentPassword;
  final int users;
  final int? subscriptionTierId;
  final String subscriptionStatus;
  final String? subscriptionExpiresAt;
  final bool isAccessRestricted;
  final int monthlySubscriptionFee;
  final String createdAt;
  final String updatedAt;

  AdminModel({
    required this.id,
    required this.userName,
    required this.email,
    required this.companyName,
    required this.delivery,
    required this.systemId,
    required this.systemToken,
    required this.systemTokenUpdatedTime,
    required this.smsToken,
    required this.smsEmail,
    required this.smsMessage,
    required this.smsPassword,
    required this.smsTokenUpdatedTime,
    required this.paymentUsername,
    required this.paymentPassword,
    required this.users,
    this.subscriptionTierId,
    required this.subscriptionStatus,
    this.subscriptionExpiresAt,
    required this.isAccessRestricted,
    required this.monthlySubscriptionFee,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id'] ?? 0,
      userName: json['user_name'] ?? '',
      email: json['email'] ?? '',
      companyName: json['company_name'] ?? '',
      delivery: _parseIntSafely(json['delivery']),
      systemId: json['system_id'] ?? '',
      systemToken: json['system_token'] ?? '',
      systemTokenUpdatedTime: json['system_token_updated_time'] ?? '',
      smsToken: json['sms_token'] ?? '',
      smsEmail: json['sms_email'] ?? '',
      smsMessage: json['sms_message'] ?? '',
      smsPassword: json['sms_password'] ?? '',
      smsTokenUpdatedTime: json['sms_token_updated_time'] ?? '',
      paymentUsername: json['payment_username'] ?? '',
      paymentPassword: json['payment_password'] ?? '',
      users: json['users'] ?? 0,
      subscriptionTierId: json['subscription_tier_id'],
      subscriptionStatus: json['subscription_status'] ?? '',
      subscriptionExpiresAt: json['subscription_expires_at'],
      isAccessRestricted: json['is_access_restricted'] ?? false,
      monthlySubscriptionFee: _parseIntSafely(json['monthly_subscription_fee']),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  // Safe parsing for integers with default as 0
  static int _parseIntSafely(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    try {
      return int.parse(value.toString());
    } catch (e) {
      return 0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'email': email,
      'company_name': companyName,
      'delivery': delivery,
      'system_id': systemId,
      'system_token': systemToken,
      'system_token_updated_time': systemTokenUpdatedTime,
      'sms_token': smsToken,
      'sms_email': smsEmail,
      'sms_message': smsMessage,
      'sms_password': smsPassword,
      'sms_token_updated_time': smsTokenUpdatedTime,
      'payment_username': paymentUsername,
      'payment_password': paymentPassword,
      'users': users,
      'subscription_tier_id': subscriptionTierId,
      'subscription_status': subscriptionStatus,
      'subscription_expires_at': subscriptionExpiresAt,
      'is_access_restricted': isAccessRestricted,
      'monthly_subscription_fee': monthlySubscriptionFee,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
