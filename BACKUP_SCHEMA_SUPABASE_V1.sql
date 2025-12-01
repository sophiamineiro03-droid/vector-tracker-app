-- BACKUP REALIZADO EM: 20/11/2025
-- ARQUIVO: BACKUP_SCHEMA_SUPABASE_V1.sql

-- ==============================================================================
-- 1. DADOS DA TABELA: AGENTES
-- ==============================================================================
INSERT INTO "public"."agentes" ("id", "user_id", "municipio_id", "nome", "email", "registro_matricula", "ativo", "created_at", "avatar_url") VALUES ('2c7260cc-6464-4b19-b253-0899e7ce43e5', 'bcd90f6b-f39e-4d69-bec0-e6e9215e3e5f', '90f66b55-3983-4cb2-990d-9597ca37cb1c', 'João Agente', 'joao.agente@example.com', '67890', 'true', '2025-11-08 18:40:56.117711+00', null), ('3fb08d1a-c30e-44ef-92d9-61039a939237', 'fd440a89-1062-4834-9037-3b9eacbf3650', '33bec900-22b7-4ea1-a92f-f130151c02f1', 'Agente Teresina 01', 'agente.example@email.com', 'MAT-TRS-001', 'true', '2025-11-12 20:28:58.222218+00', 'https://wcxiziyrjiqvhmxvpfga.supabase.co/storage/v1/object/public/profile_pictures/fd440a89-1062-4834-9037-3b9eacbf3650.jpg'), ('660ba263-9aa9-463d-a5d9-6a40d81f8b3d', 'cdc5f127-a0f7-493e-95f0-4a64ce1e2082', '90f66b55-3983-4cb2-990d-9597ca37cb1c', 'Sophia', 'sophia@example.com', '12345', 'true', '2025-11-08 18:40:56.117711+00', null), ('828698e3-a93a-412e-b472-9508fcccec62', 'a05904b5-7304-4321-b526-8129d3d924de', 'c5cdea81-1565-4a2a-a234-afada1b7f678', 'sophia alves mineiro', 'sophiamineiro03@gmail.com', null, 'true', '2025-11-20 14:28:55.894504+00', null), ('9822ed24-9cca-4dd5-8491-d394b8c373f2', null, 'c5cdea81-1565-4a2a-a234-afada1b7f678', 'João Pereira (EDITAR)', 'joao.pereira@email.com', '1002', 'true', '2025-11-10 19:24:29.476752+00', null), ('a3b59e9f-c446-4253-a8dd-28f57036ba82', '59c2c046-7726-455e-a153-bc96a8ada796', 'c5cdea81-1565-4a2a-a234-afada1b7f678', 'Sophia Alves', 'sophiamineiro04@gmail.com', null, 'true', '2025-11-25 18:12:58.979211+00', null), ('d74eab4b-b143-4223-9a11-911877c076e7', '37a22a0e-880e-4d4b-898f-b31f9030135f', 'c5cdea81-1565-4a2a-a234-afada1b7f678', 'Maria ', 'maria.silva@email.com', '1001', 'true', '2025-11-10 19:24:29.476752+00', 'https://wcxiziyrjiqvhmxvpfga.supabase.co/storage/v1/object/public/profile_pictures/37a22a0e-880e-4d4b-898f-b31f9030135f.jpg');

-- ==============================================================================
-- 2. ESTRUTURA DA TABELA: AGENTES
-- ==============================================================================
create table public.agentes (
  id uuid not null default gen_random_uuid (),
  user_id uuid null,
  municipio_id uuid not null,
  nome text not null,
  email text not null,
  registro_matricula text null,
  ativo boolean null default true,
  created_at timestamp with time zone null default timezone ('utc'::text, now()),
  avatar_url text null,
  constraint agentes_pkey primary key (id),
  constraint agentes_email_key unique (email),
  constraint agentes_registro_matricula_key unique (registro_matricula),
  constraint agentes_user_id_key unique (user_id),
  constraint agentes_municipio_id_fkey foreign KEY (municipio_id) references municipios (id),
  constraint agentes_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete set null
) TABLESPACE pg_default;

