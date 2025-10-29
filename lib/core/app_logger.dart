import 'package:logger/logger.dart';

/// Sistema centralizado de logging para a aplicação
/// 
/// Substitui os prints espalhados pelo código e fornece logs estruturados.
/// REFATORAÇÃO: Sistema de logging criado para melhorar rastreabilidade e debug.
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // Número de métodos para incluir na stack trace
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  /// Log de informações gerais
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log de debug (apenas em modo debug)
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log de warnings
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log de erros
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log de erros fatais
  static void fatal(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log específico para sincronização
  static void sync(String message, [Object? error]) {
    _logger.d('🔄 SYNC: $message', error: error);
  }

  /// Log específico para operações de rede
  static void network(String message, [Object? error]) {
    _logger.d('🌐 NETWORK: $message', error: error);
  }

  /// Log específico para operações de banco de dados
  static void database(String message, [Object? error]) {
    _logger.d('💾 DATABASE: $message', error: error);
  }

  /// Log específico para operações de UI
  static void ui(String message, [Object? error]) {
    _logger.d('🎨 UI: $message', error: error);
  }
}

