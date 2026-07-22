/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-19-instalacao-oracle19c-linux-e-configuracoes.sql
  Objetivo     : Roteiro prático para instalação e pós-instalação do Oracle Database 19c
                 no Oracle Linux (Red Hat). Cobre pré-requisitos (RPM Preinstall),
                 criação de diretórios/grupos, configuração de variáveis de ambiente,
                 gerenciamento de Swap, Listener, inicialização via Systemd, RMAN e EM Express.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database Installation Guide 19c for Linux / Administrator's Guide
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: PRÉ-REQUISITOS DO S.O., GRUPOS E ESTRUTURA DE DIRETÓRIOS (ROOT)
--------------------------------------------------------------------------------

/*
  -- 1. Instalar o pacote de pré-instalação do Oracle Database 19c (Cria usuário oracle e grupos):
  sudo yum update -y
  sudo dnf install -y oracle-database-preinstall-19c.x86_64

  -- 2. Validar/Criar grupos de segurança do sistema operacional:
  sudo groupadd -g 54321 oinstall
  sudo groupadd -g 54322 dba
  sudo groupadd -g 54323 oper
  sudo groupadd -g 54324 backupdba
  sudo groupadd -g 54325 dgdba
  sudo groupadd -g 54326 kmdba
  sudo groupadd -g 54327 racdba

  -- 3. Definir senha para o usuário do S.O. 'oracle':
  sudo passwd oracle

  -- 4. Criar a estrutura de diretórios para o ORACLE_HOME e ORACLE_BASE:
  sudo mkdir -p /app/oracle/product/19.0.0/dbhome_1
  sudo mkdir -p /app/oraInventory
  sudo chown -R oracle:oinstall /app
  sudo chmod -R 775 /app

  -- 5. Configurar resolução estática no /etc/hosts:
  -- Adicionar no arquivo /etc/hosts:
  -- 192.168.1.188    cursooracle cursooracle.localdomain
*/


--------------------------------------------------------------------------------
-- PARTE 2: GERENCIAMENTO E EXPANSÃO DO ESPAÇO DE SWAP (ROOT)
--------------------------------------------------------------------------------

/*
  -- Verificar o tamanho atual do Swap:
  free -h
  swapon --show

  -- Criar arquivo de Swap adicional de 11 GB utilizando o utilitário dd:
  sudo dd if=/dev/zero of=/root/meuswap bs=1M count=11264
  sudo chmod 600 /root/meuswap
  sudo mkswap /root/meuswap
  sudo swapon /root/meuswap

  -- Tornar o novo arquivo de Swap permanente após reboots (Editar /etc/fstab):
  -- Adicionar: /root/meuswap swap swap defaults 0 0
  sudo systemctl daemon-reload
*/


--------------------------------------------------------------------------------
-- PARTE 3: VARIÁVEIS DE AMBIENTE DO SISTEMA (ORACLE / PROFILE)
--------------------------------------------------------------------------------

/*
  -- Configurar variáveis globais em /etc/profile.d/oracle.sh (Executar como Root):
  sudo nano /etc/profile.d/oracle.sh

  -- Conteúdo do arquivo oracle.sh:
  export ORACLE_BASE=/app/oracle
  export ORACLE_HOME=/app/oracle/product/19.0.0/dbhome_1
  export ORACLE_SID=orcl
  export ORACLE_UNQNAME=orcl
  export PATH=$ORACLE_HOME/bin:$PATH

  -- Aplicar permissão de execução:
  sudo chmod +x /etc/profile.d/oracle.sh
*/


--------------------------------------------------------------------------------
-- PARTE 4: EXTRAÇÃO DOS BINÁRIOS E EXECUÇÃO DO INSTALADOR (USUÁRIO ORACLE)
--------------------------------------------------------------------------------

/*
  -- Conectar como usuário oracle e descompactar o instalador direto no ORACLE_HOME:
  cd /app/oracle/product/19.0.0/dbhome_1
  unzip -q LINUX.X64_193000_db_home.zip

  -- Executar o assistente de instalação (Modo Gráfico via MobaXterm ou Silent):
  ./runInstaller

  -- Passos do Assistente:
  -- 1. Opção: Set Up Software Only
  -- 2. Tipo: Single Instance Database Installation
  -- 3. Edição: Enterprise Edition
  -- 4. Localização: /app/oracle
  -- 5. Inventário: /app/oraInventory
  -- 6. Execução Automática de Scripts de Root: Fornecer credencial do Root

  -- Executar scripts de root manualmente se solicitado:
  -- /app/oraInventory/orainstRoot.sh
  -- /app/oracle/product/19.0.0/dbhome_1/root.sh
*/


--------------------------------------------------------------------------------
-- PARTE 5: CONFIGURAÇÃO DO LISTENER E CRIAÇÃO DA BASE VIA DBCA
--------------------------------------------------------------------------------

/*
  -- 1. Configurar o Listener via assistente 'netca' (Usuário Oracle):
  netca /silent /responseFile /app/oracle/product/19.0.0/dbhome_1/assistants/netca/netca.rsp

  -- Validar e iniciar o Listener:
  lsnrctl status
  lsnrctl start

  -- 2. Criar a base de dados Container (CDB) e Pluggable (PDB) via 'dbca':
  dbca -silent -createDatabase \
    -templateName General_Purpose.dbc \
    -gdbName orcl \
    -sid orcl \
    -createAsContainerDatabase true \
    -numberOfPDBs 1 \
    -pdbName orclpdb1linux \
    -emConfiguration LOCAL \
    -storageType FS \
    -datafileDestination /app/oracle/oradata \
    -action createDatabase \
    -useConfigurationArchive false
*/


