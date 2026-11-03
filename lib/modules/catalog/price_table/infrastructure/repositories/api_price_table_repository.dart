import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/json_read.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/enums/price_scope_type.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/price_rule.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/price_table.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/repositories/price_table_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/address/enums/state.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/price_table_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_variant_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';

class ApiPriceTableRepository implements PriceTableRepository {
  final ApiClient _api;

  ApiPriceTableRepository(this._api);

  @override
  Future<List<PriceTable>> findAll() async {
    final data = await _api.get('/api/price-tables');
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => _fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<PriceTable?> findById(PriceTableId id) async {
    final all = await findAll();
    for (final table in all) {
      if (table.id == id) return table;
    }
    return null;
  }

  @override
  Future<void> save(PriceTable priceTable) async {
    await _api.post('/api/price-tables', data: _toJson(priceTable));
  }

  @override
  Future<void> delete(PriceTableId id) async {
    // A API ainda não expõe exclusão de tabela de preços.
    throw UnsupportedError(
      'Exclusão de tabela de preços não disponível na API.',
    );
  }

  Map<String, dynamic> _toJson(PriceTable table) => {
    'id': table.id.value,
    'name': table.name,
    'scopeType': _scopeToApi(table.scopeType),
    if (table.companyId != null && table.companyId!.isNotEmpty)
      'companyId': table.companyId,
    'rules': table.rules
        .map(
          (rule) => {
            'productId': rule.productId.value,
            'variantId': rule.variantId?.value,
            'minQuantity': rule.minQuantity.value,
            'maxQuantity': rule.maxQuantity.value,
            'unitPrice': rule.unitPrice.amount,
            'state': rule.state?.apiName,
          },
        )
        .toList(),
  };

  PriceTable _fromJson(Map<String, dynamic> json) => PriceTable(
    id: PriceTableId(readString(json, 'id')),
    name: readString(json, 'name'),
    scopeType: _scopeFromApi(readString(json, 'scopeType')),
    companyId: readNullableString(json, 'companyId'),
    rules: readMapList(json, 'rules').map(_ruleFromJson).toList(),
  );

  PriceRule _ruleFromJson(Map<String, dynamic> json) {
    final variantId = readNullableString(json, 'variantId');
    final state = readNullableString(json, 'state');

    return PriceRule(
      productId: ProductId(readString(json, 'productId')),
      variantId: variantId == null ? null : ProductVariantId(variantId),
      minQuantity: Quantity.create(readInt(json, 'minQuantity')).getOrThrow(),
      maxQuantity: Quantity.create(readInt(json, 'maxQuantity')).getOrThrow(),
      unitPrice: Money.create(readDouble(json, 'unitPrice')).getOrThrow(),
      state: state == null ? null : State.fromApiName(state).getOrThrow(),
    );
  }

  PriceScopeType _scopeFromApi(String value) => switch (value.toLowerCase()) {
    'regional' => PriceScopeType.regional,
    'customerspecific' => PriceScopeType.customerSpecific,
    _ => PriceScopeType.national,
  };

  String _scopeToApi(PriceScopeType scope) => switch (scope) {
    PriceScopeType.national => 'National',
    PriceScopeType.regional => 'Regional',
    PriceScopeType.customerSpecific => 'CustomerSpecific',
  };
}
