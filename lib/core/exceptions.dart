/// Exceções customizadas para a aplicação
/// 
/// REFATORAÇÃO: Sistema de exceções estruturado para melhor tratamento de erros.

/// Exceção base para erros da aplicação
/// 
/// Todas as exceções da aplicação devem estender esta classe
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final Object? originalError;
  final StackTrace? stackTrace;

  const AppException(this.message, {this.code, this.originalError, this.stackTrace});

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exceção relacionada a operações de rede
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError, super.stackTrace});
}

/// Exceção relacionada a falhas de conexão
class ConnectionException extends NetworkException {
  const ConnectionException([String? message]) 
      : super(message ?? 'Sem conexão com a internet');
}

/// Exceção relacionada a operações de banco de dados local
class LocalDatabaseException extends AppException {
  const LocalDatabaseException(super.message, {super.code, super.originalError, super.stackTrace});
}

/// Exceção relacionada a operações de sincronização
class SyncException extends AppException {
  const SyncException(super.message, {super.code, super.originalError, super.stackTrace});
}

/// Exceção relacionada a operações com Supabase
class SupabaseException extends AppException {
  const SupabaseException(super.message, {super.code, super.originalError, super.stackTrace});
}

/// Exceção relacionada a validação de dados
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.originalError, super.stackTrace});
}

/// Exceção relacionada a autenticação
class AuthenticationException extends AppException {
  const AuthenticationException(super.message, {super.code, super.originalError, super.stackTrace});
}

/// Exceção relacionada a permissões
class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.originalError, super.stackTrace});
}

