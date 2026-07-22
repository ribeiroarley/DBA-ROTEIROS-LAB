/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-14-backup-recovery-rman-datapump-scheduler-19c.sql
  Objetivo     : Roteiro prático de estratégias de Backup e Recovery no Oracle 19c:
                 Configurações de RMAN, Multiplexação de Control Files, Backups Full e
                 Incrementais (Level 0/1), Data Pump (EXPDP/IMPDP), Recovery PITR, 
                 RMAN Catalog, e Automação de Jobs via DBMS_SCHEDULER.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c Backup and Recovery User's Guide / RMAN Reference
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: CONFIGURAÇÕES INICIAIS DO RMAN E MULTIPLEXAÇÃO DE CONTROL FILES
--------------------------------------------------------------------------------

-- Conectar via RMAN no Target (Prompt do S.O. / CMD):
-- rman target sys/Oracle123

/*
  -- Exibir configurações globais do RMAN:
  SHOW ALL;

  -- Definir tamanho e local da Fast Recovery Area (FRA) no SQL*Plus:
  ALTER SYSTEM SET DB_RECOVERY_FILE_DEST_SIZE = 8G SCOPE=BOTH;
  ALTER SYSTEM SET DB_RECOVERY_FILE_DEST = 'C:\oracleflashbackdatabase' SCOPE=BOTH;

  -- Configurar formato padrão do canal de saída do RMAN:
  CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT 'C:\oraclebackup\backup_%U_%T.bkp';
  CONFIGURE CONTROLFILE AUTOBACKUP ON;
  CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO 'C:\oraclebackup\BKCONTROLFILE_%F';
*/

-- Multiplexação do Control File no SQL*Plus:
CONNECT / AS SYSDBA;

-- 1. Backup Preventivo do SPFILE e Controlfile
-- Executar no RMAN: BACKUP SPFILE; BACKUP CURRENT CONTROLFILE;

-- 2. Atualizar parâmetro do arquivo de controle no SPFILE
ALTER SYSTEM SET control_files = 
    'C:\app\administrator\oradata\ORCL\CONTROL01.CTL',
    'C:\secondcontrolfile\control02.ctl' 
SCOPE=SPFILE;

/*
  -- 3. Reiniciar instância em NOMOUNT no RMAN para restaurar arquivo multiplexado:
  SHUTDOWN IMMEDIATE;
  STARTUP NOMOUNT;
  RESTORE CONTROLFILE FROM AUTOBACKUP;
  ALTER DATABASE MOUNT;
  RECOVER DATABASE;
  ALTER DATABASE OPEN RESETLOGS;
*/


--------------------------------------------------------------------------------
-- PARTE 2: COMANDOS E ESTRATÉGIAS DE BACKUP RMAN (FULL, INCREMENTAL, ARCHIVELOG)
--------------------------------------------------------------------------------

/*
  -- Backup Full de todo o Container Database (CDB) incluindo Archivelogs:
  BACKUP DATABASE PLUS ARCHIVELOG;

  -- Backup com Compressão para Economia de Espaço:
  BACKUP AS COMPRESSED BACKUPSET DATABASE PLUS ARCHIVELOG;

  -- Backup Incremental Level 0 (Base da estratégia incremental):
  BACKUP INCREMENTAL LEVEL=0 DATABASE PLUS ARCHIVELOG;

  -- Backup Incremental Level 1 Cumulativo (Acumula alterações desde o Level 0):
  BACKUP INCREMENTAL LEVEL=1 CUMULATIVE DATABASE PLUS ARCHIVELOG;

  -- Backup Incremental Level 1 Diferencial (Padrão: Apenas alterações desde o último Level 0/1):
  BACKUP INCREMENTAL LEVEL=1 DATABASE PLUS ARCHIVELOG;

  -- Backup exclusivo de Pluggable Database (PDB):
  BACKUP PLUGGABLE DATABASE ORCLPDB;

  -- Backup exclusivo de Archivelogs e purga de arquivos processados:
  RUN {
    SQL 'ALTER SYSTEM ARCHIVE LOG CURRENT';
    BACKUP AS COMPRESSED BACKUPSET 
      FORMAT 'C:\oraclebackup\arch_%d_%s_%p.arc' 
      ARCHIVELOG ALL DELETE INPUT;
    CROSSCHECK ARCHIVELOG ALL;
    DELETE NOPROMPT OBSOLETE;
  }
*/


--------------------------------------------------------------------------------
-- PARTE 3: GERENCIAMENTO DE RETENÇÃO E MANUTENÇÃO DO CATÁLOGO RMAN
--------------------------------------------------------------------------------

