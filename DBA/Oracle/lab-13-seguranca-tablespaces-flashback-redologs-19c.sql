/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-13-seguranca-tablespaces-flashback-redologs-19c.sql
  Objetivo     : Roteiro prático abrangendo Usuários/Privilégios, Gestão Avançada
                 de Tablespaces (Bigfile/Smallfile/Temp/Undo), Recursos de
                 Oracle Flashback (Transaction, Table, Database) e Administração/
                 Multiplexação de Redo Logs e Archivelogs no Oracle 19c (Windows).
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c Security / Administrator's Guide
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: GESTÃO DE ROLES, PRIVILÉGIOS DE SISTEMA E DE OBJETOS
--------------------------------------------------------------------------------

-- Conectar como SYSDBA e alterar para o PDB de trabalho
CONNECT / AS SYSDBA;

ALTER PLUGGABLE DATABASE ORCLPDB OPEN;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Consultar Roles existentes e criadas pelo usuário
SELECT role, oracle_maintained FROM dba_roles WHERE oracle_maintained = 'N';

-- Criar e descartar Role personalizada
CREATE ROLE role_finance_lab;
DROP ROLE role_finance_lab;

-- Criar usuários para testes de privilégios
CREATE USER arleyribeiro IDENTIFIED BY "arley123" CONTAINER=CURRENT;
GRANT CREATE SESSION TO arleyribeiro CONTAINER=CURRENT;

CREATE USER livraria IDENTIFIED BY "liv123" CONTAINER=CURRENT;
GRANT CREATE SESSION, CREATE TABLE TO livraria CONTAINER=CURRENT;
ALTER USER livraria QUOTA UNLIMITED ON users;

-- Criar estrutura e dados de exemplo no schema LIVRARIA
CREATE TABLE livraria.minha_tabela2 (
    id   NUMBER PRIMARY KEY,
    nome VARCHAR2(50) NOT NULL
);

INSERT INTO livraria.minha_tabela2 (id, nome) VALUES (1, 'Arley Ribeiro');
COMMIT;

-- Concessão de privilégios de objeto granulares
GRANT SELECT, INSERT, UPDATE, DELETE ON livraria.minha_tabela2 TO arleyribeiro;

-- Testar acesso na sessão arleyribeiro
CONNECT arleyribeiro/arley123@//localhost:1521/ORCLPDB;
SELECT * FROM livraria.minha_tabela2;

-- Revogar permissões
CONNECT livraria/liv123@//localhost:1521/ORCLPDB;
REVOKE SELECT, INSERT, UPDATE, DELETE ON livraria.minha_tabela2 FROM arleyribeiro;

-- Concessão em nível de coluna via View de Segurança
CREATE OR REPLACE VIEW livraria.minha_view AS SELECT nome FROM livraria.minha_tabela2;
GRANT SELECT ON livraria.minha_view TO arleyribeiro;

-- Concessão em massa via Bloco Anônimo PL/SQL (Oracle 19c)
CONNECT / AS SYSDBA;
ALTER SESSION SET CONTAINER = ORCLPDB;

BEGIN
    FOR r IN (SELECT owner, table_name FROM dba_tables WHERE owner = 'LIVRARIA') LOOP
        EXECUTE IMMEDIATE 'GRANT SELECT ON ' || r.owner || '.' || r.table_name || ' TO arleyribeiro';
    END LOOP;
END;
/


--------------------------------------------------------------------------------
-- PARTE 2: GESTÃO DE TABLESPACES, QUOTAS E REDIMENSIONAMENTO
--------------------------------------------------------------------------------

-- Criar diretório para Datafiles no Windows Server antes da execução
-- mkdir C:\oracle\clientestabelas

-- Criar Smallfile Tablespace com Autoextend
CREATE TABLESPACE tbs_clientes_loja1
    DATAFILE 'C:\oracle\clientestabelas\tbsclientes_loja1.dbf' SIZE 100M
    AUTOEXTEND ON NEXT 10M MAXSIZE 500M;

-- Criar Usuário com Quota especificada
CREATE USER arley_user IDENTIFIED BY "senha123"
    DEFAULT TABLESPACE tbs_clientes_loja1
    QUOTA 30M ON tbs_clientes_loja1;

-- Mover Tabela entre Tablespaces ONLINE (Sem bloqueio DML)
ALTER TABLE livraria.minha_tabela2 MOVE ONLINE TABLESPACE tbs_clientes_loja1 PARALLEL 2;

