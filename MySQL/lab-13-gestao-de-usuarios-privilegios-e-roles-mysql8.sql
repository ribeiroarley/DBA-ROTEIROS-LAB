/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-13-gestao-de-usuarios-privilegios-e-roles-mysql8.sql
  Objetivo     : Roteiro prático para gestão de segurança no MySQL 8.x, abordando
                 criação de usuários com escopo de host, concessão/revogação de 
                 privilégios de dados/objetos/colunas, criação e atribuição de 
                 Roles, controle de ativador SET DEFAULT ROLE e auditoria das 
                 tabelas de dicionário de dados (mysql.user, mysql.db).
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Security, Account Management & Roles
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: SELEÇÃO DO SCHEMA E INSPEÇÃO DE USUÁRIOS E DICIONÁRIO
--------------------------------------------------------------------------------

USE arley_cliente2;

-- Inspecionar usuários cadastrados no dicionário do MySQL
SELECT user, host, plugin, account_locked 
FROM mysql.user;

-- Consultar privilégios globais e de schema registrados
SELECT user, host, db 
FROM mysql.db;


--------------------------------------------------------------------------------
-- PARTE 2: CRIAÇÃO DE USUÁRIOS E ATRIBUIÇÃO DE PRIVILEGIOS DIRETOS
--------------------------------------------------------------------------------

-- Criar usuário com restrição de escopo local (localhost)
CREATE USER IF NOT EXISTS 'arley_local'@'localhost' 
IDENTIFIED WITH caching_sha2_password BY 'Arley@Local2026!';

-- Criar usuário com permissão de acesso remoto (%)
CREATE USER IF NOT EXISTS 'arley'@'%' 
IDENTIFIED WITH caching_sha2_password BY 'Arley@Remote2026!';

-- Atribuir privilégios DML e EXECUTE no schema do laboratório
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE 
ON arley_cliente2.* 
TO 'arley_local'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE 
ON arley_cliente2.* 
TO 'arley'@'%';

-- Inspecionar privilégios concedidos aos usuários
SHOW GRANTS FOR 'arley_local'@'localhost';
SHOW GRANTS FOR 'arley'@'%';


--------------------------------------------------------------------------------
-- PARTE 3: PRIVILÉGIOS EM NÍVEL DE TABELA E COLUNA COM WITH GRANT OPTION
--------------------------------------------------------------------------------

-- Criar usuário para acesso restrito a colunas de auditoria/leitura
CREATE USER IF NOT EXISTS 'arley_analista'@'127.0.0.1' 
IDENTIFIED WITH caching_sha2_password BY 'Arley@Analista2026!';

-- Conceder permissão seletiva de SELECT e UPDATE apenas em colunas específicas
GRANT SELECT (id, firstname, lastname), UPDATE (id, firstname, lastname)
ON arley_cliente2.customer
TO 'arley_analista'@'127.0.0.1' WITH GRANT OPTION;

-- Visualizar privilégios granulares
SHOW GRANTS FOR 'arley_analista'@'127.0.0.1';


--------------------------------------------------------------------------------
-- PARTE 4: REVOGAÇÃO DE PRIVILÉGIOS (REVOKE)
--------------------------------------------------------------------------------

-- Revogar permissões seletivas de colunas
REVOKE SELECT (id, firstname, lastname), UPDATE (id, firstname, lastname)
ON arley_cliente2.customer
FROM 'arley_analista'@'127.0.0.1';

-- Revogar especificamente a opção de replicação de privilégios (GRANT OPTION)
REVOKE GRANT OPTION 
ON arley_cliente2.customer
FROM 'arley_analista'@'127.0.0.1';

-- Confirmar remoção total dos privilégios
SHOW GRANTS FOR 'arley_analista'@'127.0.0.1';


--------------------------------------------------------------------------------
-- PARTE 5: GESTÃO DE PAPÉIS (ROLES) E ATIVAÇÃO DEFAULT (SET DEFAULT ROLE)
--------------------------------------------------------------------------------

-- Remover papéis (Roles) se já existirem
DROP ROLE IF EXISTS 'role_app_dev', 'role_app_read', 'role_app_write';

-- Criar novos papéis no MySQL 8.x
CREATE ROLE 'role_app_dev', 'role_app_read', 'role_app_write';

-- Atribuir permissões específicas para cada papel
GRANT ALL PRIVILEGES ON arley_cliente2.* TO 'role_app_dev';
GRANT SELECT ON arley_cliente2.* TO 'role_app_read';
GRANT INSERT, UPDATE, DELETE ON arley_cliente2.* TO 'role_app_write';

-- Criar contas de serviço/aplicação para vinculação com Roles
CREATE USER IF NOT EXISTS 'arley_dev'@'localhost' IDENTIFIED BY 'Dev@2026!Pass';
CREATE USER IF NOT EXISTS 'arley_read1'@'localhost' IDENTIFIED BY 'Read1@2026!Pass';
CREATE USER IF NOT EXISTS 'arley_rw1'@'localhost' IDENTIFIED BY 'Rw1@2026!Pass';

-- Vincular papéis aos usuários
GRANT 'role_app_dev' TO 'arley_dev'@'localhost';
GRANT 'role_app_read' TO 'arley_read1'@'localhost';
GRANT 'role_app_read', 'role_app_write' TO 'arley_rw1'@'localhost';

-- Verificar permissões atribuídas a um papel
SHOW GRANTS FOR 'role_app_read';

-- Ativar os papéis automaticamente no momento da conexão (Padrão MySQL 8.0+)
SET DEFAULT ROLE ALL TO
  'arley_dev'@'localhost',
  'arley_read1'@'localhost',
  'arley_rw1'@'localhost';

-- Validar a atribuição ativada para o desenvolvedor
SHOW GRANTS FOR 'arley_dev'@'localhost' USING 'role_app_dev';


--------------------------------------------------------------------------------
-- PARTE 6: DESVINCULAÇÃO DE ROLES E ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

-- Revogar uma Role de um usuário específico
REVOKE 'role_app_read' FROM 'arley_rw1'@'localhost';

-- Remover Roles criadas
DROP ROLE IF EXISTS 'role_app_dev', 'role_app_read', 'role_app_write';

-- Remover Usuários criados no laboratório
DROP USER IF EXISTS 'arley_local'@'localhost';
DROP USER IF EXISTS 'arley'@'%';
DROP USER IF EXISTS 'arley_analista'@'127.0.0.1';
DROP USER IF EXISTS 'arley_dev'@'localhost';
DROP USER IF EXISTS 'arley_read1'@'localhost';
DROP USER IF EXISTS 'arley_rw1'@'localhost';

-- Recarregar e consolidar tabelas de privilégios na memória
FLUSH PRIVILEGES;