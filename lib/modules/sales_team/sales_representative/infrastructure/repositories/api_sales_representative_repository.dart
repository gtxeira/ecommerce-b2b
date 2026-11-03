import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/app/core/network/json_read.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/customer_assignment.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/enums/commission_status.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/repositories/sales_representative_repository.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/sales_representative.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/sales_hierarchy_link.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/representative_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/contact/value_objects/email_address.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/percentage.dart';

class ApiSalesRepresentativeRepository
    implements SalesRepresentativeRepository {
  final ApiClient _api;

  ApiSalesRepresentativeRepository(this._api);

  @override
  Future<SalesRepresentative?> findById(RepresentativeId id) async {
    final all = await findAll();
    for (final rep in all) {
      if (rep.id == id) return rep;
    }
    return null;
  }

  @override
  Future<List<SalesRepresentative>> findAll() async {
    String? selfId;
    String selfName = '';
    String selfEmail = '';
    double? selfRate;
    final team = <({String id, String fullName, String email})>[];

    try {
      final profile = await _api.get('/api/me/profile');
      if (profile is Map) {
        final json = Map<String, dynamic>.from(profile);
        selfRate = readNullableDouble(json, 'commissionRate');
        selfId = readString(json, 'userId');
        selfName = readString(json, 'fullName');
        selfEmail = readString(json, 'email');
      }
    } on ApiException {
      // Sem perfil (sessão expirada/rede): a lista fica com o que a equipe trouxer.
    }

    try {
      final data = await _api.get('/api/me/team');
      if (data is List) {
        for (final raw in data.whereType<Map>()) {
          final json = Map<String, dynamic>.from(raw);
          team.add((
            id: readString(json, 'id'),
            fullName: readString(json, 'fullName'),
            email: readString(json, 'email'),
          ));
        }
      }
    } on ApiException {
      // Não-supervisor recebe 403: a equipe simplesmente não existe.
    }

    if (selfRate == null || selfId == null || selfId.isEmpty) {
      return team
          .map((member) => _rep(member.id, member.fullName, member.email, 0))
          .toList();
    }

    final supervisor = _rep(
      selfId,
      selfName,
      selfEmail,
      selfRate,
      subordinateLinks: team
          .map(
            (member) => SalesHierarchyLink(
              supervisorId: RepresentativeId(selfId!),
              subordinateId: RepresentativeId(member.id),
            ),
          )
          .toList(),
    );

    return [
      supervisor,
      ...team.map(
        (member) => _rep(
          member.id,
          member.fullName,
          member.email,
          0,
          supervisorLink: SalesHierarchyLink(
            supervisorId: RepresentativeId(selfId!),
            subordinateId: RepresentativeId(member.id),
          ),
        ),
      ),
    ];
  }

  @override
  Future<List<Commission>> getCommissions({
    String? representativeId,
    bool teamScope = false,
  }) async {
    final data = await _api.get(
      '/api/me/commissions',
      query: {
        if (teamScope)
          'scope': 'team'
        else if (representativeId != null && representativeId.isNotEmpty)
          'representativeId': representativeId,
      },
    );
    if (data is! List) return const [];

    return data
        .whereType<Map>()
        .map((raw) => _mapCommission(Map<String, dynamic>.from(raw)))
        .toList();
  }

  @override
  Future<Commission> updateCommissionStatus({
    required int commissionId,
    required CommissionStatus status,
  }) async {
    final data = await _api.patch(
      '/api/me/commissions/$commissionId/status',
      data: {'status': _commissionStatusToApi(status)},
    );
    if (data is! Map) {
      throw const ApiException(
        statusCode: 0,
        code: 'INVALID_RESPONSE',
        message: 'Resposta inválida ao alterar o status da comissão.',
      );
    }

    return _mapCommission(Map<String, dynamic>.from(data));
  }

  Commission _mapCommission(Map<String, dynamic> json) => Commission(
    id: readInt(json, 'commissionId'),
    baseAmount: Money.create(readDouble(json, 'baseAmount')).getOrThrow(),
    rate: Percentage.create(readDouble(json, 'rate')).getOrThrow(),
    amount: Money.create(readDouble(json, 'amount')).getOrThrow(),
    status: _commissionStatusFromApi(readString(json, 'status')),
    orderId: readNullableString(json, 'orderId'),
    createdAt: readDate(json, 'createdAt'),
    representativeId: readNullableString(json, 'representativeId'),
    representativeName: readNullableString(json, 'representativeName'),
  );

  @override
  Future<List<CustomerAssignment>> getPortfolio({
    String? representativeId,
    bool teamScope = false,
  }) async {
    final data = await _api.get(
      '/api/me/portfolio',
      query: {
        if (teamScope)
          'scope': 'team'
        else if (representativeId != null && representativeId.isNotEmpty)
          'representativeId': representativeId,
      },
    );
    if (data is! List) return const [];
    return data.whereType<Map>().map((raw) {
      final json = Map<String, dynamic>.from(raw);
      return CustomerAssignment(
        CompanyId(readString(json, 'companyId')),
        representativeId: readNullableString(json, 'representativeId'),
        representativeName: readNullableString(json, 'representativeName'),
      );
    }).toList();
  }

  static CommissionStatus _commissionStatusFromApi(String value) =>
      switch (value.toLowerCase()) {
        'paid' => CommissionStatus.paid,
        'cancelled' => CommissionStatus.cancelled,
        _ => CommissionStatus.pending,
      };

  static String _commissionStatusToApi(CommissionStatus status) =>
      switch (status) {
        CommissionStatus.paid => 'Paid',
        CommissionStatus.cancelled => 'Cancelled',
        CommissionStatus.pending => 'Pending',
      };

  SalesRepresentative _rep(
    String id,
    String fullName,
    String email,
    double rate, {
    SalesHierarchyLink? supervisorLink,
    List<SalesHierarchyLink> subordinateLinks = const [],
  }) => SalesRepresentative(
    id: RepresentativeId(id),
    fullName: fullName,
    email: EmailAddress.create(email).getOrThrow(),
    commissionRate: Percentage.create(rate).getOrThrow(),
    supervisorLink: supervisorLink,
    subordinateLinks: subordinateLinks,
  );
}
