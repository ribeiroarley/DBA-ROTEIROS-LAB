/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-33-partitions.sql
  Objetivo     : Configuração e gerenciamento de Table Partitioning e Subpartitions
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Partitioning
*******************************************************************************/

-- 1. Preparação do Ambiente
CREATE DATABASE IF NOT EXISTS lab_partitions;
USE lab_partitions;

-- ============================================================================
-- EXEMPLO 1: PARTITION BY RANGE (Data de Contratação)
-- ============================================================================
DROP TABLE IF EXISTS tb_funcionarios_range;

CREATE TABLE tb_funcionarios_range (
    id_funcionario INT NOT NULL,
    nome VARCHAR(50) NOT NULL,
    cargo VARCHAR(50) NOT NULL,
    data_contratacao DATE NOT NULL,
    PRIMARY KEY (id_funcionario, data_contratacao)
)
PARTITION BY RANGE (YEAR(data_contratacao)) (
    PARTITION p0 VALUES LESS THAN (2010),
    PARTITION p1 VALUES LESS THAN (2015),
    PARTITION p2 VALUES LESS THAN (2020),
    PARTITION p3 VALUES LESS THAN MAXVALUE
);

INSERT INTO tb_funcionarios_range (id_funcionario, nome, cargo, data_contratacao) VALUES
(1, 'usuarioteste1', 'Analista', '2008-05-10'),
(2, 'usuarioteste2', 'Desenvolvedor', '2012-08-15'),
(3, 'usuarioteste3', 'Gerente', '2018-01-20'),
(4, 'usuarioteste4', 'Diretor', '2023-11-01');

-- ============================================================================
-- EXEMPLO 2: PARTITION BY LIST (Regiões ou Lojas)
-- ============================================================================
DROP TABLE IF EXISTS tb_vendas_list;

CREATE TABLE tb_vendas_list (
    id_venda INT NOT NULL,
    id_loja INT NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_venda, id_loja)
)
PARTITION BY LIST (id_loja) (
    PARTITION p_norte VALUES IN (1, 2, 3),
    PARTITION p_sul VALUES IN (4, 5, 6),
    PARTITION p_leste VALUES IN (7, 8, 9),
    PARTITION p_oeste VALUES IN (10, 11, 12)
);

INSERT INTO tb_vendas_list (id_venda, id_loja, valor) VALUES
(100, 1, 1500.00),
(101, 5, 2300.50),
(102, 8, 450.75),
(103, 12, 900.00);

-- ============================================================================
-- EXEMPLO 3: PARTITION BY KEY E HASH
-- ============================================================================
DROP TABLE IF EXISTS tb_clientes_key;

CREATE TABLE tb_clientes_key (
    id_cliente INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    status_conta VARCHAR(20) NOT NULL,
    PRIMARY KEY (id_cliente)
)
PARTITION BY KEY()
PARTITIONS 4;

INSERT INTO tb_clientes_key (id_cliente, nome, status_conta) VALUES
(1, 'usuarioteste5', 'Ativo'),
(2, 'usuarioteste6', 'Inativo'),
(3, 'usuarioteste7', 'Ativo'),
(4, 'usuarioteste8', 'Suspenso');

-- ============================================================================
-- EXEMPLO 4: SUBPARTITIONS (RANGE E HASH)
-- ============================================================================
DROP TABLE IF EXISTS tb_pedidos_subpart;

CREATE TABLE tb_pedidos_subpart (
    id_pedido INT NOT NULL,
    data_pedido DATE NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_pedido, data_pedido)
)
PARTITION BY RANGE (YEAR(data_pedido))
SUBPARTITION BY HASH(TO_DAYS(data_pedido))
SUBPARTITIONS 2 (
    PARTITION p0 VALUES LESS THAN (2020),
    PARTITION p1 VALUES LESS THAN (2025),
    PARTITION p2 VALUES LESS THAN MAXVALUE
);

INSERT INTO tb_pedidos_subpart (id_pedido, data_pedido, total) VALUES
(1001, '2019-05-10', 350.00),
(1002, '2022-11-20', 1200.00),
(1003, '2024-01-15', 850.50),
(1004, '2026-03-10', 95.00);

-- ============================================================================
-- EXEMPLO 5: CONFIGURAÇÃO DE DISCOS (DATA DIRECTORY E INDEX DIRECTORY)
-- Nota: O diretorio deve estar configurado no innodb_directories no my.ini ou my.cnf
--       Se o diretorio nao estiver configurado, o comando podera falhar.
--       No InnoDB (formato padrao do MySQL 8.x) INDEX DIRECTORY e ignorado 
--       pois dados e indices sao guardados juntos no mesmo arquivo .ibd.
--       O DATA DIRECTORY pode ser utilizado por particao.
-- ============================================================================

-- Exemplo didatico (Descomente e ajuste os caminhos para uso real no Windows)
/*
DROP TABLE IF EXISTS tb_logs_disco;

CREATE TABLE tb_logs_disco (
    id_log INT NOT NULL,
    data_log DATE NOT NULL,
    mensagem VARCHAR(255),
    PRIMARY KEY (id_log, data_log)
)
PARTITION BY RANGE (YEAR(data_log)) (
    PARTITION p0 VALUES LESS THAN (2023) DATA DIRECTORY = 'C:/Temp/dados_old',
    PARTITION p1 VALUES LESS THAN (2025) DATA DIRECTORY = 'C:/Temp/dados_new'
);
*/

-- ============================================================================
-- CONSULTAS DE GERENCIAMENTO DE PARTICOES
-- ============================================================================
-- Verificando as particoes criadas no banco de dados
SELECT 
    TABLE_NAME, 
    PARTITION_NAME, 
    SUBPARTITION_NAME, 
    PARTITION_METHOD, 
    TABLE_ROWS 
FROM 
    information_schema.PARTITIONS 
WHERE 
    TABLE_SCHEMA = 'lab_partitions' 
    AND TABLE_NAME IN ('tb_funcionarios_range', 'tb_vendas_list', 'tb_clientes_key', 'tb_pedidos_subpart');

-- Exemplo de consulta lendo direto de uma particao especifica
SELECT * FROM tb_funcionarios_range PARTITION (p1);

-- ============================================================================
-- MANUTENCAO DE PARTICOES
-- ============================================================================
-- Adicionando uma particao
ALTER TABLE tb_vendas_list ADD PARTITION (
    PARTITION p_centro VALUES IN (13, 14, 15)
);

-- Removendo uma particao (Aviso: Isso apaga todos os dados que estavam na particao)
-- ALTER TABLE tb_funcionarios_range DROP PARTITION p0;
