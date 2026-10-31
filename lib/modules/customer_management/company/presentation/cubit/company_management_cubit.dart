import 'package:ecommerce_b2b/modules/customer_management/company/application/add_authorized_buyer/add_authorized_buyer_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/application/get_companies/get_companies_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/application/register_company/register_company_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/company.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/repositories/sales_representative_repository.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/sales_representative.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'company_management_state.dart';

class CompanyManagementCubit extends Cubit<CompanyManagementState> {
  final GetCompaniesUseCase _getCompaniesUseCase;
  final RegisterCompanyUseCase _registerCompanyUseCase;
  final AddAuthorizedBuyerUseCase _addAuthorizedBuyerUseCase;
  final SalesRepresentativeRepository _representativeRepository;

  CompanyManagementCubit({
    required this._getCompaniesUseCase,
    required this._registerCompanyUseCase,
    required this._addAuthorizedBuyerUseCase,
    required this._representativeRepository,
  }) : super(CompanyManagementInitial());

  Future<void> loadCompanies(
    UserSession session, {
    String? targetRepresentativeId,
  }) async {
    emit(CompanyManagementLoading());
    final result = await _getCompaniesUseCase.execute(
      session,
      targetRepresentativeId: targetRepresentativeId,
    );

    // A API já devolve a equipe do supervisor em /api/me/team; o app só
    // remove a própria sessão da lista de opções.
    List<SalesRepresentative> subordinates = [];
    try {
      if (session.isSupervisor) {
        final allReps = await _representativeRepository.findAll();
        subordinates = allReps
            .where((rep) => rep.id.value != session.userId.value)
            .toList();
      }
    } catch (_) {
      subordinates = [];
    }

    result.fold(
      (error) => emit(CompanyManagementFailure(error.message)),
      (companies) => emit(
        CompanyManagementLoaded(
          companies: companies,
          subordinates: subordinates,
          selectedRepresentativeId:
              targetRepresentativeId ?? session.userId.value,
        ),
      ),
    );
  }

  Future<void> registerCompany({
    required UserSession currentSession,
    required String legalName,
    required String tradeName,
    required String cnpj,
    required String inscricaoEstadual,
    required String email,
    required String phone,
    required String billingStreet,
    required String billingNumber,
    String? billingComplement,
    required String billingNeighborhood,
    required String billingCity,
    required String billingState,
    required String billingZipCode,
    required String shippingStreet,
    required String shippingNumber,
    String? shippingComplement,
    required String shippingNeighborhood,
    required String shippingCity,
    required String shippingState,
    required String shippingZipCode,
    required double creditLimit,
  }) async {
    final originalState = state;
    emit(CompanyManagementLoading());

    final result = await _registerCompanyUseCase.execute(
      currentSession: currentSession,
      legalName: legalName,
      tradeName: tradeName,
      cnpj: cnpj,
      inscricaoEstadual: inscricaoEstadual,
      email: email,
      phone: phone,
      billingStreet: billingStreet,
      billingNumber: billingNumber,
      billingComplement: billingComplement,
      billingNeighborhood: billingNeighborhood,
      billingCity: billingCity,
      billingState: billingState,
      billingZipCode: billingZipCode,
      shippingStreet: shippingStreet,
      shippingNumber: shippingNumber,
      shippingComplement: shippingComplement,
      shippingNeighborhood: shippingNeighborhood,
      shippingCity: shippingCity,
      shippingState: shippingState,
      shippingZipCode: shippingZipCode,
      creditLimit: creditLimit,
    );

    result.fold(
      (error) {
        emit(CompanyManagementFailure(error.message));
        if (originalState is CompanyManagementLoaded) {
          emit(originalState);
        }
      },
      (company) {
        emit(const CompanyManagementSuccess('Empresa cadastrada com sucesso!'));
        final lastRepId = originalState is CompanyManagementLoaded
            ? originalState.selectedRepresentativeId
            : null;
        loadCompanies(currentSession, targetRepresentativeId: lastRepId);
      },
    );
  }

  Future<void> addAuthorizedBuyer({
    required UserSession currentSession,
    required CompanyId companyId,
    required String fullName,
    required String email,
    required String phone,
    required String positionTitle,
  }) async {
    final originalState = state;
    emit(CompanyManagementLoading());

    final result = await _addAuthorizedBuyerUseCase.execute(
      currentSession: currentSession,
      companyId: companyId,
      fullName: fullName,
      email: email,
      phone: phone,
      positionTitle: positionTitle,
    );

    result.fold(
      (error) {
        emit(CompanyManagementFailure(error.message));
        if (originalState is CompanyManagementLoaded) {
          emit(originalState);
        }
      },
      (company) {
        emit(
          const CompanyManagementSuccess(
            'Comprador autorizado adicionado com sucesso!',
          ),
        );
        final lastRepId = originalState is CompanyManagementLoaded
            ? originalState.selectedRepresentativeId
            : null;
        loadCompanies(currentSession, targetRepresentativeId: lastRepId);
      },
    );
  }
}
