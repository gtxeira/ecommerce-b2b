import 'package:ecommerce_b2b/modules/shared_kernel/model/entity.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_variant_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/logistics/value_objects/weight.dart';

class ProductVariant extends Entity<ProductVariantId> {
  final String color;
  final String size;
  final String voltage;
  final String variantSku;
  final Money? price;
  final bool sameAsParent;

  /// Peso da variante, usado pela API no cálculo de frete.
  final Weight? weight;

  ProductVariant({
    required ProductVariantId id,
    required this.color,
    required this.size,
    required this.voltage,
    required this.variantSku,
    this.price,
    this.sameAsParent = true,
    this.weight,
  }) : super(id);

  /// `Cinza · 15pol · Bivolt`, ignorando campos vazios.
  String get label => [
    if (color.isNotEmpty) color,
    if (size.isNotEmpty) size,
    if (voltage.isNotEmpty) voltage,
  ].join(' · ');
}
