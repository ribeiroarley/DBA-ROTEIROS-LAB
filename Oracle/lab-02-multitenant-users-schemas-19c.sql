/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-02-multitenant-users-schemas-19c.sql
  Objetivo     : Laboratório prático sobre Arquitetura Multitenant (CDB/PDB),
                 gerenciamento de PDBs, Usuários Comuns/Locais e Privilégios no 
                 Oracle Database 19c.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c Administrator's Guide
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: NAVEGAÇÃO E INSPEÇÃO DO CONTAINER ROOT (CDB$ROOT)
--------------------------------------------------------------------------------

-- Conectar como superusuário no SQL*Plus
-- sqlplus / as sysdba

-- Verificar o container atual da sessão
SHOW con_name;

-- Consultar informações detalhadas do Container Root
SELECT con_id, dbid, name, open_mode 
FROM v$containers 
WHERE con_id = 1;

-- Listar todos os Pluggable Databases (PDBs) registrados
SELECT con_id, name, open_mode, restricted 
FROM v$pdbs;


--------------------------------------------------------------------------------
-- PARTE 2: GESTÃO DE USUÁRIOS COMUNS (COMMON USERS) NO CDB
--------------------------------------------------------------------------------

-- Usuários comuns devem obrigatoriamente possuir o prefixo 'C##' ou 'c##'
CREATE USER c##commonuser IDENTIFIED BY "commonuser123" CONTAINER=ALL;

-- Conceder permissão de conexão global
GRANT CONNECT TO c##commonuser CONTAINER=ALL;

-- Conceder privilégio de criar tabelas apenas no container atual (CDB$ROOT)
GRANT CREATE TABLE TO c##commonuser CONTAINER=CURRENT;

-- Teste de conexão com o usuário comum
CONNECT c##commonuser/commonuser123;
SHOW con_name;
SHOW user;

-- Teste de criação de objeto e limpeza no CDB
CREATE TABLE t1 (id NUMBER);
DROP TABLE t1;

-- Revogando privilégio via SYS
CONNECT / AS SYSDBA;
REVOKE CREATE TABLE FROM c##commonuser CONTAINER=CURRENT;


--------------------------------------------------------------------------------
-- PARTE 3: GESTÃO DE USUÁRIOS LOCAIS E PDBS
--------------------------------------------------------------------------------

-- Alterar a sessão para o PDB padrão da instalação (ORCLPDB)
ALTER SESSION SET CONTAINER = ORCLPDB;
SHOW con_name;

-- Garantir que o PDB esteja aberto em modo READ WRITE
ALTER PLUGGABLE DATABASE ORCLPDB OPEN;

