import 'package:ecommerce_b2b/modules/catalog/product/domain/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/domain/repositories/product_repository.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';

class GetProductsUseCase {
  final ProductRepository _productRepository;

  GetProductsUseCase(this._productRepository);

  /// O filtro de busca é da API: o cliente só repassa o termo em `?query`.
  Future<Result<List<Product>, Exception>> execute({String? query}) async {
    try {
      return Success(await _productRepository.getAll(query: query));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }
}