/*
  -- Definir política de retenção por Janela de Recuperação (30 dias):
  CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 30 DAYS;

  -- Definir política por Redundância de Cópias:
  CONFIGURE RETENTION POLICY TO REDUNDANCY 2;

  -- Ajustar retenção do Controlfile para casar com a política RMAN (No SQL*Plus):
  ALTER SYSTEM SET control_file_record_keep_time = 30 SCOPE=BOTH;

  -- Verificação de integridade física/lógica e sincronização de disco/catálogo:
  CROSSCHECK BACKUP;
  CROSSCHECK ARCHIVELOG ALL;
  DELETE EXPIRED BACKUP;
  DELETE NOPROMPT OBSOLETE;
  RESTORE DATABASE VALIDATE;
*/


--------------------------------------------------------------------------------
-- PARTE 4: CONFIGURAÇÃO DO RECOVERY CATALOG INDEPENDENTE (RMAN_CAT)
--------------------------------------------------------------------------------

CONNECT / AS SYSDBA;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- 1. Criar Tablespace dedicada ao Catálogo de Recuperação
CREATE TABLESPACE tbs_rman_cat 
    DATAFILE 'C:\oraclebackup\rmancat01.dbf' SIZE 200M 
    AUTOEXTEND ON NEXT 20M MAXSIZE 2000M;

-- 2. Criar Usuário do Catálogo
CREATE USER rman_cat IDENTIFIED BY "oracle123" 
    DEFAULT TABLESPACE tbs_rman_cat 
    TEMPORARY TABLESPACE temp 
    QUOTA UNLIMITED ON tbs_rman_cat;

-- 3. Conceder privilégios do catálogo RMAN
GRANT recovery_catalog_owner TO rman_cat;
GRANT CONNECT, RESOURCE TO rman_cat;

/*
  -- 4. Criar e registrar banco de dados no Catálogo (Linha de comando do S.O.):
  rman catalog rman_cat@ORCLPDB/oracle123
  RMAN> CREATE CATALOG;
  
  rman target sys/Oracle123 catalog rman_cat@ORCLPDB/oracle123
  RMAN> REGISTER DATABASE;
  RMAN> RESYNC CATALOG;
*/


--------------------------------------------------------------------------------
-- PARTE 5: EXPORTAÇÃO E IMPORTAÇÃO DE SCHEMAS E TABELAS (DATA PUMP)
--------------------------------------------------------------------------------

CONNECT / AS SYSDBA;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Criar Objeto de Diretório para gravação dos arquivos .DMP
CREATE OR REPLACE DIRECTORY exp_schema AS 'C:\oraclebackup';

-- Criar usuário dedicado para operações de Backup Data Pump
CREATE USER backup_user IDENTIFIED BY "Arley#1234" 
    DEFAULT TABLESPACE users 
    TEMPORARY TABLESPACE temp 
    QUOTA UNLIMITED ON users;

GRANT CONNECT, CREATE SESSION, RESOURCE TO backup_user;
GRANT READ, WRITE ON DIRECTORY exp_schema TO backup_user;
GRANT DATAPUMP_EXP_FULL_DATABASE, DATAPUMP_IMP_FULL_DATABASE TO backup_user;

/*
  -- Executar Exportação do Schema "arleyribeiro" via Prompt do S.O.:
  expdp backup_user@ORCLPDB/Arley#1234 DIRECTORY=exp_schema DUMPFILE=exp_arley_%T.dmp LOGFILE=exp_arley.log SCHEMAS=arleyribeiro

  -- Executar Importação redirecionando para um novo Schema (Remap Schema):
  impdp backup_user@ORCLPDB/Arley#1234 DIRECTORY=exp_schema DUMPFILE=exp_arley.dmp LOGFILE=imp_arley.log REMAP_SCHEMA=arleyribeiro:arley_novo REMAP_TABLESPACE=USERS:USERS

  -- Executar Exportação de Tabela Específica:
  expdp backup_user@ORCLPDB/Arley#1234 DIRECTORY=exp_schema DUMPFILE=exp_tabela.dmp LOGFILE=exp_tabela.log TABLES=arleyribeiro.minha_tabela2
*/


--------------------------------------------------------------------------------
-- PARTE 6: PROCEDIMENTOS DE RECOVERY E RESTORE (DATABASE, TABLESPACE, DATAFILE)
--------------------------------------------------------------------------------

