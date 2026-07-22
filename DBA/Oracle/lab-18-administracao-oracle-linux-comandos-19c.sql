/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-18-administracao-oracle-linux-comandos-19c.sql
  Objetivo     : Guia de referência técnica e operacional no Oracle Linux (Red Hat)
                 voltado para a rotina de um DBA Oracle 19c (Navegação, Permissões,
                 Gestão de Usuários, Processos, Monitoramento e Integração com CDB/PDB).
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Linux 9 System Administration Guide / Database Installation Guide
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: NAVEGAÇÃO, DIRETÓRIOS E MANIPULAÇÃO DE ARQUIVOS (S.O. LINUX)
--------------------------------------------------------------------------------

/*
  -- Exibir o diretório atual de trabalho:
  pwd

  -- Navegação entre a hierarquia de diretórios:
  cd /
  cd /home
  cd /lib/modules
  cd ..
  cd ~

  -- Listagem detalhada e exibição de arquivos ocultos:
  ls
  ls -l          -- Permissões, links, owner, grupo, tamanho e data
  ls -A          -- Exibir arquivos ocultos (iniciados com ponto)

  -- Histórico de comandos do terminal:
  history

  -- Criação e remoção de diretórios:
  mkdir /home/dadossql
  mkdir /home/dir1 /home/dir2
  rmdir /home/dir1
  rm -rf /home/dadossql   -- Remoção recursiva forçada (Usar com cautela!)

  -- Criação, edição e leitura de arquivos texto:
  touch /home/dadossql/script.sql
  nano /home/dadossql/script.sql
  vi /home/dadossql/script2.sql
  cat /home/dadossql/script.sql
  rm /home/dadossql/script.sql
*/


--------------------------------------------------------------------------------
-- PARTE 2: GERENCIAMENTO DE USUÁRIOS, GRUPOS E PROPRIEDADE (CHOWN / CHMOD)
--------------------------------------------------------------------------------

/*
  -- Estrutura de permissões (ls -l):
  -- -rw-rw-r--. 1 root root 0 May 14 17:08 texto.txt
  -- |  |  |  |     |    |
  -- |  |  |  |     |    +--> Grupo proprietário
  -- |  |  |  |     +-------> Usuário proprietário
  -- |  |  |  +-------------> Permissão Outros (Others: r--)
  -- |  |  +----------------> Permissão Grupo (Group: rw-)
  -- |  +-------------------> Permissão Dono (User: rw-)
  -- +----------------------> Tipo (- = arquivo, d = diretório)

  -- Criar usuário do sistema e associar ao grupo root / oinstall:
  sudo useradd arleyribeiro
  sudo passwd arleyribeiro
  sudo usermod -aG root arleyribeiro
  groups arleyribeiro

  -- Alteração de propriedade (chown) para o usuário arleyribeiro:
  touch /home/texto.txt
  chown arleyribeiro /home/texto.txt
  chown arleyribeiro:root /home/texto.txt
  chown -R arleyribeiro:oinstall /u01/app/oracle

  -- Alteração de permissões via modo octal (chmod):
  -- 7 = rwx (Ler, Gravar, Executar), 6 = rw (Ler, Gravar), 4 = r (Apenas Ler)
  chmod 755 /u01/app/oracle
  chmod 664 /home/texto.txt
*/


--------------------------------------------------------------------------------
-- PARTE 3: BUSCA DE ARQUIVOS, FILTROS E MONITORAMENTO EM TEMPO REAL
--------------------------------------------------------------------------------

/*
  -- Localizar arquivos de banco de dados ou logs no sistema de arquivos:
  find /home/ -name "log*"
  find /u01/app/oracle -name "alert_*.log"

  -- Pesquisar padrões dentro de arquivos texto (grep):
  grep -i "ORA-" /u01/app/oracle/diag/rdbms/orcl/orcl/trace/alert_orcl.log
  grep -r "GRANT" /home/dadossql

  -- Executar busca combinada (find + grep):
  find /home -type f -name "*.sql" -exec grep -i "CREATE TABLE" {} \;

  -- Acompanhamento em tempo real do arquivo Alert Log do Oracle:
  tail -f /u01/app/oracle/diag/rdbms/orcl/orcl/trace/alert_orcl.log

  -- Criar atalho permanente (alias) para o Alert Log:
  alias alert="tail -f /u01/app/oracle/diag/rdbms/orcl/orcl/trace/alert_orcl.log"
*/


--------------------------------------------------------------------------------
-- PARTE 4: MONITORAMENTO DE RECURSOS DO SISTEMA OPERACIONAL (CPU/RAM/DISCO)
--------------------------------------------------------------------------------

/*
  -- Verificar espaço em disco e pontos de montagem:
  df -h

  -- Monitorar utilização de memória RAM e Swap (em MB):
  free -m

  -- Exibir processos em execução e consumo de CPU/RAM em tempo real:
  top

  -- Localizar o identificador de processo (PID) e finalizar de forma forçada:
  pgrep -u oracle dbase
  ps -ef | grep pmon
  kill -9 <PID>
*/


--------------------------------------------------------------------------------
-- PARTE 5: INTEGRAÇÃO LINUX X ORACLE DATABASE 19c (SQL*PLUS)
--------------------------------------------------------------------------------

-- Conectar como SYSDBA na instância Oracle 19c
CONNECT / AS SYSDBA;

-- Consultar o Hostname e o status do sistema de arquivos do servidor
SELECT 
    host_name, 
    instance_name, 
    version, 
    status, 
    to_char(startup_time, 'DD/MM/YYYY HH24:MI:SS') AS startup_time
FROM v$instance;

-- Mapear os processos de segundo plano (Background Processes) no Linux
SELECT 
    spid AS pid_linux, 
    pid AS pid_oracle, 
    program, 
    background 
FROM v$process 
WHERE background = 1 
ORDER BY program;

-- Consultar os caminhos físicos dos Datafiles registrados no dicionário
SELECT 
    file_id, 
    tablespace_name, 
    file_name 
FROM dba_data_files;

-- Alternar para o PDB e validar estado de abertura
ALTER SESSION SET CONTAINER = ORCLPDB;
ALTER PLUGGABLE DATABASE ORCLPDB OPEN;

SELECT 
    con_id, 
    name AS pdb_name, 
    open_mode 
FROM v$pdbs;