--------------------------------------------------------------------------------
-- PARTE 6: AUTOMAÇÃO DE INICIALIZAÇÃO VIA SYSTEMD E ORATAB (ROOT)
--------------------------------------------------------------------------------

/*
  -- 1. Atualizar o arquivo /etc/oratab para permitir inicialização automática:
  -- Alterar a linha da instância de 'N' para 'Y':
  -- orcl:/app/oracle/product/19.0.0/dbhome_1:Y

  -- 2. Criar o script de inicialização /app/oracle/scripts/start_oracle.sh:
  #!/bin/bash
  export ORACLE_HOME=/app/oracle/product/19.0.0/dbhome_1
  export ORACLE_SID=orcl
  export PATH=$ORACLE_HOME/bin:$PATH

  $ORACLE_HOME/bin/dbstart $ORACLE_HOME
  $ORACLE_HOME/bin/lsnrctl start
  echo "ALTER PLUGGABLE DATABASE ALL OPEN;" | $ORACLE_HOME/bin/sqlplus -s / as sysdba

  -- Dar permissão de execução ao script:
  chmod +x /app/oracle/scripts/start_oracle.sh

  -- 3. Criar a unidade de serviço Systemd em /etc/systemd/system/oracle-db.service:
  [Unit]
  Description=Oracle Database and Listener Service
  After=network.target

  [Service]
  ExecStart=/bin/bash /app/oracle/scripts/start_oracle.sh
  ExecStop=/bin/bash -c '/app/oracle/product/19.0.0/dbhome_1/bin/lsnrctl stop && /app/oracle/product/19.0.0/dbhome_1/bin/dbshut /app/oracle/product/19.0.0/dbhome_1'
  User=oracle
  Group=oinstall
  Restart=always
  RestartSec=3
  Type=forking
  Environment="ORACLE_HOME=/app/oracle/product/19.0.0/dbhome_1"
  Environment="ORACLE_SID=orcl"

  [Install]
  WantedBy=multi-user.target

  -- Recarregar Systemd e habilitar o serviço no boot:
  sudo systemctl daemon-reload
  sudo systemctl enable oracle-db
  sudo systemctl start oracle-db
*/


--------------------------------------------------------------------------------
-- PARTE 7: COMANDOS SQL DE VALIDAÇÃO, ABERTURA E CONFIGURAÇÃO DO PDB
--------------------------------------------------------------------------------

-- Conectar como SYSDBA via SQL*Plus
CONNECT / AS SYSDBA;

-- Checar o estado da instância e se é Container Database
SELECT name, cdb, open_mode FROM v$database;

-- Listar os Pluggable Databases e seus respectivos modos de abertura
SELECT name, open_mode FROM v$pdbs;

-- Abrir o PDB recém-criado e salvar seu estado para inicializações futuras
ALTER PLUGGABLE DATABASE ORCLPDB1LINUX OPEN;
ALTER PLUGGABLE DATABASE ORCLPDB1LINUX SAVE STATE;

-- Alternar a sessão para o PDB de trabalho
ALTER SESSION SET CONTAINER = ORCLPDB1LINUX;

-- Criar usuário local de testes e conceder privilégios
CREATE USER arleyribeiro IDENTIFIED BY "Arley123" CONTAINER=CURRENT;
GRANT CONNECT, RESOURCE, DBA TO arleyribeiro CONTAINER=CURRENT;
ALTER USER arleyribeiro QUOTA UNLIMITED ON users;

-- Testar criação de estrutura no PDB
CREATE TABLE arleyribeiro.minha_tabela1 (
    id    NUMBER PRIMARY KEY,
    nome  VARCHAR2(50),
    idade NUMBER
);

INSERT INTO arleyribeiro.minha_tabela1 VALUES (1, 'Arley Ribeiro', 25);
COMMIT;

SELECT * FROM arleyribeiro.minha_tabela1;

-- Retornar ao CDB Root
ALTER SESSION SET CONTAINER = CDB$ROOT;


--------------------------------------------------------------------------------
-- PARTE 8: CONFIGURAÇÃO DO ENTERPRISE MANAGER EXPRESS (EM EXPRESS)
--------------------------------------------------------------------------------

-- Verificar porta HTTPS configurada para o CDB Root (Padrão: 5500)
SELECT dbms_xdb_config.getHttpsPort() FROM dual;

-- Configurar porta HTTPS dedicada para o PDB (ex: 5501)
ALTER SESSION SET CONTAINER = ORCLPDB1LINUX;
EXEC dbms_xdb_config.sethttpsport(5501);

SELECT dbms_xdb_config.getHttpsPort() FROM dual;

-- Retornar ao Root
ALTER SESSION SET CONTAINER = CDB$ROOT;

/*
  URLS DE ACESSO AO EM EXPRESS NO NAVEGADOR:
  - CDB Root : https://192.168.1.188:5500/em
  - PDB Local: https://192.168.1.188:5501/em
*/


--------------------------------------------------------------------------------
-- PARTE 9: EXECUÇÃO DE BACKUP FULL VIA RMAN
--------------------------------------------------------------------------------

/*
  -- Executar no terminal do Linux logado como usuário 'oracle':
  rman target /

  -- Comandos do RMAN para Backup do Banco e Controlfile:
  BACKUP DATABASE PLUS ARCHIVELOG;

  -- Exibir backups registrados:
  LIST BACKUP SUMMARY;
  EXIT;
*/