import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product_page.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/repositories/product_repository.dart';

class GetProductsUseCase {
  final ProductRepository _productRepository;

  GetProductsUseCase(this._productRepository);

  /// Busca uma página. O filtro e a paginação são da API: o cliente só repassa o termo,
  /// a página e o tamanho em `?query`, `?page` e `?pageSize`.
  Future<Result<ProductPage, Exception>> executePage({
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      return Success(
        await _productRepository.getPage(
          query: query,
          page: page,
          pageSize: pageSize,
        ),
      );
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }
}
