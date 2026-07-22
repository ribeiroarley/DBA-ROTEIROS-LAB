/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-01-instalacao-oracle19c.sql
  Objetivo     : Roteiro prático e comandos SQL de pós-instalação para o 
                 Oracle Database 19c Enterprise Edition no Windows Server.
  Autor        : Arley Ribeiro (DBA Júnior)
*******************************************************************************/

--------------------------------------------------------------------------------
-- 1. GUIA RÁPIDO DE INSTALAÇÃO NO WINDOWS (ORACLE DATABASE 19c)
--------------------------------------------------------------------------------
/*
  PASSO A PASSO NO WINDOWS SERVER:
  1. Criar o diretório do ORACLE_HOME:
     mkdir C:\app\administrator\product\19.0.0\dbhome_1

  2. Extrair o arquivo 'WINDOWS.X64_193000_db_home.zip' DIRETO dentro da pasta acima.

  3. Abrir o Prompt de Comando (cmd) como Administrador e executar:
     cd C:\app\administrator\product\19.0.0\dbhome_1
     setup.exe

  4. Opções do Assistente de Instalação:
     - Opção de Instalação : Create and configure a single instance database
     - Classe de Sistema   : Server Class
     - Edição do Banco     : Enterprise Edition
     - Conta do Windows    : Virtual Account
     - Base Directory      : C:\app\administrator
     - Tipo de Banco       : General Purpose / Transaction Processing
     - Global Database Name: ORCL.localdomain (ou ORCL)
     - SID                 : ORCL
     - Pluggable Database  : ORCLPDB (Manter marcado)
     - Alocação de Memória : 50% a 70% da RAM da VM
     - Character Set       : AL32UTF8 (Unicode) ou WE8MSWIN1252 (Latin-1)
     - Locais de Arquivos  : C:\app\administrator\oradata
*/

--------------------------------------------------------------------------------
-- 2. CONFIGURAÇÃO E TESTE DO LISTENER (PROMPT DO WINDOWS)
--------------------------------------------------------------------------------
/*
  Executar no Prompt de Comando / PowerShell para validar o escutador (Listener):

  -- Verificar status do Listener:
  lsnrctl status

  -- Em caso de erro de HOST (TNS-12545 / TNS-12560), ajustar o listener.ora em:
  -- C:\app\administrator\product\19.0.0\dbhome_1\network\admin\listener.ora

  -- Conteúdo Padrão para listener.ora:
  LISTENER =
    (DESCRIPTION_LIST =
      (DESCRIPTION =
        (ADDRESS = (PROTOCOL = TCP)(HOST = %HOSTNAME%)(PORT = 1521))
        (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
      )
    )

  -- Reiniciar o serviço do Listener:
  lsnrctl stop
  lsnrctl start
*/

--------------------------------------------------------------------------------
-- 3. PRIMEIRO ACESSO E VALIDAÇÕES DO BANCO DE DADOS (SQL*PLUS)
--------------------------------------------------------------------------------

-- Conectar via linha de comando no servidor
-- sqlplus / as sysdba

-- Verificar status do banco de dados e da instância 19c
SELECT 
    instance_name, 
    version, 
    status, 
    database_status,
    to_char(startup_time, 'DD/MM/YYYY HH24:MI:SS') AS startup_time
FROM v$instance;

-- Verificar o nome do banco de dados e se é CDB (Multitenant)
SELECT 
    name AS database_name, 
    cdb, 
    open_mode, 
    log_mode 
FROM v$database;

-- Listar todos os Pluggable Databases (PDBs)
SELECT 
    con_id, 
    name AS pdb_name, 
    open_mode, 
    restricted 
FROM v$pdbs;

--------------------------------------------------------------------------------
-- 4. ABRIR E CONFIGURAR O PDB PARA INICIALIZAÇÃO AUTOMÁTICA
--------------------------------------------------------------------------------

-- Alterar a sessão para trabalhar dentro do PDB padrão
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Abrir o PDB em modo Read Write caso esteja em MOUNTED
ALTER PLUGGABLE DATABASE ORCLPDB OPEN;

-- Retornar ao Container Root (CDB$ROOT)
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- Salvar o estado do PDB para que abra automaticamente no STARTUP do banco
ALTER PLUGGABLE DATABASE ALL SAVE STATE;

--------------------------------------------------------------------------------
-- 5. VERIFICAÇÃO DE SERVIÇOS E CONEXÃO EXTERNA (SQL DEVELOPER)
--------------------------------------------------------------------------------

-- Listar os nomes de serviços ativos para conexão de clientes
SELECT 
    name AS service_name, 
    network_name, 
    pdb 
FROM v$active_services;

/*
  CONFIGURAÇÃO DA CONEXÃO NO SQL DEVELOPER:
  - Usuário      : sys
  - Senha        : <Senha_Definida_na_Instalacao>
  - Funcao / Role: SYSDBA
  - Hostname     : <IP_da_VM> ou <Nome_da_maquina>
  - Porta        : 1521
  - Tipo Conexão : Nome do Serviço (Service Name)
  - Nome Servico : ORCLPDB (para conectar no PDB) ou ORCL (para o CDB)
*/

--------------------------------------------------------------------------------
-- 6. ROTINA DE DESLIGAMENTO E INICIALIZAÇÃO SEGURA (LABORATÓRIO)
--------------------------------------------------------------------------------

-- Procedimento para Desligar o Banco de Dados com segurança antes de fechar a VM
CONNECT / AS SYSDBA;

-- Desligamento Gracioso (Immediate)
SHUTDOWN IMMEDIATE;

-- Procedimento para Iniciar o Banco de Dados
STARTUP;

-- Garantir que todos os PDBs estejam abertos após o startup
ALTER PLUGGABLE DATABASE ALL OPEN;