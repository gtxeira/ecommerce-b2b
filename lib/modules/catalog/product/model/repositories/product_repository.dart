import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_variant_id.dart';

/// Contrato do repositório de produtos.
abstract class ProductRepository {
  /// Salva um produto.
  Future<void> save(Product product);

  /// Exclui um produto.
  Future<void> delete(ProductId id);

  /// Exclui uma variante específica de um produto.
  Future<void> deleteVariant(ProductId productId, ProductVariantId variantId);

  /// Retorna os produtos, opcionalmente filtrados por nome ou SKU na API.
  Future<List<Product>> getAll({String? query});
}
