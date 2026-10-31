import 'package:ecommerce_b2b/modules/shared_kernel/model/entity.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_variant_id.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product_variant.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';

/// Raiz do Agregado que representa um Produto no catálogo.
class Product extends Entity<ProductId> {
  /// Unidade de Manutenção de Estoque (SKU) principal.
  final String sku;
  /// Nome do produto.
  final String name;
  /// Descrição detalhada do produto.
  final String description;
  /// Preço base do produto.
  final Money basePrice;
  /// Indica se o produto está ativo para venda.
  final bool active;
  final List<ProductVariant> _variants;

  /// Construtor do Produto.
  Product({
    required ProductId id,
    required this.sku,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.active,
    List<ProductVariant>? variants,
  })  : _variants = variants ?? [],
        super(id);

  /// Lista de variantes (cores, tamanhos, voltagens) deste produto.
  List<ProductVariant> get variants => List.unmodifiable(_variants);

  /// Adiciona uma nova variante ao produto.
  void addVariant(ProductVariant variant) {
    _variants.add(variant);
  }

  /// Remove uma variante pelo ID. Retorna true se a variante foi encontrada e removida.
  bool removeVariant(ProductVariantId variantId) {
    final lengthBefore = _variants.length;
    _variants.removeWhere((v) => v.id == variantId);
    return _variants.length < lengthBefore;
  }
}
