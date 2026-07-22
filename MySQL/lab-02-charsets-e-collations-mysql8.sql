/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-02-charsets-e-collations-mysql8.sql
  Objetivo     : Roteiro prático para criação, alteração e inspeção de 
                 Character Sets e Collations em nível de Server, Schema e 
                 Sessão no MySQL 8.x no Windows.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Character Sets, Collations, Unicode
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: INSPEÇÃO DOS CHARSETS E COLLATIONS SUPORTADOS PELO MYSQL 8.X
--------------------------------------------------------------------------------

-- Listar todos os conjuntos de caracteres (Character Sets) disponíveis no MySQL
SHOW CHARACTER SET;

-- Listar especificamente o charset utf8mb4 e suas collations associadas
SHOW CHARACTER SET LIKE 'utf8mb4';

-- Consultar collations suportadas para o padrão utf8mb4 na tabela de metadados
SELECT collation_name, character_set_name, id, is_default
FROM information_schema.collations
WHERE character_set_name = 'utf8mb4'
ORDER BY collation_name;


--------------------------------------------------------------------------------
-- PARTE 2: CRIAÇÃO DE SCHEMA COM CHARSET E COLLATION PADRÃO (UTF8MB4)
--------------------------------------------------------------------------------

-- Garantir a remoção do banco caso já exista de execuções anteriores
DROP DATABASE IF EXISTS arley_clientes;

-- Criar o schema 'arley_clientes' utilizando o padrão utf8mb4_0900_ai_ci (Accent Insensitive / Case Insensitive)
CREATE DATABASE arley_clientes
CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;

-- Selecionar o banco de dados ativo
USE arley_clientes;

-- Verificar as configurações de charset e collation atribuídas ao schema atual
SELECT @@character_set_database AS charset_database, 
       @@collation_database AS collation_database;


--------------------------------------------------------------------------------
-- PARTE 3: ALTERAÇÃO DE CHARSET E COLLATION DO SCHEMA
--------------------------------------------------------------------------------

-- Alterar a collation padrão do schema 'arley_clientes' para suporte a regras específicas de ordenação e sensibilidade
ALTER SCHEMA arley_clientes
DEFAULT CHARACTER SET utf8mb4
DEFAULT COLLATE utf8mb4_vi_0900_as_cs;

-- Validar a alteração efetuada nas propriedades do schema
SELECT schema_name, default_character_set_name, default_collation_name
FROM information_schema.schemata
WHERE schema_name = 'arley_clientes';


--------------------------------------------------------------------------------
-- PARTE 4: CONSULTA AOS PARÂMETROS GLOBAIS E DE SESSÃO
--------------------------------------------------------------------------------

-- Verificar charset e collation globais do servidor MySQL
SHOW VARIABLES LIKE 'character_set_server';
SHOW VARIABLES LIKE 'collation_server';

-- Verificar charset e collation estabelecidos para a sessão ativa
SHOW VARIABLES LIKE 'character_set_connection';
SHOW VARIABLES LIKE 'collation_connection';


--------------------------------------------------------------------------------
-- PARTE 5: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

/*
-- Descomentar para remover o banco de dados criado durante os testes:

USE mysql;
DROP DATABASE IF EXISTS arley_clientes;
*/