-- ==============================================================================
-- 3. DADOS DA TABELA: AGENTES_LOCALIDADES
-- ==============================================================================
INSERT INTO "public"."agentes_localidades" ("id", "agente_id", "localidade_id") VALUES ('24a1c5cb-5d10-44f2-aca6-5cd8812c2e03', '3fb08d1a-c30e-44ef-92d9-61039a939237', '3edd21ce-6cbd-4a93-a9de-6ba45f9903a4'), ('3461b143-d36b-4088-a070-e8791c765cff', 'd74eab4b-b143-4223-9a11-911877c076e7', '91715184-c173-4bb1-a668-c9d6a065e79a'), ('a922ae3a-002a-4b59-a800-8dbd428de72b', '660ba263-9aa9-463d-a5d9-6a40d81f8b3d', '0c4e35cb-0867-4572-89f7-3633adce01bb'), ('b1f3b158-c4c9-46c0-ade0-105d19a18a48', 'a3b59e9f-c446-4253-a8dd-28f57036ba82', '91715184-c173-4bb1-a668-c9d6a065e79a'), ('b2b90e7d-54f5-43fc-9f86-9ca115700ce3', '828698e3-a93a-412e-b472-9508fcccec62', '91715184-c173-4bb1-a668-c9d6a065e79a');

-- ==============================================================================
-- 4. ESTRUTURA DA TABELA: AGENTES_LOCALIDADES
-- ==============================================================================
create table public.agentes_localidades (
  id uuid not null default gen_random_uuid (),
  agente_id uuid not null,
  localidade_id uuid not null,
  constraint agentes_localidades_pkey primary key (id),
  constraint agentes_localidades_agente_id_localidade_id_key unique (agente_id, localidade_id),
  constraint agentes_localidades_agente_id_fkey foreign KEY (agente_id) references agentes (id) on delete CASCADE,
  constraint agentes_localidades_localidade_id_fkey foreign KEY (localidade_id) references localidades (id) on delete CASCADE
) TABLESPACE pg_default;

-- ==============================================================================
-- 5. DADOS DA TABELA: DENUNCIAS
-- (Incluindo os testes, para garantir integridade total)
-- ==============================================================================
INSERT INTO "public"."denuncias" ("id", "created_at", "user_id", "descricao", "foto_url", "latitude", "longitude", "rua", "numero", "bairro", "cidade", "estado", "localidade_id", "status", "agente_responsavel_id", "complemento") VALUES ('037eaa47-03b9-4308-a48a-5724ebc42f03', '2025-11-25 23:47:08.316723+00', null, 'encontrei um barbeiro ', 'https://wcxiziyrjiqvhmxvpfga.supabase.co/storage/v1/object/public/imagens_denuncias/037eaa47-03b9-4308-a48a-5724ebc42f03/scaled_1000073674.jpg', null, null, 'Rua São Joaquim', '88', 'Tapuia', '33bec900-22b7-4ea1-a92f-f130151c02f1', null, '3edd21ce-6cbd-4a93-a9de-6ba45f9903a4', 'atendida', null, 'Rural'), ('389d70f5-61d2-4985-9e42-50900df05540', '2025-11-26 07:45:22.020024+00', null, 'Encontrei esse barbeiro aqui na porta da minha casa.', 'https://wcxiziyrjiqvhmxvpfga.supabase.co/storage/v1/object/public/imagens_denuncias/389d70f5-61d2-4985-9e42-50900df05540/scaled_1001957524.jpg', '-5.0546115', '-42.7981855', 'Rua Desembargador Robert Wall de Carvalho', '773', 'Ininga', '33bec900-22b7-4ea1-a92f-f130151c02f1', null, '3edd21ce-6cbd-4a93-a9de-6ba45f9903a4', 'pendente_envio', null, 'ap20'), ('77bf518b-779e-454c-b2a5-1ffb72f73520', '2025-11-26 10:11:31.350887+00', null, '', 'https://wcxiziyrjiqvhmxvpfga.supabase.co/storage/v1/object/public/imagens_denuncias/77bf518b-779e-454c-b2a5-1ffb72f73520/scaled_be57348a-2266-49b2-a3f8-5d5780d7707a462207125765714363.jpg', '-5.0553907', '-42.7912999', 'Campus Universitário Ministro Petrônio Portella - Ininga', '123', 'Ininga', '33bec900-22b7-4ea1-a92f-f130151c02f1', null, '3edd21ce-6cbd-4a93-a9de-6ba45f9903a4', 'pendente_envio', null, ''), ('e9cac957-4534-47d4-9be9-8bd06c88acdd', '2025-11-26 07:29:53.743973+00', null, 'encontrei esse barbeiro no quintal de casa', 'https://wcxiziyrjiqvhmxvpfga.supabase.co/storage/v1/object/public/imagens_denuncias/e9cac957-4534-47d4-9be9-8bd06c88acdd/scaled_1002419239.jpg', '-5.0575302', '-42.783714', 'R. Manoel Felício de Carvalho', '1955', 'Planalto', '33bec900-22b7-4ea1-a92f-f130151c02f1', null, '3edd21ce-6cbd-4a93-a9de-6ba45f9903a4', 'pendente_envio', null, 'Edifício ');

