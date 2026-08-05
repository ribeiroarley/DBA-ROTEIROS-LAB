/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-32-compactacao-tabelas.sql
  Objetivo     : Compactação de Tabelas InnoDB
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Optimization and Indexes
*******************************************************************************/

-- 1. Setup do Banco
CREATE DATABASE IF NOT EXISTS dbtestindicecompactado;
USE dbtestindicecompactado;

-- Criação de uma tabela base usando o information_schema para obter volume
DROP TABLE IF EXISTS big_table;
CREATE TABLE big_table AS SELECT * FROM information_schema.columns LIMIT 5000;

-- Inserindo mais volume de dados
INSERT INTO big_table SELECT * FROM big_table;
INSERT INTO big_table SELECT * FROM big_table;
INSERT INTO big_table SELECT * FROM big_table;

-- Adicionando Primary Key
ALTER TABLE big_table ADD id INT NOT NULL PRIMARY KEY AUTO_INCREMENT;

-- 2. Compressão de Tabelas InnoDB
-- O MySQL permite comprimir os dados usando ROW_FORMAT=COMPRESSED.
-- Em KEY_BLOCK_SIZE podemos definir o tamanho da página compactada (1, 2, 4, 8, 16 KB). 
-- O padrão de página do InnoDB é de 16KB. KEY_BLOCK_SIZE=8 ou 4 costumam ter bom desempenho.

DROP TABLE IF EXISTS key_block_size_8;
CREATE TABLE key_block_size_8 LIKE big_table;
ALTER TABLE key_block_size_8 KEY_BLOCK_SIZE=8 ROW_FORMAT=COMPRESSED;
INSERT INTO key_block_size_8 SELECT * FROM big_table;

DROP TABLE IF EXISTS key_block_size_4;
CREATE TABLE key_block_size_4 LIKE big_table;
ALTER TABLE key_block_size_4 KEY_BLOCK_SIZE=4 ROW_FORMAT=COMPRESSED;
INSERT INTO key_block_size_4 SELECT * FROM big_table;

-- A compressão reduz o tamanho físico, mas consome CPU extra.
-- É essencial fazer testes comparativos na infraestrutura real (SSD, CPU).

-- 3. Tabela Não Compactada (Padrão 16KB)
DROP TABLE IF EXISTS big_table_nocompress;
CREATE TABLE big_table_nocompress LIKE big_table;
INSERT INTO big_table_nocompress SELECT * FROM big_table;

-- 4. Otimização de Espaço
-- Ao deletar ou atualizar grandes volumes, espaços em branco fragmentam o arquivo.
-- O comando OPTIMIZE TABLE reorganiza o armazenamento físico e índices.
OPTIMIZE TABLE key_block_size_8;
OPTIMIZE TABLE key_block_size_4;
OPTIMIZE TABLE big_table_nocompress;

-- 5. Índices em Tabelas Compactadas
-- O MySQL compactará automaticamente os índices associados às tabelas compactadas.
ALTER TABLE key_block_size_8 ADD INDEX idx_table_name (TABLE_NAME);
ALTER TABLE big_table_nocompress ADD INDEX idx_table_name (TABLE_NAME);

-- 6. Remoção de Compressão
-- Para retornar a tabela ao estado original descompactado:
ALTER TABLE key_block_size_4 KEY_BLOCK_SIZE=16, ROW_FORMAT=DEFAULT;
OPTIMIZE TABLE key_block_size_4;
