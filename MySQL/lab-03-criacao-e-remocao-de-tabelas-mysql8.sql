/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-03-criacao-e-remocao-de-tabelas-mysql8.sql
  Objetivo     : Roteiro prático para criação, inspeção de metadados e remoção 
                 de tabelas (DDL) aplicando boas práticas no MySQL 8.x (InnoDB, 
                 utf8mb4, chave primária auto_increment).
  Autor        : Arley Ribeiro (DBA Júnior)
  Referencias  : MySQL 8.0 Reference Manual / CREATE TABLE & DROP TABLE Statements
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: PREPARAÇÃO DO SCHEMA DE TRABALHO
--------------------------------------------------------------------------------

-- Criar e selecionar o banco de dados do laboratório com padrões modernos
CREATE DATABASE IF NOT EXISTS arley_livraria
CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;

USE arley_livraria;


--------------------------------------------------------------------------------
-- PARTE 2: CRIAÇÃO DE TABELA (DDL - CREATE TABLE)
--------------------------------------------------------------------------------

-- Garantir remoção prévia para idempotência do script
DROP TABLE IF EXISTS editora;

-- Criar tabela 'editora' declarando Engine InnoDB e Charset explicitamente
CREATE TABLE editora (
  ideditora INT NOT NULL AUTO_INCREMENT,
  nomeeditora VARCHAR(45) NULL,
  PRIMARY KEY (ideditora)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


--------------------------------------------------------------------------------
-- PARTE 3: INSPEÇÃO DA ESTRUTURA E METADADOS DA TABELA
--------------------------------------------------------------------------------

-- Exibir a estrutura de colunas e tipos de dados da tabela
DESCRIBE editora;

-- Exibir o comando DDL de criação gerado pelo MySQL
SHOW CREATE TABLE editora;

-- Consultar metadados da tabela no dicionário de dados (information_schema)
SELECT table_name, engine, table_rows, data_length, table_collation
FROM information_schema.tables
WHERE table_schema = 'arley_livraria' AND table_name = 'editora';


--------------------------------------------------------------------------------
-- PARTE 4: REMOÇÃO DE TABELA E LIMPEZA DO AMBIENTE (CLEANUP)
--------------------------------------------------------------------------------

-- Remover a tabela criada no laboratório
DROP TABLE IF EXISTS editora;

-- Confirmar a remoção da tabela do schema ativo
SHOW TABLES FROM arley_livraria;

/*
-- Descomentar para remover o schema completo ao finalizar os estudos:

USE mysql;
DROP DATABASE IF EXISTS arley_livraria;
*/