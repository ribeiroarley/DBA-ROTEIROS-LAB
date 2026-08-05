/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-34-tablespaces.sql
  Objetivo     : Administração de InnoDB Tablespaces (Criação, Associação, Backup e Drop)
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / InnoDB Tablespaces
*******************************************************************************/

-- -----------------------------------------------------------------------------
-- CONCEITOS GERAIS: TABLESPACE INNODB
-- -----------------------------------------------------------------------------
-- Um TableSpace pode conter dados para uma ou mais tabelas InnoDB e índices associados.
-- Existem 3 tipos principais de tablespaces:
-- 
-- 1. System TableSpace (ibdata1): 
--    Dicionário de dados, area de apoio de buffer, logs de undo (quando aplicável).
--    Pode conter tabelas se innodb_file_per_table estiver OFF.
-- 
-- 2. File-per-table Tablespaces (*.ibd): 
--    Habilitado por padrão (innodb_file_per_table = ON).
--    Cada tabela InnoDB tem seu próprio arquivo de dados.
--    Vantagens: Recuperação de espaço ao truncar/deletar tabelas, melhor IO, facilidade de backup.
-- 
-- 3. General Tablespaces (Compartilhados): 
--    Introduzidos no MySQL 5.7.6. Podem conter várias tabelas.
--    Têm vantagem potencial de uso de memória de metadados quando há milhares de tabelas.
--    Desvantagens: O espaço liberado por exclusões/truncates é reaproveitado apenas internamente (não volta pro SO). Não suporta tabelas temporárias físicas.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- LAB 1: VERIFICANDO E CRIANDO TABLESPACES PADRÃO (FILE-PER-TABLE)
-- -----------------------------------------------------------------------------

-- Visualizando o diretório de dados atual
SELECT @@datadir;

-- Verificando se a configuração file-per-table está habilitada (Padrão MySQL 8.x: ON)
SHOW VARIABLES LIKE 'innodb_file_per_table';

-- Criando um banco de dados de testes
DROP DATABASE IF EXISTS db_tablespace_teste;
CREATE DATABASE db_tablespace_teste;
USE db_tablespace_teste;