-- ==============================================================================
-- 6. ESTRUTURA DA TABELA: DENUNCIAS
-- ==============================================================================
create table public.denuncias (
  id uuid not null default gen_random_uuid (),
  created_at timestamp with time zone null default timezone ('utc'::text, now()),
  user_id uuid null,
  descricao text null,
  foto_url text null,
  latitude double precision null,
  longitude double precision null,
  rua text null,
  numero text null,
  bairro text null,
  cidade uuid null,
  estado text null,
  localidade_id uuid null,
  status text not null default 'Pendente'::text,
  agente_responsavel_id uuid null,
  complemento text null,
  constraint denuncias_pkey primary key (id),
  constraint denuncias_agente_responsavel_id_fkey foreign KEY (agente_responsavel_id) references agentes (id),
  constraint denuncias_cidade_fkey foreign KEY (cidade) references municipios (id),
  constraint denuncias_localidade_id_fkey foreign KEY (localidade_id) references localidades (id),
  constraint denuncias_user_id_fkey foreign KEY (user_id) references auth.users (id)
) TABLESPACE pg_default;

-- ==============================================================================
-- 7. DADOS DA TABELA: MUNICIPIOS
-- ==============================================================================
INSERT INTO "public"."municipios" ("id", "nome", "estado", "codigo_ibge", "created_at") VALUES ('33bec900-22b7-4ea1-a92f-f130151c02f1', 'Teresina', 'PI', '2211001', '2025-11-12 20:22:24.464783+00'), ('90f66b55-3983-4cb2-990d-9597ca37cb1c', 'Dom Inocêncio', 'PI', '2203251', '2025-11-08 18:37:24.083953+00'), ('c5cdea81-1565-4a2a-a234-afada1b7f678', 'Castelo do Piauí', 'PI', '2202604', '2025-11-10 19:24:29.476752+00');

-- ==============================================================================
-- 8. ESTRUTURA DA TABELA: MUNICIPIOS
-- ==============================================================================
create table public.municipios (
  id uuid not null default gen_random_uuid (),
  nome text not null,
  estado character(2) not null,
  codigo_ibge text null,
  created_at timestamp with time zone null default timezone ('utc'::text, now()),
  constraint municipios_pkey primary key (id),
  constraint municipios_codigo_ibge_key unique (codigo_ibge),
  constraint municipios_nome_key unique (nome)
) TABLESPACE pg_default;

-- ==============================================================================
-- 9. DADOS DA TABELA: LOCALIDADES
-- (Convertido do CSV fornecido)
-- ==============================================================================
INSERT INTO "public"."localidades" ("id", "municipio_id", "nome", "codigo", "categoria", "created_at") VALUES 
('0c4e35cb-0867-4572-89f7-3633adce01bb', '90f66b55-3983-4cb2-990d-9597ca37cb1c', 'Centro', NULL, NULL, '2025-11-08 18:37:24.083953+00'),
('3edd21ce-6cbd-4a93-a9de-6ba45f9903a4', '33bec900-22b7-4ea1-a92f-f130151c02f1', 'Localidade 01', '01', 'Urbana', '2025-11-12 20:22:24.464783+00'),
('91715184-c173-4bb1-a668-c9d6a065e79a', 'c5cdea81-1565-4a2a-a234-afada1b7f678', 'Centro', NULL, NULL, '2025-11-10 19:24:29.476752+00');