-- Adicionar novo Datafile para expandir Smallfile Tablespace
ALTER TABLESPACE tbs_clientes_loja1 
    ADD DATAFILE 'C:\oracle\clientestabelas\tbsclientes_loja2.dbf' SIZE 200M AUTOEXTEND ON;

-- Criar e Redimensionar Bigfile Tablespace
CREATE BIGFILE TABLESPACE tbs_bigfile_lab 
    DATAFILE 'C:\oracle\clientestabelas\tbs_bigfile.dbf' SIZE 1G;

ALTER TABLESPACE tbs_bigfile_lab RESIZE 2G;

-- Mover Datafile de local físico (Passo a passo lógico)
ALTER TABLESPACE tbs_clientes_loja1 OFFLINE;

/*
  -- Executar no Prompt de Comando Windows (cmd):
  copy C:\oracle\clientestabelas\tbsclientes_loja1.dbf C:\oracle\tbsclientes_loja1.dbf
*/

ALTER TABLESPACE tbs_clientes_loja1 
    RENAME DATAFILE 'C:\oracle\clientestabelas\tbsclientes_loja1.dbf' 
                 TO 'C:\oracle\tbsclientes_loja1.dbf';

ALTER TABLESPACE tbs_clientes_loja1 ONLINE;


--------------------------------------------------------------------------------
-- PARTE 3: TEMPORARY TABLESPACES E TEMPORARY GROUPS
--------------------------------------------------------------------------------

-- Criar Temporary Tablespaces
CREATE TEMPORARY TABLESPACE temp_lab01
    TEMPFILE 'C:\oracle\clientestabelas\temp01_lab.dbf' SIZE 50M
    AUTOEXTEND ON NEXT 10M MAXSIZE 200M;

CREATE TEMPORARY TABLESPACE temp_lab02
    TEMPFILE 'C:\oracle\clientestabelas\temp02_lab.dbf' SIZE 50M
    TABLESPACE GROUP grp_temp_clientes;

-- Atribuir Temp Tablespace ao Usuário
ALTER USER arleyribeiro TEMPORARY TABLESPACE temp_lab01;

-- Alterar Default Temp Tablespace da Instância PDB
ALTER DATABASE DEFAULT TEMPORARY TABLESPACE temp_lab01;


--------------------------------------------------------------------------------
-- PARTE 4: UNDO TABLESPACE, CONFIGURAÇÕES E GERENCIAMENTO
--------------------------------------------------------------------------------

-- Consultar parâmetros Atuais de UNDO
SHOW PARAMETER UNDO;

-- Alterar tempo de retenção de UNDO (em segundos)
ALTER SYSTEM SET UNDO_RETENTION = 2400 SCOPE=BOTH;

-- Criar novo Undo Tablespace
CREATE UNDO TABLESPACE undotbs2 
    DATAFILE 'C:\oracle\clientestabelas\undotbs02.dbf' SIZE 100M;

-- Mudar Undo Tablespace ativo na instância
ALTER SYSTEM SET UNDO_TABLESPACE = undotbs2 SCOPE=BOTH;

-- Habilitar retenção garantida (GUARANTEE)
ALTER TABLESPACE undotbs2 RETENTION GUARANTEE;
ALTER TABLESPACE undotbs2 RETENTION NOGUARANTEE;


--------------------------------------------------------------------------------
-- PARTE 5: TECNOLOGIA ORACLE FLASHBACK (QUERY, TABLE, RESTORE POINT, DATABASE)
--------------------------------------------------------------------------------

-- Conectar no CDB$ROOT para configurações Globais de Flashback e Archivelog
CONNECT / AS SYSDBA;

-- Configurar Área de Recuperação (FRA)
ALTER SYSTEM SET DB_RECOVERY_FILE_DEST_SIZE = 2G SCOPE=BOTH;
ALTER SYSTEM SET DB_RECOVERY_FILE_DEST = 'C:\oracle\fast_recovery_area' SCOPE=BOTH;

/*
  -- Procedimento para habilitar ARCHIVELOG e FLASHBACK no CDB:
  SHUTDOWN IMMEDIATE;
  STARTUP MOUNT;
  ALTER DATABASE ARCHIVELOG;
  ALTER DATABASE FLASHBACK ON;
  ALTER DATABASE OPEN;
*/

ALTER SESSION SET CONTAINER = ORCLPDB;

