import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';

/// Uma página da listagem de produtos, com os metadados de `meta.pagination`.
class ProductPage {
  final List<Product> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  const ProductPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
}