-- ==============================================================================
-- 10. ESTRUTURA DA TABELA: LOCALIDADES
-- ==============================================================================
create table public.localidades (
  id uuid not null default gen_random_uuid (),
  municipio_id uuid not null,
  nome text not null,
  codigo text null,
  categoria text null,
  created_at timestamp with time zone null default timezone ('utc'::text, now()),
  constraint localidades_pkey primary key (id),
  constraint localidades_municipio_id_codigo_key unique (municipio_id, codigo),
  constraint localidades_municipio_id_nome_key unique (municipio_id, nome),
  constraint localidades_municipio_id_fkey foreign KEY (municipio_id) references municipios (id) on delete CASCADE
) TABLESPACE pg_default;

-- ==============================================================================
-- 11. DADOS DA TABELA: OCORRENCIAS
-- ==============================================================================
INSERT INTO "public"."ocorrencias" ("id", "created_at", "agente_id", "denuncia_id", "localidade_id", "tipo_atividade", "data_atividade", "numero_pit", "endereco", "numero", "complemento", "latitude", "longitude", "codigo_localidade", "categoria_localidade", "pendencia_pesquisa", "pendencia_borrifacao", "nome_morador", "numero_anexo", "situacao_imovel", "tipo_parede", "tipo_teto", "melhoria_habitacional", "vestigios_intradomicilio", "barbeiros_intradomicilio", "vestigios_peridomicilio", "barbeiros_peridomicilio", "inseticida", "numero_cargas", "codigo_etiqueta", "sincronizado", "fotos_urls") VALUES ('0a8eb308-769d-422d-bb01-fa021093eebf', '2025-11-26 07:37:22.486383+00', '3fb08d1a-c30e-44ef-92d9-61039a939237', null, '3edd21ce-6cbd-4a93-a9de-6ba45f9903a4', '["pesquisa"]', '2025-11-26', '', 'R. Dra. Alaíde Marques', '873', '', '-5.0503571', '-42.794587', '', '', 'semPendencias', 'semPendencias', '', null, null, 'Alvenaria c/ reboco', 'Telha', 'true', 'Nenhum', '0', 'Nenhum', '0', '', '0', '', 'false', '"{]}'), ('81dd70f3-a11a-4618-ba30-994b0302bb19', '2025-11-26 00:23:23.913723+00', 'd74eab4b-b143-4223-9a11-911877c076e7', null, '91715184-c173-4bb1-a668-c9d6a065e79a', '["pesquisa","atendimentoPIT","borrifacao"]', '2025-11-26', '64646', 'benejsj', 'nenrjeje', 'hdhehe', null, null, 'shhsje', 'jejejej', 'semPendencias', 'semPendencias', 'hshshe', '1', 'nova', 'Barro s/ reboco', 'Metálico', 'true', 'Nenhum', '6', 'Ovos', '8', 'hwhehe', '1', 'hwhwh', 'false', '"{\"https://wcxiziyrjiqvhmxvpfga.supabase.co/storage/v1/object/public/fotos-ocorrencias/81dd70f3-a11a-4618-ba30-994b0302bb19/3bdfb207-8f21-4b5a-b503-9fa668ca2aa2.jpg\"]}'), ('d5be255a-5764-42fb-ba1e-57de39c1936c', '2025-11-25 23:49:48.469947+00', '3fb08d1a-c30e-44ef-92d9-61039a939237', '037eaa47-03b9-4308-a48a-5724ebc42f03', '3edd21ce-6cbd-4a93-a9de-6ba45f9903a4', '["pesquisa","borrifacao"]', '2025-11-25', '', 'Rua São Joaquim', '88', 'Rural', null, null, '01', '', 'semPendencias', 'semPendencias', 'Fictício', '1', 'nova', 'Alvenaria s/ reboco', 'Palha', 'true', 'Nenhum', '1', 'Ovos', '0', 'alfacipermetrina', '2', '001', 'false', '"{\"https://wcxiziyrjiqvhmxvpfga.supabase.co/storage/v1/object/public/imagens_denuncias/037eaa47-03b9-4308-a48a-5724ebc42f03/scaled_1000073674.jpg\"]}');

