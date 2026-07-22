/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-15-estrategias-de-backup-restore-e-clone-mysql8.sql
  Objetivo     : Roteiro prático para administração de Backups e Restores no 
                 MySQL 8.x no Windows, cobrindo backups lógicos (mysqldump),
                 gerenciamento e aplicação de Logs Binários (Point-in-Time Recovery),
                 automação via scripts (PowerShell e .bat) e snapshots físicos
                 utilizando o Plugin Clone (mysql_clone.dll).
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / mysqldump, Binary Logs & Clone Plugin
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: VERIFICAÇÃO DE ENGINES E CAMINHOS FÍSICOS DE DADOS
--------------------------------------------------------------------------------

USE arley_cliente2;[cite: 17]

-- Verificar quais tabelas não utilizam a Engine Padrão InnoDB no schema
SELECT table_name, engine, table_type
FROM information_schema.tables
WHERE table_schema = 'arley_cliente2'
  AND engine != 'InnoDB';[cite: 17]

-- Identificar o diretório físico de dados (datadir) gerenciado pela instância
SELECT @@datadir AS diretorio_dados_mysql;[cite: 17]

-- Consultar variáveis de diretórios e logs do sistema
SHOW VARIABLES WHERE Variable_Name LIKE '%dir%';[cite: 17]


--------------------------------------------------------------------------------
-- PARTE 2: COMANDOS DE BACKUP LÓGICO VIA LINHA DE COMANDO (MYSQLDUMP)
--------------------------------------------------------------------------------

/*
  AS INSTRUÇÕES ABAIXO DEVEM SER EXECUTADAS NO PROMPT DE COMANDO (CMD) DO WINDOWS:

  1. Backup de um schema específico sem bloquear tabelas (--single-transaction):
     mysqldump -u arleyribeiro -p arley_cliente2 --single-transaction > C:\mysqlapoio\backups\bk_arley_cliente2.sql[cite: 17]

  2. Backup de múltiplos schemas específicos:
     mysqldump -u arleyribeiro -p --databases arley_cliente2 arley_livraria > C:\mysqlapoio\backups\bk_múltiplos_schemas.sql[cite: 17]

  3. Backup completo da instância (Todos os bancos, Stored Procedures, Functions e Events):
     mysqldump -u arleyribeiro -p --all-databases --single-transaction --routines --events > C:\mysqlapoio\backups\bk_instancia_completa.sql[cite: 17]

  4. Backup de uma única tabela específica:
     mysqldump -u arleyribeiro -p arley_cliente2 customer > C:\mysqlapoio\backups\bk_tabela_customer.sql[cite: 17]

  5. Processo de Restauração Lógica via CMD:
     mysql -u arleyribeiro -p -e "CREATE DATABASE IF NOT EXISTS arley_cliente2;"[cite: 17]
     mysql -u arleyribeiro -p arley_cliente2 < C:\mysqlapoio\backups\bk_arley_cliente2.sql[cite: 17]
*/


--------------------------------------------------------------------------------
-- PARTE 3: GERENCIAMENTO DE LOGS BINÁRIOS (BINLOGS) E PURGE
--------------------------------------------------------------------------------

-- Listar os arquivos de log binário ativos e seus respectivos tamanhos
SHOW BINARY LOGS;[cite: 17]

-- Consultar o log binário atualmente em gravação pela instância
SHOW MASTER STATUS;

-- Verificar o tempo de expiração dos binlogs em segundos (Padrão 8.0: 2592000 seg / 30 dias)
SHOW VARIABLES LIKE 'binlog_expire_logs_seconds';[cite: 17]

-- Forçar a rotação dos arquivos de log binário atuais (Cria novo arquivo binlog)
FLUSH LOGS;[cite: 17]

-- Eliminar logs binários antigos mantendo a partir de um arquivo específico
-- PURGE BINARY LOGS TO 'binlog.000005';[cite: 17]

