// =============================================================================
// BusinessSummaryModel
// Maps columns from the `admin_tenant_view` Supabase secure view.
// =============================================================================

class BusinessSummaryModel {
  final String id;
  final String businessName;
  final String? email;
  final String subscriptionTier;
  final String status; // 'active' | 'suspended' | 'trial'
  final DateTime createdAt;
  final String? ownerUserId;
  
  // New Business Profile fields
  final String? industry;
  final String? phone;
  final String? website;
  final String? city;
  final String? country;
  final String? registrationNumber;
  final String? logoUrl;
  final String? coverUrl;

  const BusinessSummaryModel({
    required this.id,
    required this.businessName,
    this.email,
    required this.subscriptionTier,
    required this.status,
    required this.createdAt,
    this.ownerUserId,
    this.industry,
    this.phone,
    this.website,
    this.city,
    this.country,
    this.registrationNumber,
    this.logoUrl,
    this.coverUrl,
  });

  factory BusinessSummaryModel.fromJson(Map<String, dynamic> json) {
    return BusinessSummaryModel(
      id: json['id'] as String,
      businessName: json['business_name'] as String? ?? 'Unnamed',
      email: json['business_email'] as String?,
      subscriptionTier: json['business_subscription_tier'] as String? ?? 'free',
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      ownerUserId: json['owner_user_id'] as String?,
      industry: json['business_industry'] as String?,
      phone: json['business_phone'] as String?,
      website: json['business_website'] as String?,
      city: json['business_city'] as String?,
      country: json['business_country'] as String?,
      registrationNumber: json['business_registration_number'] as String?,
      logoUrl: json['business_logo_url'] as String?,
      coverUrl: json['business_cover_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_name': businessName,
        'business_email': email,
        'business_subscription_tier': subscriptionTier,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'owner_user_id': ownerUserId,
        'business_industry': industry,
        'business_phone': phone,
        'business_website': website,
        'business_city': city,
        'business_country': country,
        'business_registration_number': registrationNumber,
        'business_logo_url': logoUrl,
        'business_cover_url': coverUrl,
      };

  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool get isTrial => status == 'trial';
}