-- Criar usuário local (não deve utilizar o prefixo c##)
CREATE USER arleyribeiro IDENTIFIED BY "arley123" CONTAINER=CURRENT;
GRANT CONNECT TO arleyribeiro CONTAINER=CURRENT;

CREATE USER arleyribeiro2 IDENTIFIED BY "arley123" CONTAINER=CURRENT;
GRANT CONNECT TO arleyribeiro2 CONTAINER=CURRENT;

-- Retornar ao CDB Root
ALTER SESSION SET CONTAINER = CDB$ROOT;
SHOW con_name;


--------------------------------------------------------------------------------
-- PARTE 4: CRIAÇÃO, CLONAGEM E DROP DE PLUGGABLE DATABASES (PDBS)
--------------------------------------------------------------------------------

-- Definir o destino padrão de armazenamento para a criação automática de PDBs
-- Substitua 'C:\app\administrator\oradata\newpdbs' pelo diretório do seu ambiente
ALTER SYSTEM SET db_create_file_dest='C:\app\administrator\oradata\newpdbs' SCOPE=BOTH;

-- Validar a alteração do parâmetro
SHOW PARAMETER db_create_file_dest;

-- Criar PDB1 com cota de armazenamento
CREATE PLUGGABLE DATABASE pdb1 
  ADMIN USER admin IDENTIFIED BY "benvindo123" 
  STORAGE (MAXSIZE 2G);

-- Criar PDB2 com cota de armazenamento
CREATE PLUGGABLE DATABASE pdb2 
  ADMIN USER admin IDENTIFIED BY "benvindo123" 
  STORAGE (MAXSIZE 1G);

-- Clonar um PDB existente (copiar PDB2 para PDB3)
ALTER PLUGGABLE DATABASE pdb2 OPEN READ ONLY;
CREATE PLUGGABLE DATABASE pdb3 FROM pdb2;
ALTER PLUGGABLE DATABASE pdb2 CLOSE;
ALTER PLUGGABLE DATABASE pdb2 OPEN READ WRITE;

-- Listar os PDBs criados e seus estados
SELECT con_id, name, open_mode FROM v$pdbs;

-- Abrir PDBs recém-criados
ALTER PLUGGABLE DATABASE pdb1 OPEN;
ALTER PLUGGABLE DATABASE pdb3 OPEN;

-- Excluir PDB2 removendo os arquivos físicos do disco
ALTER PLUGGABLE DATABASE pdb2 CLOSE;
DROP PLUGGABLE DATABASE pdb2 INCLUDING DATAFILES;

-- Excluir PDB1 e PDB3
ALTER PLUGGABLE DATABASE pdb1 CLOSE;
DROP PLUGGABLE DATABASE pdb1 INCLUDING DATAFILES;

ALTER PLUGGABLE DATABASE pdb3 CLOSE;
DROP PLUGGABLE DATABASE pdb3 INCLUDING DATAFILES;

-- Confirmar limpeza dos PDBs
SELECT name, open_mode FROM v$pdbs;


--------------------------------------------------------------------------------
-- PARTE 5: CONCEITO DE USER / SCHEMA E CONCESSÃO DE PRIVILÉGIOS (ORCLPDB)
--------------------------------------------------------------------------------

-- Alternar para o PDB de trabalho
ALTER SESSION SET CONTAINER = ORCLPDB;
ALTER PLUGGABLE DATABASE ORCLPDB OPEN;

-- Criar Schema/Usuário 'FINANCE' que atuará como dono dos objetos
CREATE USER finance IDENTIFIED BY "fin123" CONTAINER=CURRENT;

-- Conceder quota na tablespace USERS para permitir gravação de dados
ALTER USER finance QUOTA UNLIMITED ON USERS;

-- Conceder privilégios básicos
GRANT CONNECT, RESOURCE TO finance CONTAINER=CURRENT;

-- Criar Usuário 'ARLEYRIBEIRO' que consumirá os objetos do Schema FINANCE
CREATE USER arleyribeiro IDENTIFIED BY "a123" CONTAINER=CURRENT;
GRANT CONNECT TO arleyribeiro CONTAINER=CURRENT;

-- Conectar como FINANCE e criar a estrutura da tabela
CONNECT finance/fin123@//localhost:1521/ORCLPDB;

CREATE TABLE cliente (
    matricula NUMBER(10) PRIMARY KEY,
    nome      VARCHAR2(100) NOT NULL
);

-- Conceder privilégios granulares na tabela CLIENTE para o usuário ARLEYRIBEIRO
GRANT SELECT, INSERT, UPDATE, DELETE ON finance.cliente TO arleyribeiro;

-- Conectar como ARLEYRIBEIRO e manipular os dados do Schema FINANCE
CONNECT arleyribeiro/a123@//localhost:1521/ORCLPDB;

-- Manipulação DML
SELECT * FROM finance.cliente;
INSERT INTO finance.cliente (matricula, nome) VALUES (1, 'Arley Ribeiro');
UPDATE finance.cliente SET nome = 'Arley Ribeiro Alterado' WHERE matricula = 1;
DELETE FROM finance.cliente WHERE matricula = 1;
COMMIT;


--------------------------------------------------------------------------------
-- PARTE 6: GERENCIAMENTO DE PRIVILÉGIOS DE SISTEMA E REVOGAÇÃO
--------------------------------------------------------------------------------

-- Conectar como SYSDBA para ajustar privilégios do sistema
CONNECT / AS SYSDBA;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Revogar permissões na tabela
CONNECT finance/fin123@//localhost:1521/ORCLPDB;
REVOKE ALL ON finance.cliente FROM arleyribeiro;

-- Exemplo de Concessão de Privilégio Global de Leitura (Usar com cautela em produção)
CONNECT / AS SYSDBA;
ALTER SESSION SET CONTAINER = ORCLPDB;
GRANT SELECT ANY TABLE TO arleyribeiro;

-- Testar acesso global
CONNECT arleyribeiro/a123@//localhost:1521/ORCLPDB;
SELECT * FROM finance.cliente;

-- Revogar Privilégio Global de Leitura
CONNECT / AS SYSDBA;
ALTER SESSION SET CONTAINER = ORCLPDB;
REVOKE SELECT ANY TABLE FROM arleyribeiro;


--------------------------------------------------------------------------------
-- PARTE 7: REMOÇÃO DE SCHEMAS E OBJETOS (CLEANUP)
--------------------------------------------------------------------------------

CONNECT / AS SYSDBA;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Excluir usuário e todos os seus objetos (CASCADE)
DROP USER finance CASCADE;
DROP USER arleyribeiro CASCADE;
DROP USER arleyribeiro2 CASCADE;

-- Salvar o estado dos PDBs para que reabram automaticamente no STARTUP do CDB
ALTER PLUGGABLE DATABASE ALL SAVE STATE;