/*
  -- 1. Restaurar Datafile danificado ou perdido:
  RMAN> SHUTDOWN IMMEDIATE;
  RMAN> STARTUP MOUNT;
  RMAN> RESTORE DATAFILE 7;
  RMAN> RECOVER DATAFILE 7;
  RMAN> ALTER DATABASE OPEN;

  -- 2. Restaurar Tablespace específica:
  SQL> ALTER TABLESPACE users OFFLINE;
  RMAN> RESTORE TABLESPACE users;
  RMAN> RECOVER TABLESPACE users;
  SQL> ALTER TABLESPACE users ONLINE;

  -- 3. Point-In-Time Recovery (PITR) da Database completa:
  RMAN> SHUTDOWN IMMEDIATE;
  RMAN> STARTUP MOUNT;
  RMAN> RUN {
          SET UNTIL TIME "TO_DATE('2026-07-20 14:00:00','YYYY-MM-DD HH24:MI:SS')";
          RESTORE DATABASE;
          RECOVER DATABASE;
          ALTER DATABASE OPEN RESETLOGS;
        }

  -- 4. Recovery de Tabela Específica via RMAN (Sem downtime no banco):
  RMAN> RECOVER TABLE arleyribeiro.minha_tabela2 OF PLUGGABLE DATABASE ORCLPDB 
          UNTIL TIME "TO_DATE('2026-07-20 10:00:00','YYYY-MM-DD HH24:MI:SS')"
          AUXILIARY DESTINATION 'C:\oraclebackup\pitr';
*/


--------------------------------------------------------------------------------
-- PARTE 7: AUTOMAÇÃO DE JOBS VIA DBMS_SCHEDULER
--------------------------------------------------------------------------------

CONNECT / AS SYSDBA;
ALTER SESSION SET CONTAINER = ORCLPDB;

-- Garantir que o Scheduler esteja ativo na instância
BEGIN
    DBMS_SCHEDULER.set_scheduler_attribute('SCHEDULER_DISABLED', 'FALSE');
END;
/

-- Criar Job do Scheduler para chamada de script de backup
BEGIN
    DBMS_SCHEDULER.create_job (
        job_name        => 'JOB_BACKUP_INCREMENTAL_L0',
        job_type        => 'EXECUTABLE',
        job_action      => 'C:\oraclebackup\scriptbackup\backuporcl0.cmd',
        start_date      => TRUNC(SYSDATE) + INTERVAL '0 23:00:00' DAY TO SECOND,
        repeat_interval => 'FREQ=DAILY; BYHOUR=23; BYMINUTE=0; BYSECOND=0',
        enabled         => TRUE,
        auto_drop       => FALSE,
        comments        => 'Execucao diaria do Backup Incremental Level 0 RMAN'
    );
END;
/

-- Alterar Atributos de um Job Existente (Início e Frequência)
BEGIN
    DBMS_SCHEDULER.set_attribute(
        name      => 'JOB_BACKUP_INCREMENTAL_L0',
        attribute => 'start_date',
        value     => SYSTIMESTAMP + INTERVAL '1' MINUTE
    );

    DBMS_SCHEDULER.set_attribute(
        name      => 'JOB_BACKUP_INCREMENTAL_L0',
        attribute => 'repeat_interval',
        value     => 'FREQ=HOURLY; INTERVAL=1'
    );
END;
/

-- Monitoramento e Controle de Jobs
SELECT job_name, status, error#, additional_info 
FROM dba_scheduler_job_run_details 
WHERE job_name = 'JOB_BACKUP_INCREMENTAL_L0';

SELECT owner, job_name, state 
FROM dba_scheduler_jobs 
WHERE job_name = 'JOB_BACKUP_INCREMENTAL_L0';

-- Interromper e Desativar Job
BEGIN
    DBMS_SCHEDULER.stop_job('JOB_BACKUP_INCREMENTAL_L0', FORCE => TRUE);
    DBMS_SCHEDULER.disable('JOB_BACKUP_INCREMENTAL_L0');
END;
/

-- Excluir Job do Scheduler
BEGIN
    DBMS_SCHEDULER.drop_job('JOB_BACKUP_INCREMENTAL_L0', FORCE => TRUE);
END;
/


--------------------------------------------------------------------------------
-- PARTE 8: LIMPEZA DOS OBJETOS DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

CONNECT / AS SYSDBA;
ALTER SESSION SET CONTAINER = ORCLPDB;

DROP USER backup_user CASCADE;
DROP USER rman_cat CASCADE;
DROP TABLESPACE tbs_rman_cat INCLUDING CONTENTS AND DATAFILES;
DROP DIRECTORY exp_schema;