-- 1. Flashback Query (Consultar estado histórico de dados)
SELECT * FROM livraria.minha_tabela2 AS OF TIMESTAMP (SYSDATE - INTERVAL '15' MINUTE);

-- 2. Flashback Table (Reverter alterações DML em uma tabela)
ALTER TABLE livraria.minha_tabela2 ENABLE ROW MOVEMENT;
FLASHBACK TABLE livraria.minha_tabela2 TO TIMESTAMP (SYSDATE - INTERVAL '5' MINUTE);
ALTER TABLE livraria.minha_tabela2 DISABLE ROW MOVEMENT;

-- 3. Flashback Drop (Recuperar tabela descartada da lixeira)
DROP TABLE livraria.minha_tabela2;
SELECT object_name, original_name, type FROM user_recyclebin;
FLASHBACK TABLE livraria.minha_tabela2 TO BEFORE DROP;

-- 4. Guaranteed Restore Point
CONNECT / AS SYSDBA;
CREATE RESTORE POINT rp_limpo_lab GUARANTEE FLASHBACK DATABASE;

-- Consultar Restore Points
SELECT scn, name, time FROM v$restore_point;

/*
  -- Para reverter todo o banco para o Restore Point:
  SHUTDOWN IMMEDIATE;
  STARTUP MOUNT;
  FLASHBACK DATABASE TO RESTORE POINT rp_limpo_lab;
  ALTER DATABASE OPEN RESETLOGS;
*/

DROP RESTORE POINT rp_limpo_lab;


--------------------------------------------------------------------------------
-- PARTE 6: GERENCIAMENTO E MULTIPLEXAÇÃO DE REDO LOGS & ARCHIVELOGS
--------------------------------------------------------------------------------

CONNECT / AS SYSDBA;

-- Consultar Grupos e Membros de Redo Log Atuais
SELECT group#, sequence#, status, bytes/1024/1024 AS size_mb FROM v$log;
SELECT group#, member FROM v$logfile;

-- Adicionar Novo Grupo de Redo Log Multiplexado (2 membros em locais distintos)
ALTER DATABASE ADD LOGFILE GROUP 4 
  ('C:\oracle\redo04a.log',
   'C:\oracle\fast_recovery_area\redo04b.log') SIZE 100M;

-- Adicionar Membro a um Grupo Existente
ALTER DATABASE ADD LOGFILE MEMBER 'C:\oracle\redo01b.log' TO GROUP 1;

-- Forçar Alternância de Log (Log Switch) e Checkpoint
ALTER SYSTEM SWITCH LOGFILE;
ALTER SYSTEM CHECKPOINT;

-- Remover Membro e Grupo de Redo Log
ALTER DATABASE DROP LOGFILE MEMBER 'C:\oracle\redo01b.log';
ALTER DATABASE DROP LOGFILE GROUP 4;

-- Consultar Histórico de Archivelogs Gerados
SELECT name, sequence#, first_time FROM v$archived_log;


--------------------------------------------------------------------------------
-- PARTE 7: CARGA DIRETA E OPERAÇÕES NOLOGGING
--------------------------------------------------------------------------------

ALTER SESSION SET CONTAINER = ORCLPDB;

-- Criar tabela para teste de DML com bypassed Redo (NOLOGGING)
CREATE TABLE livraria.tbnolog AS SELECT * FROM dba_objects WHERE 1=0;

-- Alterar modo da tabela para NOLOGGING
ALTER TABLE livraria.tbnolog NOLOGGING;

-- Inserção de Carga Direta via Hint APPEND
INSERT /*+ APPEND NOLOGGING */ INTO livraria.tbnolog SELECT * FROM dba_objects;
COMMIT;

-- Retornar tabela para modo LOGGING tradicional
ALTER TABLE livraria.tbnolog LOGGING;


--------------------------------------------------------------------------------
-- PARTE 8: LIMPEZA DOS OBJETOS DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

CONNECT / AS SYSDBA;
ALTER SESSION SET CONTAINER = ORCLPDB;

DROP USER arleyribeiro CASCADE;
DROP USER arley_user CASCADE;
DROP USER livraria CASCADE;

DROP TABLESPACE tbs_clientes_loja1 INCLUDING CONTENTS AND DATAFILES;
DROP TABLESPACE tbs_bigfile_lab INCLUDING CONTENTS AND DATAFILES;
DROP TABLESPACE temp_lab01 INCLUDING TEMPORARY DATAFILES;
DROP TABLESPACE undotbs2 INCLUDING CONTENTS AND DATAFILES;