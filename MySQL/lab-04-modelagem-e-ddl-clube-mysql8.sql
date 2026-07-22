/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-04-modelagem-e-ddl-clube-mysql8.sql
  Objetivo     : Roteiro DDL gerado a partir do modelo 'CLUBE' (MySQL Workbench).
                 Contém a criação de schemas, tabelas com chaves primárias,
                 chaves estrangeiras, motores InnoDB e collations modernas no MySQL 8.x.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Data Definition Language (DDL)
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: CRIAÇÃO E CONFIGURAÇÃO DO DATABASE/SCHEMA
--------------------------------------------------------------------------------

-- Garantir idempotência na criação do schema de trabalho
DROP DATABASE IF EXISTS arley_clube;

-- Criar schema 'arley_clube' com suporte a UTF-8 Unicode de 4 bytes
CREATE DATABASE arley_clube
CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;

USE arley_clube;


--------------------------------------------------------------------------------
-- PARTE 2: CRIAÇÃO DAS TABELAS INDEPENDENTES (ENTIDADES PRINCIPAIS)
--------------------------------------------------------------------------------

-- Tabela de Categorias/Departamentos de Associados
CREATE TABLE IF NOT EXISTS categoria (
  idcategoria INT NOT NULL AUTO_INCREMENT,
  nomecategoria VARCHAR(45) NOT NULL,
  PRIMARY KEY (idcategoria)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabela de Cargos/Funções dos Funcionários
CREATE TABLE IF NOT EXISTS cargo (
  idcargo INT NOT NULL AUTO_INCREMENT,
  nomecargo VARCHAR(45) NOT NULL,
  PRIMARY KEY (idcargo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


--------------------------------------------------------------------------------
-- PARTE 3: CRIAÇÃO DAS TABELAS DEPENDENTES (CHAVES ESTRANGEIRAS)
--------------------------------------------------------------------------------

-- Tabela de Associados do Clube
CREATE TABLE IF NOT EXISTS associado (
  idassociado INT NOT NULL AUTO_INCREMENT,
  nomeassociado VARCHAR(60) NOT NULL,
  cpf VARCHAR(14) NOT NULL,
  datanascimento DATE NULL,
  idcategoria INT NOT NULL,
  PRIMARY KEY (idassociado),
  UNIQUE INDEX uq_associado_cpf (cpf ASC) VISIBLE,
  INDEX idx_associado_categoria (idcategoria ASC) VISIBLE,
  CONSTRAINT fk_associado_categoria
    FOREIGN KEY (idcategoria)
    REFERENCES categoria (idcategoria)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabela de Funcionários do Clube
CREATE TABLE IF NOT EXISTS funcionario (
  idfuncionario INT NOT NULL AUTO_INCREMENT,
  nomefuncionario VARCHAR(60) NOT NULL,
  salario DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  idcargo INT NOT NULL,
  PRIMARY KEY (idfuncionario),
  INDEX idx_funcionario_cargo (idcargo ASC) VISIBLE,
  CONSTRAINT fk_funcionario_cargo
    FOREIGN KEY (idcargo)
    REFERENCES cargo (idcargo)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabela de Dependentes dos Associados
CREATE TABLE IF NOT EXISTS dependente (
  iddependente INT NOT NULL AUTO_INCREMENT,
  nomedependente VARCHAR(60) NOT NULL,
  parentesco VARCHAR(20) NOT NULL,
  idassociado INT NOT NULL,
  PRIMARY KEY (iddependente),
  INDEX idx_dependente_associado (idassociado ASC) VISIBLE,
  CONSTRAINT fk_dependente_associado
    FOREIGN KEY (idassociado)
    REFERENCES associado (idassociado)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


--------------------------------------------------------------------------------
-- PARTE 4: INSPEÇÃO DE ESTRUTURAS, ÍNDICES E RELACIONAMENTOS
--------------------------------------------------------------------------------

-- Listar tabelas criadas no schema ativo
SHOW TABLES FROM arley_clube;

-- Exibir relacionamentos e restrições de Foreign Key ativas
SELECT 
  table_name,
  constraint_name,
  referenced_table_name,
  foreign_key_checks
FROM information_schema.key_column_usage
WHERE table_schema = 'arley_clube' AND referenced_table_name IS NOT NULL;


--------------------------------------------------------------------------------
-- PARTE 5: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

/*
-- Descomentar o bloco abaixo para remover os objetos criados ao concluir o estudo:

USE mysql;
DROP DATABASE IF EXISTS arley_clube;
*/