-- Criando tabelas no padrão file-per-table
CREATE TABLE tabela1_fpt (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE tabela2_fpt (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao VARCHAR(255)
) ENGINE=InnoDB;

-- Inserindo dados realistas para teste de volume (SEM emojis ou caracteres especiais bizarros)
INSERT INTO tabela1_fpt (nome, descricao) VALUES 
('usuarioteste_01', 'Descricao padrao de teste para alocacao de disco'),
('usuarioteste_02', 'Registro anonimizado numero dois para laboratorio'),
('usuarioteste_03', 'Registro tres para validar insercao em innodb');

INSERT INTO tabela2_fpt (nome, descricao) VALUES 
('processo_alfa', 'Descricao do processo de testes de tablespace'),
('processo_beta', 'Processo secundario para verificar armazenamento');

-- Verificando os tablespaces criados para as tabelas (Usando view INNODB_TABLESPACES e FILES)
SELECT SPACE, NAME, FILE_SIZE, ALLOCATED_SIZE 
FROM INFORMATION_SCHEMA.INNODB_TABLESPACES 
WHERE NAME LIKE 'db_tablespace_teste%';

SELECT TABLESPACE_NAME, FILE_NAME 
FROM information_schema.FILES 
WHERE TABLESPACE_NAME LIKE 'db_tablespace_teste%';

-- Simulando desativação do file-per-table (As tabelas irão para o System Tablespace)
SET GLOBAL innodb_file_per_table = OFF;

CREATE TABLE tabela_system_ts (
    id INT PRIMARY KEY,
    valor VARCHAR(50)
) ENGINE=InnoDB;

-- Retornando ao padrão
SET GLOBAL innodb_file_per_table = ON;

-- -----------------------------------------------------------------------------
-- LAB 2: CRIANDO E ASSOCIANDO GENERAL TABLESPACES
-- -----------------------------------------------------------------------------

-- Criando um General Tablespace 
-- (O arquivo será criado relativo ao datadir, mas pode ser especificado caminho absoluto desde que em diretorio aprovado)
CREATE TABLESPACE ts_geral_01 ADD DATAFILE 'ts_geral_01.ibd' ENGINE=InnoDB;

-- Verificando o novo tablespace na INNODB_TABLESPACES
SELECT NAME, SPACE_TYPE, STATE, FILE_SIZE 
FROM INFORMATION_SCHEMA.INNODB_TABLESPACES 
WHERE NAME = 'ts_geral_01';

-- Criando tabelas e as associando ao General Tablespace
CREATE TABLE tabela3_geral (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_data VARCHAR(250)
) TABLESPACE = ts_geral_01 ENGINE=InnoDB;

CREATE TABLE tabela4_geral (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_data VARCHAR(250)
) TABLESPACE = ts_geral_01 ENGINE=InnoDB;

-- Inserindo dados de teste
INSERT INTO tabela3_geral (log_data) VALUES 
('Log de atividade 01 - Teste General Tablespace'),
('Log de atividade 02 - Compartilhamento de IBD'),
('Log de atividade 03 - Multiplas tabelas mesmo IBD');

-- Observação sobre tabelas temporárias: General Tablespaces NÃO suportam tabelas temporárias físicas.
-- CREATE TEMPORARY TABLE temp_erro (id INT) TABLESPACE = ts_geral_01; -- Isto geraria erro.
-- Porém, pode-se usar em memória:
CREATE TEMPORARY TABLE temp_memoria (id INT) ENGINE=MEMORY TABLESPACE=ts_geral_01;

-- -----------------------------------------------------------------------------
-- LAB 3: TAMANHOS DE PÁGINA CUSTOMIZADOS
-- -----------------------------------------------------------------------------
-- O padrão geralmente é 16KB.
SHOW VARIABLES LIKE 'innodb_page_size';

-- Criando tablespace com página de 8KB 
-- (NOTA: Só funciona se tabelas associadas declararem KEY_BLOCK_SIZE compatível)
CREATE TABLESPACE ts_page_8k ADD DATAFILE 'ts_page_8k.ibd' FILE_BLOCK_SIZE = 8192 ENGINE=InnoDB;

CREATE TABLE tabela_8k (
    id INT PRIMARY KEY,
    dado VARCHAR(100)
) TABLESPACE = ts_page_8k KEY_BLOCK_SIZE = 8 ENGINE=InnoDB;

INSERT INTO tabela_8k (id, dado) VALUES (1, 'Teste de Page Size 8K');

-- -----------------------------------------------------------------------------
-- LAB 4: MOVENDO TABELAS ENTRE TABLESPACES
-- -----------------------------------------------------------------------------

-- Podemos mover tabelas de file-per-table para um General Tablespace
ALTER TABLE tabela1_fpt TABLESPACE = ts_geral_01;

-- Verificando que a tabela1_fpt não possui mais tablespace próprio
SELECT NAME, SPACE_TYPE 
FROM INFORMATION_SCHEMA.INNODB_TABLESPACES 
WHERE NAME = 'db_tablespace_teste/tabela1_fpt'; -- Não deve retornar linha

-- Movendo a tabela de volta para file-per-table
ALTER TABLE tabela1_fpt TABLESPACE = innodb_file_per_table;

-- Movendo tabela que estava no System Tablespace (tabela_system_ts) para file-per-table
ALTER TABLE tabela_system_ts TABLESPACE = innodb_file_per_table;

-- -----------------------------------------------------------------------------
-- LAB 5: EXCLUSÃO DE TABLESPACES (DROP TABLESPACE)
-- -----------------------------------------------------------------------------
-- Regra: Um tablespace não pode ser deletado (DROP) enquanto contiver tabelas.

-- Consultando quais tabelas ainda pertencem ao ts_geral_01
SELECT 
    t.NAME AS Table_Name, 
    ts.NAME AS Tablespace_Name 
FROM INFORMATION_SCHEMA.INNODB_TABLES t
JOIN INFORMATION_SCHEMA.INNODB_TABLESPACES ts ON t.SPACE = ts.SPACE
WHERE ts.NAME = 'ts_geral_01';

-- Movendo ou Excluindo as tabelas do ts_geral_01
DROP TABLE tabela3_geral;
DROP TABLE tabela4_geral;

-- Agora o tablespace pode ser removido de forma segura
DROP TABLESPACE ts_geral_01;

-- Removendo os de 8K
DROP TABLE tabela_8k;
DROP TABLESPACE ts_page_8k;

-- Limpeza final do laboratório
DROP DATABASE IF EXISTS db_tablespace_teste;

-- FIM DO LABORATÓRIO