-- ==============================================================================
-- 12. ESTRUTURA DA TABELA: OCORRENCIAS
-- ==============================================================================
create table public.ocorrencias (
  id uuid not null default gen_random_uuid (),
  created_at timestamp with time zone null default timezone ('utc'::text, now()),
  agente_id uuid not null,
  denuncia_id uuid null,
  localidade_id uuid null,
  tipo_atividade text null,
  data_atividade date null,
  numero_pit text null,
  endereco text null,
  numero text null,
  complemento text null,
  latitude double precision null,
  longitude double precision null,
  codigo_localidade text null,
  categoria_localidade text null,
  pendencia_pesquisa text null,
  pendencia_borrifacao text null,
  nome_morador text null,
  numero_anexo integer null,
  situacao_imovel text null,
  tipo_parede text null,
  tipo_teto text null,
  melhoria_habitacional boolean null,
  vestigios_intradomicilio text null,
  barbeiros_intradomicilio integer null,
  vestigios_peridomicilio text null,
  barbeiros_peridomicilio integer null,
  inseticida text null,
  numero_cargas integer null,
  codigo_etiqueta text null,
  sincronizado boolean null default false,
  fotos_urls text[] null,
  constraint ocorrencias_pkey primary key (id),
  constraint ocorrencias_agente_id_fkey foreign KEY (agente_id) references agentes (id),
  constraint ocorrencias_denuncia_id_fkey foreign KEY (denuncia_id) references denuncias (id),
  constraint ocorrencias_localidade_id_fkey foreign KEY (localidade_id) references localidades (id)
) TABLESPACE pg_default;

-- ==============================================================================
-- 13. ESTRUTURA DA TABELA: PROBLEM_REPORTS
-- ==============================================================================
create table public.problem_reports (
  id uuid not null default gen_random_uuid (),
  user_id uuid null,
  description text not null,
  created_at timestamp with time zone not null default now(),
  status text null default 'Novo'::text,
  constraint problem_reports_pkey primary key (id),
  constraint problem_reports_user_id_fkey foreign KEY (user_id) references auth.users (id)
) TABLESPACE pg_default;

-- ==============================================================================
-- BACKUP CONCLUÍDO COM SUCESSO
-- ==============================================================================

-- ==============================================================================
-- NOTAS DE ATUALIZAÇÃO DO PROJETO (CHANGELOG) - 27/11/2025
-- ==============================================================================
-- CONTEXTO:
-- Implementação da funcionalidade de "Localidade Manual" e "Registro Proativo".
--
-- ALTERAÇÕES NO BANCO DE DADOS NECESSÁRIAS:
-- 1. Tabela 'ocorrencias':
--    - Adição da coluna 'nome_localidade' (TEXT, Nullable) para armazenar o nome do sítio digitado manualmente.
--    - A coluna 'localidade_id' deve permitir valores NULL (já configurado, mas reforçado logicamente).
--
-- COMANDOS SQL PARA APLICAÇÃO (MIGRATION):
/*
   ALTER TABLE public.ocorrencias ADD COLUMN IF NOT EXISTS nome_localidade text;
   ALTER TABLE public.ocorrencias ALTER COLUMN localidade_id DROP NOT NULL;
*/
--
-- ALTERAÇÕES NO APP (FLUTTER):
-- 1. Modelos atualizados (Ocorrencia, Agente) para suportar os novos campos.
-- 2. Telas de 'Pendências' e 'Mapa' ajustadas para filtrar corretamente e exibir dados manuais.
-- 3. 'Meu Trabalho' atualizado para mostrar o nome da localidade manual se não houver ID vinculado.
-- ==============================================================================
