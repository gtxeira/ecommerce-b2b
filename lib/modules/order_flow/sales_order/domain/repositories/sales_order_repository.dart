import 'package:ecommerce_b2b/modules/order_flow/sales_order/domain/sales_order.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/order_id.dart';

abstract class SalesOrderRepository {
  Future<void> save(SalesOrder order);

  Future<SalesOrder?> getById(OrderId id);

  Future<List<SalesOrder>> getAll();
  
  Future<List<SalesOrder>> findByCompanyId(CompanyId companyId);

  Future<List<SalesOrder>> findByStatus(String status);
}
