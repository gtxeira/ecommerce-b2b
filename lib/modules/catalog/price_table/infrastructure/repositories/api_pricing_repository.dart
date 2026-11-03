import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/price_tier.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/pricing_preview.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/repositories/pricing_repository.dart';

class ApiPricingRepository implements PricingRepository {
  final ApiClient _api;

  ApiPricingRepository(this._api);

  @override
  Future<PricingPreview> preview({
    required String companyId,
    required String productId,
    required int quantity,
    String? priceTableId,
    String? variantId,
  }) async {
    final data = await _api.post(
      '/api/pricing/preview',
      data: {
        'companyId': companyId,
        'productId': productId,
        'quantity': quantity,
        if (priceTableId != null && priceTableId.isNotEmpty)
          'priceTableId': priceTableId,
        if (variantId != null && variantId.isNotEmpty) 'variantId': variantId,
      },
    );

    if (data is! Map) {
      throw StateError('Resposta inesperada ao simular o preço.');
    }

    return PricingPreview.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<List<PriceTier>> findPriceTiers({String? companyId}) async {
    final data = await _api.get(
      '/api/catalog/price-tiers',
      query: companyId == null ? null : {'companyId': companyId},
    );

    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => PriceTier.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
