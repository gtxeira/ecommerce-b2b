import 'package:ecommerce_b2b/modules/customer_portal/boleto/application/download_boleto/download_boleto_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_portal/boleto/model/repositories/boleto_repository.dart';
import 'package:ecommerce_b2b/modules/customer_portal/boleto/model/value_objects/boleto_copy.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:flutter_test/flutter_test.dart';

class MockBoletoRepository implements BoletoRepository {
  @override
  Future<BoletoCopy> getBoletoByOrder(OrderId orderId) async {
    return const BoletoCopy(
      barcode: '123456789',
      url: 'https://boleto.com/123',
    );
  }
}

void main() {
  late DownloadBoletoUseCase useCase;
  late MockBoletoRepository repository;

  setUp(() {
    repository = MockBoletoRepository();
    useCase = DownloadBoletoUseCase(repository);
  });

  // Deve retornar os dados do boleto para um pedido específico.
  test('should return boleto data for a given order', () async {
    const orderId = OrderId('o1');
    final result = await useCase.execute(orderId);

    expect(result.barcode, '123456789');
    expect(result.url, 'https://boleto.com/123');
  });
}
