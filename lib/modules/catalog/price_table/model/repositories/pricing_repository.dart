import 'package:ecommerce_b2b/modules/catalog/price_table/model/price_tier.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/pricing_preview.dart';

abstract class PricingRepository {
  /// Simula o preço de um item sem gravar nada.
  Future<PricingPreview> preview({
    required String companyId,
    required String productId,
    required int quantity,
    String? priceTableId,
    String? variantId,
  });

  /// Faixas de desconto elegíveis para a empresa (UF) da sessão/consulta.
  Future<List<PriceTier>> findPriceTiers({String? companyId});
}
