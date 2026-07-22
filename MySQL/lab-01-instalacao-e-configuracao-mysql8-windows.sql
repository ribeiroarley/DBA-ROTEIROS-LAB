/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-01-instalacao-e-configuracao-mysql8-windows.sql
  Objetivo     : Guia de instalação, configuração pós-instalação, criação de 
                 usuários com privilégios administrativos e verificação de 
                 parâmetros globais no MySQL 8.x no Windows.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / MySQL Installer for Windows
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: NOTAS DE INSTALAÇÃO DO MYSQL SERVER E MYSQL WORKBENCH (WINDOWS)
--------------------------------------------------------------------------------

/*
  REQUISITOS DE DOWNLOAD E INSTALAÇÃO:
  1. MySQL Installer Community (Server, Workbench, Shell e Router em pacote único):
     - Download Oficial: https://dev.mysql.com/downloads/installer/
     - Pacote Recomendado: mysql-installer-community-8.x.x.msi

  2. Passos do Assistente de Instalação (MySQL Installer):
     - Setup Type: Custom (Permite selecionar apenas Server 8.0 e Workbench 8.0)
     - Type and Networking: Standalone MySQL Server / Dedicated Computer
     - Port: 3306 (TCP/IP) | X Protocol Port: 33060
     - Authentication Method: Use Strong Password Encryption for Authentication (caching_sha2_password)
     - Windows Service: Configurar nome do serviço como "MySQL80" (Startup ao iniciar o Windows)
*/


--------------------------------------------------------------------------------
-- PARTE 2: CRIAÇÃO E CONFIGURAÇÃO DO USUÁRIO ADMINISTRADOR DO LABORATÓRIO
--------------------------------------------------------------------------------

-- Conectar ao MySQL Server como 'root' via MySQL Workbench ou Command Line Client
-- Executar comandos de validação e criação do usuário do DBA

-- Verificar o método de autenticação padrão e usuários existentes
SELECT user, host, plugin, account_locked 
FROM mysql.user;

-- Criar o usuário 'arleyribeiro' com acesso a partir do localhost (Segurança)
CREATE USER 'arleyribeiro'@'localhost' 
IDENTIFIED WITH caching_sha2_password BY 'Arley@2026!MySQL';

-- Conceder privilégios administrativos globais (Equivalente a DBA no MySQL 8.0)
GRANT ALL PRIVILEGES ON *.* TO 'arleyribeiro'@'localhost' WITH GRANT OPTION;

-- Criar o usuário 'arley' com permissão de conexão remota ou via rede local
CREATE USER 'arley'@'%' 
IDENTIFIED WITH caching_sha2_password BY 'Arley@2026!Remote';

-- Conceder permissões de administração e gerenciamento ao usuário remoto
GRANT ALL PRIVILEGES ON *.* TO 'arley'@'%' WITH GRANT OPTION;

-- Aplicar e atualizar a tabela de privilégios na memória
FLUSH PRIVILEGES;


--------------------------------------------------------------------------------
-- PARTE 3: VERIFICAÇÃO DE PARÂMETROS GLOBAIS E ENGINE PADRÃO
--------------------------------------------------------------------------------

-- Alternar sessão para o usuário 'arleyribeiro'

-- Verificar a versão exata do banco de dados MySQL em execução
SELECT VERSION(), @@version_comment, @@version_compile_os;

-- Confirmar a Engine de armazenamento padrão (Deve ser InnoDB)
SHOW VARIABLES LIKE 'default_storage_engine';

-- Verificar o Charset e Collation do servidor (Padrão MySQL 8.0: utf8mb4 / utf8mb4_0900_ai_ci)
SHOW VARIABLES LIKE 'character_set_server';
SHOW VARIABLES LIKE 'collation_server';

-- Checar o modo SQL ativo (Strict Mode e boas práticas ANSI)
SELECT @@sql_mode;

-- Verificar limite de conexões simultâneas e tempo de timeout
SHOW VARIABLES LIKE 'max_connections';
SHOW VARIABLES LIKE 'wait_timeout';


--------------------------------------------------------------------------------
-- PARTE 4: CRIAÇÃO DO DATABASE DE LABORATÓRIO E APLICABILIDADE DE CHARSET
--------------------------------------------------------------------------------

-- Criar o banco de dados principal do laboratório garantindo padrões modernos
CREATE DATABASE IF NOT EXISTS dba_education_lab
CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;

-- Selecionar o banco de dados criado
USE dba_education_lab;

-- Validar as propriedades do schema atual
SELECT @@character_set_database, @@collation_database;


--------------------------------------------------------------------------------
-- PARTE 5: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

/*
-- Descomentar para remover o banco de dados e usuários de teste criados:

USE mysql;
DROP DATABASE IF EXISTS dba_education_lab;
DROP USER IF EXISTS 'arleyribeiro'@'localhost';
DROP USER IF EXISTS 'arley'@'%';
FLUSH PRIVILEGES;
*/