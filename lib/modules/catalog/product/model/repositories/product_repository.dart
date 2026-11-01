import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product_page.dart';
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

  /// Retorna uma página de produtos, com o filtro aplicado pela API.
  Future<ProductPage> getPage({String? query, int page = 1, int pageSize = 20});

  /// Retorna todos os produtos, percorrendo as páginas da API. Usado pelas telas que
  /// ainda precisam do catálogo inteiro (estoque, orçamento e packing).
  Future<List<Product>> getAll({String? query});
}
