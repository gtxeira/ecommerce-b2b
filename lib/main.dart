import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/core/routes/app_routes.dart';
import 'package:ecommerce_b2b/app/presentation/theme/app_theme.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/open_orders_auth_sync.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/cubit/open_orders_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => getIt<AuthCubit>()),
        // Vive acima do router: o badge da navegação não pode morrer com a tela.
        BlocProvider(create: (context) => getIt<OpenOrdersCubit>()),
      ],
      child: OpenOrdersAuthSync(
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, currentMode, child) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Ecommerce B2B',
              themeMode: currentMode,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              routerConfig: appRouter,
            );
          },
        ),
      ),
    );
  }
}
