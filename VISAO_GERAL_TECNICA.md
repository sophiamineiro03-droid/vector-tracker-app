# Visão Geral Técnica do Projeto Vector Tracker

Este documento detalha a arquitetura do banco de dados e os principais fluxos de comunicação entre o aplicativo Flutter e o backend Supabase.

---

## 1. Visão Detalhada do Banco de Dados

O banco de dados foi estruturado para suportar múltiplos municípios (multitenancy), onde cada pedaço de informação principal (agentes, localidades, ocorrências) pertence a um município específico. As conexões são feitas através de chaves estrangeiras (foreign keys).

### Tabela: `municipios`

É a tabela central que identifica cada cliente do sistema.

- **Propósito:** Armazenar os municípios que utilizam o sistema.
- **Colunas Principais:**
  - `id` (uuid, Chave Primária): Identificador único de cada município.
  - `nome` (text): Nome do município (ex: "Castelo do Piauí").
  - `codigo_ibge` (text): Código oficial do IBGE.

### Tabela: `agentes`

Contém o perfil profissional de cada Agente de Combate às Endemias.

- **Propósito:** Gerenciar os dados dos agentes.
- **Colunas Principais:**
  - `id` (uuid, Chave Primária): Identificador único do agente.
  - `user_id` (uuid, Chave Estrangeira -> `auth.users`): **A ponte crucial.** Liga o perfil profissional do agente à sua conta de login (email/senha).
  - `municipio_id` (uuid, Chave Estrangeira -> `municipios`): Garante que cada agente pertença a um município.
  - `nome` (text): Nome completo do agente.
  - `email` (text): Email de contato.
  - `registro_matricula` (text): Matrícula funcional do agente.
  - `ativo` (bool): Indica se o agente está ativo no sistema.

### Tabela: `localidades`

São as áreas de trabalho dentro de um município (bairros, zonas rurais, etc.).

- **Propósito:** Organizar o município em áreas geográficas menores.
- **Colunas Principais:**
  - `id` (uuid, Chave Primária): Identificador único da localidade.
  - `municipio_id` (uuid, Chave Estrangeira -> `municipios`): Garante que cada localidade pertença a um município.
  - `nome` (text): Nome da localidade (ex: "Centro", "Mutirão").
  - `codigo` (text): Código da localidade (preenchido em campo pelo agente).
  - `categoria` (text): Categoria da localidade (ex: "Urbana", "Rural").

### Tabela: `agentes_localidades` (Tabela de Junção)

Define quais agentes são responsáveis por quais localidades.

- **Propósito:** Criar uma relação Muitos-para-Muitos entre agentes e localidades.
- **Colunas Principais:**
  - `agente_id` (uuid, Chave Estrangeira -> `agentes`): O ID do agente.
  - `localidade_id` (uuid, Chave Estrangeira -> `localidades`): O ID da localidade.

### Tabela: `denuncias`

Registros criados pela comunidade.

- **Propósito:** Armazenar denúncias enviadas pelos cidadãos.
- **Colunas Principais:**
  - `id` (uuid, Chave Primária): ID da denúncia.
  - `status` (text): Situação atual da denúncia (ex: "Pendente", "Em Atendimento", "Concluída").
  - `descricao` (text): Detalhes da denúncia fornecidos pelo cidadão.
  - `foto_url` (text): URL da foto enviada na denúncia.
  - `localidade_id` (uuid, Chave Estrangeira -> `localidades`): Liga a denúncia a uma localidade específica e, por consequência, a um município.
  - `rua`, `numero`, `bairro`, `complemento`: Endereço detalhado da denúncia.

### Tabela: `ocorrencias`

Principal tabela do sistema, onde o trabalho do agente é registrado.

- **Propósito:** Armazenar os registros de visita e atividades dos agentes.
- **Colunas Principais:**
  - `id` (uuid, Chave Primária): ID da ocorrência.
  - `agente_id` (uuid, Chave Estrangeira -> `agentes`): Identifica o agente que realizou o trabalho.
  - `localidade_id` (uuid, Chave Estrangeira -> `localidades`): Identifica onde o trabalho foi realizado.
  - `denuncia_id` (uuid, Chave Estrangeira -> `denuncias`): Se a ocorrência foi gerada para atender a uma denúncia.
  - `tipo_atividade` (array de text): Armazena uma *lista* de atividades (ex: `["pesquisa", "borrifacao"]`).
  - `fotos_urls` (text): **Alteração Importante.** Armazena uma lista de URLs de texto (em formato JSON) para as fotos associadas. Esta abordagem substitui as antigas colunas `foto_url_1`, etc., permitindo um número flexível de imagens.
  - Demais campos de negócio (ex: `situacao_imovel`, `vestigios_intradomicilio`).

---

## 2. Comunicação App <> Banco de Dados (Fluxo de Dados)

### Fluxo 1: Autenticação do Agente

Este é o fluxo mais crítico que corrigimos.

1.  **Tela de Login (`login_screen.dart`):** O agente insere email e senha.
2.  **Supabase Auth:** O app envia as credenciais para o `Supabase.instance.client.auth.signInWithPassword`.
3.  **Resposta do Supabase:** Se o login for válido, o Supabase retorna um objeto `User` que contém o ID único de autenticação (`user.id`).
4.  **Busca do Perfil (`AgenteRepository`):** Imediatamente após o login, o app usa o `user.id` para fazer uma consulta na tabela `agentes` para carregar o perfil completo do profissional, incluindo suas localidades de trabalho.
5.  **Carregamento dos Dados:** Com a busca bem-sucedida, o app cria um objeto `Agente` e o disponibiliza para as outras telas.

### Fluxo 2: Criação de Ocorrência (com Fotos)

1.  **Tela de Registro (`registro_ocorrencia_agente_screen.dart`):** O agente preenche o formulário e tira fotos.
2.  **Salvando (`AgentOcorrenciaService`):** Ao clicar em salvar, o serviço executa o seguinte fluxo:
    a.  **Cenário Online:** Se o celular tem internet, o serviço primeiro faz o upload de cada nova foto para o **Supabase Storage** (no bucket `fotos-ocorrencias`). Após o upload, ele recebe de volta as URLs públicas de cada foto. Então, ele insere o registro completo na tabela `ocorrencias`, preenchendo a coluna `fotos_urls` com a lista de URLs recebidas.
    b.  **Cenário Offline (Offline-first):** Se o envio online falhar (por falta de internet), o serviço salva a ocorrência em uma caixa local do Hive (`pending_ocorrencias`). Importante: as fotos novas são salvas com seus **caminhos locais** no celular.
    c.  **Sincronização:** Posteriormente, quando o app detecta conexão, o serviço lê as ocorrências pendentes do Hive, realiza o upload das fotos a partir dos caminhos locais (como no cenário online) e envia o registro completo para o Supabase, garantindo que nenhum dado seja perdido.

### Fluxo 3: Atendimento de Denúncia

1.  **Seleção da Denúncia:** O agente seleciona uma denúncia pendente.
2.  **Abertura da Tela de Registro:** O app abre a `registro_ocorrencia_agente_screen`, passando os dados da denúncia.
3.  **Pré-preenchimento:** A tela usa os dados da denúncia (`rua`, `numero`, `foto_url`, etc.) para preencher o formulário de ocorrência, agilizando o trabalho do agente. A `foto_url` original da denúncia é preservada e adicionada à lista `fotos_urls` da nova ocorrência.
