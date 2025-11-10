# Contexto da Refatoração: Múltiplas Localidades por Agente

Este documento serve como ponto de partida para a refatoração da tela `registro_ocorrencia_agente_screen.dart`.

## 1. A Mudança no Banco de Dados (Supabase)

Ocorreu uma alteração fundamental na forma como associamos agentes e ocorrências a localidades.

### Antes:
- A tabela `agentes` continha uma coluna de texto simples chamada `localidade`.
- A tabela `ocorrencias` também continha uma coluna de texto `localidade`.
- A associação era frágil, baseada apenas em nomes (Strings).

### Agora (Novo Modelo):
- Foi criada uma tabela `localidades` (`id`, `nome`) para centralizar as localidades.
- Foi criada uma tabela de junção `agentes_localidades` que conecta `agentes.id` com `localidades.id`.
- A tabela `ocorrencias` foi alterada: a coluna `localidade` (texto) foi substituída por `localidade_id` (UUID), que é uma chave estrangeira para a tabela `localidades`.
- **Consequência:** A associação agora é robusta e baseada em IDs. Um agente pode estar associado a múltiplas localidades.

## 2. O Problema no Código Atual

O arquivo `lib/screens/registro_ocorrencia_agente_screen.dart` foi construído com base no modelo antigo e, portanto, está obsoleto.

- **Interface:** Usa um `TextFormField` com um `_localidadeController`.
- **Lógica:** Tenta preencher esse campo de texto buscando o valor da antiga coluna `agent.localidade`.
- **Persistência:** Salva a ocorrência usando o nome da localidade (String) em vez de uma chave estrangeira (ID).

## 3. Objetivo da Refatoração no Flutter

1.  **Remover o `_localidadeController`**.
2.  **Buscar a Lista de Localidades:** No `initState`, chamar uma função (ex: `get_my_localities`) para obter a lista de localidades do agente logado.
3.  **Substituir o Campo de Texto por um Dropdown:** Trocar o `TextFormField` por um `DropdownButtonFormField`.
4.  **Popular o Dropdown:** Usar a lista de localidades buscada para construir os `DropdownMenuItem`s.
5.  **Atualizar a Lógica de Estado:** Usar uma variável `String? _selectedLocalidadeId` para guardar o ID selecionado.
6.  **Ajustar `_saveForm` e `_populateFromOcorrencia`:** Os métodos devem usar o `localidade_id`.

## 4. Scripts SQL para a Refatoração

Abaixo estão os scripts SQL completos que foram executados para realizar esta mudança.

### Passo 1: Criar Novas Tabelas (`localidades` e `agentes_localidades`)
'''sql
-- Tabela para armazenar todas as localidades de forma única
CREATE TABLE public.localidades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.localidades ENABLE ROW LEVEL SECURITY;

-- Tabela de junção para associar agentes a múltiplas localidades
CREATE TABLE public.agentes_localidades (
    agente_id UUID NOT NULL REFERENCES public.agentes(id) ON DELETE CASCADE,
    localidade_id UUID NOT NULL REFERENCES public.localidades(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (agente_id, localidade_id) 
);
ALTER TABLE public.agentes_localidades ENABLE ROW LEVEL SECURITY;
'''

### Passo 2: Migrar Dados e Remover Coluna Antiga de `agentes`
'''sql
-- 1. Popula a tabela 'localidades' com os dados da coluna antiga
INSERT INTO public.localidades (nome)
SELECT DISTINCT localidade FROM public.agentes
WHERE localidade IS NOT NULL AND localidade <> ''
ON CONFLICT (nome) DO NOTHING;

-- 2. Cria a associação entre agente e localidade na nova tabela
INSERT INTO public.agentes_localidades (agente_id, localidade_id)
SELECT
    agentes.id,
    localidades.id
FROM
    public.agentes
JOIN
    public.localidades ON agentes.localidade = localidades.nome
ON CONFLICT (agente_id, localidade_id) DO NOTHING;

-- 3. Remove a coluna antiga da tabela de agentes
ALTER TABLE public.agentes
DROP COLUMN IF EXISTS localidade;
'''

### Passo 3: Modificar a Tabela `ocorrencias` (A PARTE CRÍTICA)
'''sql
-- 1. Adiciona a nova coluna de chave estrangeira
ALTER TABLE public.ocorrencias
ADD COLUMN localidade_id UUID;

-- 2. Popula a nova coluna 'localidade_id' com base nos nomes da coluna antiga
UPDATE public.ocorrencias
SET localidade_id = (
    SELECT id
    FROM public.localidades
    WHERE public.localidades.nome = public.ocorrencias.localidade
)
WHERE public.ocorrencias.localidade IS NOT NULL;

-- 3. Adiciona a restrição de chave estrangeira
ALTER TABLE public.ocorrencias
ADD CONSTRAINT fk_localidade
FOREIGN KEY (localidade_id)
REFERENCES public.localidades(id)
ON DELETE SET NULL; -- Define a ocorrência como nula se a localidade for apagada

-- 4. Remove a coluna de texto antiga 'localidade'
ALTER TABLE public.ocorrencias
DROP COLUMN IF EXISTS localidade;
'''

### Passo 4: Criar Função RPC para o App Flutter
'''sql
-- Função para o app buscar as localidades de um agente de forma segura
CREATE OR REPLACE FUNCTION get_my_localities()
RETURNS TABLE(id UUID, nome TEXT) 
SECURITY DEFINER -- Executa com os privilégios de quem a criou
AS $$
BEGIN
    RETURN QUERY
    SELECT l.id, l.nome
    FROM public.localidades l
    JOIN public.agentes_localidades al ON l.id = al.localidade_id
    WHERE al.agente_id = auth.uid();
END;
$$ LANGUAGE plpgsql;
'''