-- Eliminar logs binários anteriores a uma data/hora específica
-- PURGE BINARY LOGS BEFORE '2026-07-01 00:00:00';[cite: 17]


--------------------------------------------------------------------------------
-- PARTE 4: RESTAURAÇÃO POINT-IN-TIME (PITR) COM MYSQLBINLOG
--------------------------------------------------------------------------------

-- 1. Criar banco de dados de teste para demonstração do Point-in-Time Recovery
DROP DATABASE IF EXISTS arley_dbteste;[cite: 17]
CREATE DATABASE arley_dbteste
CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;[cite: 17]

USE arley_dbteste;[cite: 17]

CREATE TABLE dbteste_t1 (
    id INT NOT NULL AUTO_INCREMENT,
    test_field VARCHAR(30) NOT NULL,
    time_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB;[cite: 17]

INSERT INTO dbteste_t1 (test_field) VALUES ('Carga Inicial 1'), ('Carga Inicial 2');[cite: 17]

SELECT * FROM dbteste_t1;[cite: 17]

/*
  ROTEIRO DE APLICAÇÃO DE RECOVERY INCREMENTAL (CMD):

  1. Executar backup full com rotação de logs:
     mysqldump -u arleyribeiro -p arley_dbteste --single-transaction --flush-logs > C:\mysqlapoio\backups\bk_full_dbteste.sql[cite: 17]

  2. Inserir novos dados após o backup full (gravados no novo arquivo binlog):
     INSERT INTO dbteste_t1 (test_field) VALUES ('Carga Pos-Backup 3');[cite: 17]

  3. Restaurar a base até um horário limite específico usando mysqlbinlog:
     mysqlbinlog --stop-datetime="2026-07-22 18:00:00" C:\ProgramData\MySQL\MySQL Server 8.0\Data\binlog.000002 | mysql -u arleyribeiro -p arley_dbteste[cite: 17]

  4. Ou converter o binlog em arquivo SQL para inspeção e aplicação manual:
     mysqlbinlog C:\ProgramData\MySQL\MySQL Server 8.0\Data\binlog.000002 > C:\mysqlapoio\backups\binlog_processado.sql[cite: 17]
     mysql -u arleyribeiro -p arley_dbteste -e "source C:/mysqlapoio/backups/binlog_processado.sql"[cite: 17]
*/


--------------------------------------------------------------------------------
-- PARTE 5: AUTOMAÇÃO DE BACKUPS VIA POWERSHELL E AGENDADOR DE TAREFAS
--------------------------------------------------------------------------------

/*
  ESTRUTURA DE ARQUIVO DE CONFIGURAÇÃO SEGURA (C:\mysqlapoio\config.cnf):
  [mysqldump]
  user=arleyribeiro
  password=SuaSenhaSegura2026

  [mysqladmin]
  user=arleyribeiro
  password=SuaSenhaSegura2026

  ------------------------------------------------------------------------------
  SCRIPT POWERSHELL DE BACKUP FULL AUTOMATIZADO (C:\mysqlapoio\backupfull_arley.ps1):

  $backuppath = "C:\mysqlapoio\backups\"[cite: 17]
  $config = "C:\mysqlapoio\config.cnf"[cite: 17]
  $database = "arley_cliente2"[cite: 17]
  $errorLog = "C:\mysqlapoio\backups\erros\error_dump.log"[cite: 17]
  $days = 30[cite: 17]
  $date = Get-Date[cite: 17]
  $timestamp = "" + $date.Day + $date.Month + $date.Year + "_" + $date.Hour + $date.Minute[cite: 17]
  $backupfile = $backuppath + $database + "_" + $timestamp + ".sql"[cite: 17]
  $backupzip = $backuppath + $database + "_" + $timestamp + ".zip"[cite: 17]

  mysqldump.exe --defaults-extra-file=$config --log-error=$errorLog --result-file=$backupfile --databases $database --single-transaction --flush-logs --routines --events[cite: 17]
  7z.exe a -tzip $backupzip $backupfile[cite: 17]
  Remove-Item $backupfile[cite: 17]

  $oldbackups = Get-ChildItem -Path $backuppath -Filter *.zip[cite: 17]
  foreach ($file in $oldbackups) {[cite: 17]
      if ($file.CreationTime -lt $date.AddDays(-$days)) {[cite: 17]
          Remove-Item $file.FullName -Confirm:$false[cite: 17]
      }
  }

  ------------------------------------------------------------------------------
  COMANDO PARA CONFIGURAR NO AGENDADOR DE TAREFAS DO WINDOWS (TASK SCHEDULER):
  Program/script : C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe[cite: 17]
  Add arguments  : -ExecutionPolicy RemoteSigned -File "C:\mysqlapoio\backupfull_arley.ps1"[cite: 17]
*/


--------------------------------------------------------------------------------
-- PARTE 6: CONFIGURAÇÃO E USO DO PLUGIN CLONE (SNAPSHOT FÍSICO LOCAL)
--------------------------------------------------------------------------------

/*
  REQUISITOS DE HABILITAÇÃO NO MY.INI (Localizado em C:\ProgramData\MySQL\MySQL Server 8.0\my.ini):
  Adicionar sob a seção [mysqld]:
  plugin-load="mysql_clone.dll"[cite: 17]
  clone-enable-compression[cite: 17]
  clone-max-data-bandwidth=50[cite: 17]
  clone-max-network-bandwidth=100[cite: 17]
*/

-- Validar se o Plugin Clone foi carregado no servidor MySQL 8.x
SELECT plugin_name, plugin_status, plugin_type, plugin_version
FROM information_schema.plugins
WHERE plugin_name = 'clone';

-- Conceder privilégio de administração do Clone ao usuário do laboratório
GRANT BACKUP_ADMIN ON *.* TO 'arleyribeiro'@'localhost';[cite: 17]
FLUSH PRIVILEGES;[cite: 17]

-- Executar clonagem física local da instância diretamente para um diretório de destino
-- Nota: O diretório de destino não deve existir previamente para o comando ser executado.
CLONE LOCAL DATA DIRECTORY = 'C:\\mysqlapoio\\clonebackup';[cite: 17]


--------------------------------------------------------------------------------
-- PARTE 7: AUTOMAÇÃO DE CLONAGEM FÍSICA VIA EVENT SCHEDULER DO MYSQL
--------------------------------------------------------------------------------

USE sys;[cite: 17]

DROP EVENT IF EXISTS ev_agendar_clone_local;[cite: 17]

DELIMITER $$

-- Criar evento recorrente para solicitar o clone da instância a cada 24 horas
CREATE EVENT ev_agendar_clone_local
    ON SCHEDULE EVERY 1 DAY
    STARTS CURRENT_TIMESTAMP + INTERVAL 1 HOUR
    ON COMPLETION PRESERVE
    ENABLE
    COMMENT 'Solicita o snapshot fisico local da instancia via Plugin Clone'
    DO
    BEGIN
        CLONE LOCAL DATA DIRECTORY = 'C:\\mysqlapoio\\clonebackup';[cite: 17]
    END$$

DELIMITER ;

-- Inspecionar status do evento de clone
SHOW EVENTS FROM sys WHERE Name = 'ev_agendar_clone_local';


--------------------------------------------------------------------------------
-- PARTE 8: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)
--------------------------------------------------------------------------------

USE mysql;

-- Remover schemas de teste criados no laboratório
DROP DATABASE IF EXISTS arley_dbteste;[cite: 17]

-- Remover o evento de clone do sistema
DROP EVENT IF EXISTS sys.ev_agendar_clone_local;[cite: 17]

-- Revogar permissão estendida de BACKUP_ADMIN
REVOKE BACKUP_ADMIN ON *.* FROM 'arleyribeiro'@'localhost';
FLUSH PRIVILEGES;