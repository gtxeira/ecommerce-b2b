import 'package:ecommerce_b2b/modules/shared_kernel/model/entity.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/price_table_id.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/enums/price_scope_type.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/price_rule.dart';

class PriceTable extends Entity<PriceTableId> {
  final String name;
  final PriceScopeType scopeType;
  final List<PriceRule> _rules;

  PriceTable({
    required PriceTableId id,
    required this.name,
    required this.scopeType,
    List<PriceRule>? rules,
  })  : _rules = rules ?? [],
        super(id);

  List<PriceRule> get rules => List.unmodifiable(_rules);

  void addRule(PriceRule rule) {
    _rules.add(rule);
  }
}
