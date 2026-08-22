library fa_wallet;

export 'wallet_module.dart';
export 'src/domain/entities/wallet_balance.dart';
export 'src/domain/entities/transaction.dart';
export 'src/domain/ports/i_wallet_repository.dart';
export 'src/infrastructure/adapters/wallet_repository_impl.dart';
export 'src/infrastructure/mock/wallet_mock_interceptor.dart';
export 'src/presentation/providers/wallet_provider.dart';
