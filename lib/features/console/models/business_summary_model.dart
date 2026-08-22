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
      email: json['email'] as String?,
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      ownerUserId: json['owner_user_id'] as String?,
      industry: json['industry'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      registrationNumber: json['registration_number'] as String?,
      logoUrl: json['logo_url'] as String?,
      coverUrl: json['cover_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_name': businessName,
        'email': email,
        'subscription_tier': subscriptionTier,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'owner_user_id': ownerUserId,
        'industry': industry,
        'phone': phone,
        'website': website,
        'city': city,
        'country': country,
        'registration_number': registrationNumber,
        'logo_url': logoUrl,
        'cover_url': coverUrl,
      };

  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool get isTrial => status == 'trial';
}
