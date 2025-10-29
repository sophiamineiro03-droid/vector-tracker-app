import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Configuração centralizada da aplicação
/// 
/// REFATORAÇÃO: Credenciais movidas para variáveis de ambiente para melhor segurança.
/// Substitui o código hardcoded em main.dart
class AppConfig {
  static bool _initialized = false;

  /// Inicializa a configuração carregando variáveis de ambiente
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: ".env");
      _initialized = true;
      if (kDebugMode) {
        print('✓ AppConfig inicializado com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao carregar .env: $e');
        print('⚠️ Usando valores padrão (hardcoded para compatibilidade)');
      }
      _initialized = false;
    }
  }

  /// Retorna a URL do Supabase
  static String get supabaseUrl {
    // FALLBACK: Se não conseguir carregar .env, usa valores hardcoded (COM PATIENTE)
    // ISSO DEVE SER REMOVIDO em produção - mantenha apenas para compatibilidade durante migração
    return dotenv.env['SUPABASE_URL'] ?? 
           'https://wcxiziyrjiqvhmxvpfga.supabase.co';
  }

  /// Retorna a chave anônima do Supabase
  static String get supabaseAnonKey {
    // FALLBACK: Se não conseguir carregar .env, usa valores hardcoded (COM PATIENTE)
    // ISSO DEVE SER REMOVIDO em produção - mantenha apenas para compatibilidade durante migração
    return dotenv.env['SUPABASE_ANON_KEY'] ?? 
           'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndjeGl6aXlyamlxdmhteHZwZmdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkyOTg2NDksImV4cCI6MjA3NDg3NDY0OX0.EGNXOT3IhSVLR41q5xE2JGx-gPahQpwkwsitH1wJVLY';
  }

  /// Retorna o ambiente atual
  static String get environment => dotenv.env['APP_ENVIRONMENT'] ?? 'development';

  /// Verifica se está em modo debug
  static bool get isDebug => kDebugMode;

  /// Verifica se está em produção
  static bool get isProduction => environment == 'production';
}


