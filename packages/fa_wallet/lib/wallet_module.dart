import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:fa_design_system/fa_design_system.dart';

import 'package:fa_core/fa_core.dart';
import 'src/application/use_cases/get_wallet_use_case.dart';
import 'src/application/use_cases/get_transactions_use_case.dart';
import 'src/application/use_cases/send_transfer_use_case.dart';
import 'src/infrastructure/adapters/wallet_repository_impl.dart';
import 'src/presentation/providers/wallet_provider.dart';
import 'src/presentation/screens/movements_screen.dart';
import 'src/presentation/screens/send_money_screen.dart';

class WalletModule extends IModule {
  late ApiClient _apiClient;
  // ignore: unused_field
  late NavigationCallbacks _navigation;

  @override
  String get moduleId => 'fa_wallet';

  @override
  String get version => '1.0.0';

  @override
  void configure({required ApiClient apiClient, required NavigationCallbacks navigation}) {
    _apiClient = apiClient;
    _navigation = navigation;
  }

  @override
  List<Widget> get providers => [
        ChangeNotifierProvider<WalletProvider>(
          create: (_) {
            final repo = WalletRepositoryImpl(apiClient: _apiClient);
            return WalletProvider(
              getWallet: GetWalletUseCase(repo),
              getTransactions: GetTransactionsUseCase(repo),
              sendTransfer: SendTransferUseCase(repo),
            );
          },
        ),
      ];

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: '/wallet/movements',
          builder: (_, __) => const MovementsScreen(),
        ),
        GoRoute(
          path: '/wallet/send',
          builder: (_, __) => const SendMoneyScreen(),
        ),
      ];

  @override
  void initHome(BuildContext context) {
    context.read<WalletProvider>().loadAll();
  }

  @override
  /// El home ya no muestra la tarjeta de débito: el producto se enfoca en el
  /// crédito y el diseño reserva el resumen para el estado del crédito y las
  /// oportunidades (Journey L699–L795). El saldo y los movimientos siguen
  /// accesibles desde el historial.
  Widget? buildHomeCard(BuildContext context) => null;

  @override
  List<HomeTab> get ownedTabs => const [HomeTab.movimientos];

  @override
  Widget buildTabScreen(BuildContext context, HomeTab tab) =>
      const MovementsScreen(embedded: true);
}

// ─────────────────────────────────────────────────────────────────────────────
// Home card del módulo Wallet (con toggle de visibilidad propio)
// ─────────────────────────────────────────────────────────────────────────────

class _WalletHomeSection extends StatefulWidget {
  const _WalletHomeSection();

  @override
  State<_WalletHomeSection> createState() => _WalletHomeSectionState();
}

class _WalletHomeSectionState extends State<_WalletHomeSection> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final wallet = context.watch<WalletProvider>().wallet;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(w * 0.051, h * 0.018, w * 0.051, 0),
          child: DsWalletCard(
            balance: wallet?.available ?? 0,
            accountNumber: wallet?.accountNumber ?? '',
            clabe: wallet?.clabe,
            visible: _visible,
            onToggleVisibility: () => setState(() => _visible = !_visible),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: w * 0.051, vertical: h * 0.016),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionBtn(
                icon: Icons.arrow_upward_rounded,
                label: 'Enviar',
                onTap: () => context.go('/wallet/send'),
                h: h,
              ),
              _ActionBtn(
                icon: Icons.history_rounded,
                label: 'Historial',
                onTap: () => context.go('/wallet/movements'),
                h: h,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.h});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double h;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: h * 0.062,
            height: h * 0.062,
            decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(18)),
            child: Icon(icon, color: AppColors.primary, size: h * 0.03),
          ),
          Gap(h * 0.006),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurface, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
