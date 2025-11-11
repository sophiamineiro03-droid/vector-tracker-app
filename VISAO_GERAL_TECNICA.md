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

### Tabela: `localidades`

São as áreas de trabalho dentro de um município (bairros, zonas rurais, etc.).

- **Propósito:** Organizar o município em áreas geográficas menores.
- **Colunas Principais:**
  - `id` (uuid, Chave Primária): Identificador único da localidade.
  - `municipio_id` (uuid, Chave Estrangeira -> `municipios`): Garante que cada localidade pertença a um município.
  - `nome` (text): Nome da localidade (ex: "Centro", "Mutirão").

### Tabela: `agentes_localidades` (Tabela de Junção)

Define quais agentes são responsáveis por quais localidades.

- **Propósito:** Criar uma relação Muitos-para-Muitos entre agentes e localidades.
- **Colunas Principais:**
  - `agente_id` (uuid, Chave Estrangeira -> `agentes`): O ID do agente.
  - `localidade_id` (uuid, Chave Estrangeira -> `localidades`): O ID da localidade.

### Tabela: `denuncias`

Registros criados pela comunidade.

- **Propósito:** Armazenar denúncias enviadas pelos cidadãos.
- **Conexão Indireta com Município:** A denúncia se conecta a um município através da sua localidade.
- **Colunas Principais:**
  - `id` (uuid, Chave Primária): ID da denúncia.
  - `localidade_id` (uuid, Chave Estrangeira -> `localidades`): Liga a denúncia a uma localidade específica e, por consequência, a um município.
  - `complemento` (text): Campo adicionado para detalhar o endereço.

### Tabela: `ocorrencias`

Principal tabela do sistema, onde o trabalho do agente é registrado.

- **Propósito:** Armazenar os registros de visita e atividades dos agentes.
- **Conexão Indireta com Município:** A ocorrência se conecta a um município tanto pelo agente quanto pela localidade.
- **Colunas Principais:**
  - `id` (uuid, Chave Primária): ID da ocorrência.
  - `agente_id` (uuid, Chave Estrangeira -> `agentes`): Identifica o agente que realizou o trabalho.
  - `localidade_id` (uuid, Chave Estrangeira -> `localidades`): Identifica onde o trabalho foi realizado.
  - `denuncia_id` (uuid, Chave Estrangeira -> `denuncias`): Se a ocorrência foi gerada para atender a uma denúncia.
  - `tipo_atividade` (array de text): **Alteração importante.** Agora armazena uma *lista* de atividades (ex: `["pesquisa", "borrifacao"]`).

---

## 2. Comunicação App <> Banco de Dados (Fluxo de Dados)

### Fluxo 1: Autenticação do Agente

Este é o fluxo mais crítico que corrigimos.

1.  **Tela de Login (`login_screen.dart`):** O agente insere email e senha.
2.  **Supabase Auth:** O app envia as credenciais para o `Supabase.instance.client.auth.signInWithPassword`.
3.  **Resposta do Supabase:** Se o login for válido, o Supabase retorna um objeto `User` que contém o ID único de autenticação (`user.id`).
4.  **Busca do Perfil (`AgenteRepository`):** Imediatamente após o login, o app usa o `user.id` para fazer uma consulta na tabela `agentes`:
    ```sql
    SELECT *, municipios(nome), agentes_localidades!inner(localidades(nome))
    FROM agentes
    WHERE user_id = 'ID_DO_USUARIO_LOGADO';
    ```
5.  **Erro `0 rows` (Resolvido):** O erro que encontramos ("The result contains 0 rows") acontecia aqui, pois a coluna `user_id` na tabela `agentes` não estava preenchida com o ID da tabela `auth.users`.
6.  **Carregamento dos Dados:** Com a busca bem-sucedida, o app cria um objeto `Agente` e o disponibiliza para as outras telas, que podem então exibir o nome do agente, seu município e suas localidades de trabalho.

### Fluxo 2: Criação de Ocorrência

1.  **Tela de Registro (`registro_ocorrencia_agente_screen.dart`):** O agente preenche o formulário.
2.  **Dados Pré-preenchidos:** Ao abrir a tela, o app busca o perfil do agente logado e já preenche automaticamente campos como "Município" e "Localidade", usando os dados do `Agente` obtidos no login.
3.  **Seleção de Atividades:** O agente agora pode marcar uma ou mais checkboxes para `tipo_atividade` (Pesquisa, Borrifação, etc.).
4.  **Salvando (`AgentOcorrenciaService`):** Ao clicar em salvar, o app:
    a.  Cria um objeto `Ocorrencia` com todos os dados do formulário.
    b.  O campo `tipo_atividade` do objeto agora é uma `List<String>`.
    c.  O serviço tenta enviar esses dados para a tabela `ocorrencias` no Supabase.
    d.  **Offline-first:** Se o envio online falhar (por falta de internet), o `AgentOcorrenciaService` salva a ocorrência em uma caixa local do Hive (`pending_ocorrencias`) para sincronizar mais tarde.

### Fluxo 3: Atendimento de Denúncia

1.  **Seleção da Denúncia:** O agente seleciona uma denúncia pendente na sua tela inicial.
2.  **Abertura da Tela de Registro:** O app abre a `registro_ocorrencia_agente_screen`, passando os dados da denúncia.
3.  **Pré-preenchimento:** A tela usa os dados da denúncia (`rua`, `numero`, `bairro`, e o novo campo `complemento`) para preencher o formulário de ocorrência, agilizando o trabalho do agente.
