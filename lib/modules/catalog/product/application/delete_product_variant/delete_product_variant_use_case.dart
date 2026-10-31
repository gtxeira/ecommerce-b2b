import 'package:ecommerce_b2b/modules/catalog/product/domain/repositories/product_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/product_variant_id.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';

/// Exclusão de variante. A API valida o vínculo e devolve o erro.
class DeleteProductVariantUseCase {
  final ProductRepository _productRepository;

  DeleteProductVariantUseCase(this._productRepository);

  Future<Result<void, Exception>> execute(
    ProductId productId,
    ProductVariantId variantId,
  ) async {
    try {
      await _productRepository.deleteVariant(productId, variantId);
      return Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}
