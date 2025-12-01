# Relatório Técnico: Fluxo de Denúncia e Distribuição de Tarefas
**Projeto:** Vector Tracker App
**Módulo:** Vigilância e Denúncias da Comunidade

## 1. Objetivo
Descrever o processo técnico e operacional desde o momento em que um cidadão registra uma denúncia de vetor (barbeiro) até o momento em que essa demanda aparece na lista de tarefas do Agente de Endemias responsável.

## 2. O Fluxo Passo a Passo

### Etapa 1: Registro da Denúncia (Comunidade)
O processo se inicia no aplicativo do usuário comum (população).
1.  **Entrada de Dados:** O usuário acessa a tela `DenunciaScreen`.
2.  **Geolocalização:** O usuário pode usar o GPS para preencher rua e bairro, ou digitar manualmente.
3.  **Vinculação Geográfica (Crítico):**
    *   O sistema obriga o usuário a selecionar um **Município**.
    *   Com base no município, o sistema carrega e obriga a seleção de uma **Localidade** específica (bairro, sítio, zona).
    *   *Código:* A função `_onMunicipioChanged` garante que as localidades carregadas pertençam à cidade escolhida.
4.  **Envio:** Ao clicar em "Enviar", o objeto `Denuncia` é salvo no banco de dados (Supabase) contendo o campo `localidade_id` preenchido.
    *   *Status Inicial:* A denúncia é salva com status `'Pendente'`.

### Etapa 2: Processamento e Roteamento (Backend/Sistema)
Não há necessidade de um "dispatch" manual (alguém pegando a ficha e entregando). O roteamento é **automático e passivo**, baseado em dados:
*   A denúncia fica armazenada no banco de dados como um registro "órfão" de agente, mas "filho" de uma **Localidade**.
*   A inteligência do sistema reside no fato de que **Agentes são responsáveis por Localidades**.

### Etapa 3: Recebimento da Pendência (Agente de Endemias)
Esta é a etapa onde a mágica acontece na tela `MinhasDenunciasScreen` do aplicativo do agente.
1.  **Sincronização:** O agente abre o aplicativo e o `DenunciaService` é acionado.
2.  **Filtragem Inteligente:**
    *   O aplicativo do agente deve possuir a lista de IDs das localidades que ele atende (perfil do usuário).
    *   O serviço executa a função `fetchItems(localidadeIds: [...])`.
    *   *Validação de Código:* Confirmamos que o método `fetchItems` no `DenunciaService.dart` possui a lógica `query.inFilter('localidade_id', filterToUse)`.
3.  **Visualização:** O agente vê em sua lista apenas as denúncias que pertencem à sua área de atuação.
4.  **Ação:** O agente clica na denúncia, visualiza a foto e o endereço, e se desloca para o atendimento.

## 3. Conclusão Técnica
A arquitetura atual do **Vector Tracker** suporta nativamente a distribuição de tarefas baseada em território.

*   **Ponto Forte:** O vínculo é feito na origem (pelo cidadão escolhendo a localidade), o que elimina a necessidade de um coordenador triar manualmente cada denúncia.
*   **Garantia de Entrega:** Desde que o cadastro do Agente no sistema possua as localidades corretas vinculadas ao seu perfil, a denúncia aparecerá automaticamente na tela dele assim que for sincronizada.

---

**Resumo Visual:**
`Cidadão (Seleciona Localidade X)` ➔ `Banco de Dados (Grava ID Localidade X)` ➔ `App do Agente (Filtra "Tudo que é de X")` ➔ `Visita Agendada`.
