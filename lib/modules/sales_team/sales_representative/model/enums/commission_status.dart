/// Situação da comissão no backend (Pending | Paid | Cancelled).
///
/// Não existe "approved": a API só emite esses três estados e o representante não
/// aprova a própria comissão. O enum foi alinhado ao backend para o `switch` ser
/// exaustivo.
enum CommissionStatus { pending, paid, cancelled }
