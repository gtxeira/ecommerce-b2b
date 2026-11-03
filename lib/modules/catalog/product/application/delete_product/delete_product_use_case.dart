import 'package:ecommerce_b2b/modules/catalog/product/model/repositories/product_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';

/// Exclusão de produto. A API decide se há vínculos ativos e devolve o erro.
class DeleteProductUseCase {
  final ProductRepository _productRepository;

  DeleteProductUseCase(this._productRepository);

  Future<Result<void, Exception>> execute(ProductId productId) async {
    try {
      await _productRepository.delete(productId);
      return Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}
