# Visão Geral do Projeto: Vector Tracker App

Este documento serve como a fonte central da verdade para o desenvolvimento do aplicativo Vector Tracker. Ele resume o propósito, a arquitetura e os fluxos de trabalho definidos.

## 1. Propósito Principal

O objetivo do **Vector-Tracker** é **digitalizar e otimizar o trabalho de campo dos Agentes de Combate às Endemias**. O aplicativo substitui os formulários de papel do SIOCHAGAS por uma solução digital que agrega funcionalidades essenciais como **geolocalização (GPS)** e **captura de fotos**, enriquecendo o registro das ocorrências.

## 2. Arquitetura de Dados (Multitenancy)

A arquitetura foi projetada para ser **escalável** e suportar múltiplos municípios de forma independente a partir de uma única base de dados.

-   **Tabelas Únicas:** Teremos tabelas centralizadas para `municipios`, `localidades`, `agentes`, `denuncias` e `ocorrencias`.
-   **Segregação por ID:** A coluna `municipio_id` (ou uma relação similar) em cada tabela é a chave que garante a separação dos dados.
-   **Visão do Cliente:** Para criar um painel ou site para um município específico (ex: Castelo do Piauí), a aplicação web fará um **filtro por `municipio_id` em todas as consultas**. Isso fará com que o sistema se comporte como se fosse exclusivo para aquele município, garantindo total privacidade e separação dos dados.

## 3. Fluxos de Trabalho Essenciais

Existem dois fluxos de usuário principais que se conectam.

### a. Fluxo do Cidadão (Registrar Denúncia)

1.  O cidadão preenche um formulário simples para reportar um possível foco de vetor.
2.  **Endereço e GPS:** O app pode usar o GPS para preencher automaticamente os campos de endereço (Rua, Bairro, Cidade).
3.  **Seleção de Localidade (Crítico):** O cidadão **deve obrigatoriamente** selecionar a **Localidade** a partir de uma lista pré-carregada do banco de dados. Isso garante a integridade e a consistência dos dados para o direcionamento do agente.
4.  **Campos Adicionais:** O cidadão pode adicionar uma **descrição** do que encontrou, um **complemento** para o endereço (Ex: "Apto 101") e uma **foto**.
5.  Ao salvar, uma `Denuncia` é criada no banco de dados com o status "Pendente".

### b. Fluxo do Agente (Atender Denúncia e Registrar Ocorrência)

1.  O agente vê uma lista de denúncias pendentes que foram feitas nas **localidades pelas quais ele é responsável**.
2.  Ao selecionar uma denúncia, a tela de **Registro de Ocorrência** é aberta.
3.  **Pré-preenchimento Inteligente:**
    -   Os dados de endereço (`localidade`, `rua`, `número`, `complemento`) são automaticamente preenchidos a partir da denúncia.
    -   Um **Cartão de Contexto** é exibido no topo da tela, mostrando a **descrição original** e o **bairro** informados pelo cidadão, para que o agente entenda o chamado antes de agir.
4.  **Formulário Técnico:** O agente então preenche o restante do formulário, que corresponde à ficha do SIOCHAGAS:
    -   **Múltiplas Atividades:** O agente pode selecionar uma ou mais atividades (ex: Pesquisa, Borrifação) usando caixas de seleção.
    -   Detalhes do domicílio, captura de vetores, borrifação, etc.
5.  Ao salvar, uma `Ocorrencia` é criada e a `Denuncia` original pode ter seu status atualizado para "Atendida".

---
*Este documento foi gerado para refletir as discussões e decisões tomadas. Ele deve ser mantido atualizado à medida que o projeto evolui.*
