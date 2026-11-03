import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/enums/commission_status.dart';
import 'package:flutter/material.dart';

String commissionStatusLabel(CommissionStatus status) => switch (status) {
  CommissionStatus.pending => 'Pendente',
  CommissionStatus.approved => 'Aprovada',
  CommissionStatus.paid => 'Paga',
  CommissionStatus.cancelled => 'Cancelada',
};

Color commissionStatusColor(CommissionStatus status, ColorScheme colors) =>
    switch (status) {
      CommissionStatus.pending => Colors.orange.shade700,
      CommissionStatus.approved => Colors.blue.shade700,
      CommissionStatus.paid => Colors.green.shade700,
      CommissionStatus.cancelled => colors.error,
    };
