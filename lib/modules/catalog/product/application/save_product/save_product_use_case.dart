import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/repositories/product_repository.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';

class SaveProductUseCase {
  final ProductRepository _productRepository;

  SaveProductUseCase(this._productRepository);

  Future<Result<void, Exception>> execute(Product product) async {
    try {
      await _productRepository.save(product);
      return Success(null);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }
}
