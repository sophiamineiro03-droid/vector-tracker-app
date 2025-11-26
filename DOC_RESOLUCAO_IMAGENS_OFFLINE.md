# 📋 Documentação de Status: Correção de Imagens Offline

**Data:** 24/05/2024
**Contexto:** O aplicativo apresenta imagens quebradas na lista "Meu Trabalho" quando o usuário cria ou edita registros sem internet (offline).

---

## 🔴 O Problema Atual
Quando o usuário salva um registro offline, a foto tirada aparece com ícone de erro ou tenta carregar uma URL da internet (que falha) na tela de listagem. Isso acontece porque o caminho do arquivo local no celular está se perdendo ou sendo misturado com links da internet durante o salvamento.

---

## ✅ O Que Já Foi Feito (Infraestrutura Pronta)

1.  **Serviço (`AgentOcorrenciaService`):**
    *   Implementada lógica de **"Pasta Segura"**: Ao salvar, o app copia as fotos do cache temporário para uma pasta persistente (`/offline_photos`).
    *   Isso impede que o sistema operacional apague a foto antes dela ser sincronizada.

2.  **Repositório (`OcorrenciaRepository`):**
    *   Atualizado para usar `toLocalMap()` ao salvar no banco de dados local (Hive).
    *   Isso garante que o campo `localImagePaths` (caminho do arquivo no celular) seja gravado no disco, e não apenas as URLs da nuvem.

3.  **Tela de Listagem (`MeuTrabalhoListScreen`):**
    *   Lógica de exibição alterada para dar **Prioridade Absoluta** a arquivos locais.
    *   O app verifica primeiro se existe um arquivo físico válido no celular. Se sim, mostra ele. Só se não houver, tenta carregar o link da internet.

---

## 🚧 O Que Falta Fazer (A Solução Final)

O erro persiste porque a tela de formulário (**`registro_ocorrencia_agente_screen.dart`**) está montando o objeto de forma errada antes de enviar para o serviço.

**Diagnóstico:**
No método `_saveForm`, o código atual mistura fotos locais e links da internet em uma única lista ou atribui fotos locais ao campo de URLs.

**Tarefas Pendentes:**
1.  Abrir `lib/screens/registro_ocorrencia_agente_screen.dart`.
2.  Localizar o método `_saveForm`.
3.  Alterar a criação do objeto `Ocorrencia` para separar rigorosamente as listas:
    *   **Links (`http...`):** Devem ir apenas para `fotos_urls`.
    *   **Arquivos Locais (caminhos de disco):** Devem ir apenas para `localImagePaths`.
4.  Não permitir que caminhos locais sejam colocados no campo `fotos_urls` manualmente antes do upload.

**Exemplo do que precisa ser corrigido no código:**
```dart
// ERRADO (Provável estado atual):
fotos_urls: _localImagePaths, // Mistura tudo

// CORRETO (Como deve ficar):
fotos_urls: _localImagePaths.where((p) => p.startsWith('http')).toList(),
localImagePaths: _localImagePaths.where((p) => !p.startsWith('http')).toList() 
                 + _newlyAddedImages.map((f) => f.path).toList(),
```

---

## Como Retomar
Peça para a IA: *"Leia o arquivo DOC_RESOLUCAO_IMAGENS_OFFLINE.md e aplique a correção pendente na tela de registro."*