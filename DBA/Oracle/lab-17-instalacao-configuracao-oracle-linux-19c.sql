/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-17-instalacao-configuracao-oracle-linux-19c.sql
  Objetivo     : Roteiro prático e guia de comandos para preparação do S.O. 
                 Oracle Linux (Red Hat) focado em hospedar o Oracle Database 19c.
                 Inclui particionamento LVM, SSH, controle de Firewall, IP estático
                 e integração com views de monitoramento da instância.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Linux 9 Installation Guide / Database Installation Guide for Linux
*******************************************************************************/

--------------------------------------------------------------------------------
-- PARTE 1: PREPARAÇÃO DA MÁQUINA VIRTUAL E PARTICIONAMENTO LVM (S.O.)
--------------------------------------------------------------------------------

/*
  REQUISITOS DA VM (VIRTUALBOX / HYPER-V):
  - Nome da VM: vmoraclelinux19c
  - Memória RAM Mínima: 4096 MB (4 GB)
  - Processadores (vCPU): 4 Cores
  - Armazenamento: 80 GB (Dynamically Allocated / VDI)
  - Placa de Rede: Modo Bridge (Acesso Direto à Sub-rede)

  ESTRUTURA DE PARTICIONAMENTO RECOMENDADA (LVM - LOGICAL VOLUME MANAGER):
  - /boot      : 1 GiB (ext4 ou xfs)
  - /boot/efi  : 512 MiB (para boot UEFI)
  - / (root)   : 50 GiB (ext4)
  - swap       : 4096 MiB (4 GB)
  - /home      : 30 GiB (ext4)
*/


--------------------------------------------------------------------------------
-- PARTE 2: CONFIGURAÇÕES INICIAIS DO SERVIDOR E REDE NO ORACLE LINUX
--------------------------------------------------------------------------------

/*
  -- 1. Fazer logon no servidor como usuário Root (Terminal):
  -- Login: root | Senha: <senha_definida>

  -- 2. Validar informações de Kernel e versão da distribuição:
  hostname
  whoami
  uname -r
  cat /etc/oracle-release

  -- 3. Atualizar pacotes de sistema e segurança:
  sudo yum update -y
  sudo yum upgrade -y

  -- 4. Desabilitar o Firewall local para evitar bloqueios na porta 1521/TNS:
  sudo systemctl stop firewalld
  sudo systemctl disable firewalld
  sudo systemctl status firewalld

  -- 5. Liberar acesso SSH remoto direto via Root (Editar /etc/ssh/sshd_config):
  -- Alterar a linha: PermitRootLogin yes
  -- Salvar o arquivo e reiniciar o serviço SSH:
  sudo systemctl restart sshd

  -- 6. Configurar Endereço IP Estático na Interface de Rede (NetworkManager):
  -- Consultar a interface ativa (ex: enp0s3):
  ip a

  -- Aplicar IP estático, Gateway e DNS:
  nmcli con mod enp0s3 ipv4.method manual
  nmcli con mod enp0s3 ipv4.addresses 192.168.1.188/24
  nmcli con mod enp0s3 ipv4.gateway 192.168.1.1
  nmcli con mod enp0s3 ipv4.dns 192.168.1.1
  nmcli connection reload
  nmcli con down enp0s3
  nmcli con up enp0s3

  -- 7. Reiniciar o servidor para consolidar as alterações:
  sudo reboot
*/


--------------------------------------------------------------------------------
-- PARTE 3: CONSULTAS SQL DE VALIDAÇÃO DA INFRAESTRUTURA NO BANCO (19c)
--------------------------------------------------------------------------------

-- Conectar como SYSDBA no Container Root
CONNECT / AS SYSDBA;

-- Checar o nome do Host, Instância e versão em execução
SELECT 
    host_name, 
    instance_name, 
    version, 
    status, 
    to_char(startup_time, 'DD/MM/YYYY HH24:MI:SS') AS startup_time
FROM v$instance;

-- Identificar a plataforma do S.O. onde a base Oracle está sendo executada
SELECT 
    dbid, 
    name AS db_name, 
    platform_name, 
    open_mode 
FROM v$database;

-- Mapear os Datafiles e seus respectivos caminhos no sistema de arquivos do Linux/Windows
SELECT 
    file_id, 
    tablespace_name, 
    file_name, 
    bytes / 1024 / 1024 AS size_mb 
FROM dba_data_files;

-- Consultar informações sobre todos os Pluggable Databases no servidor
SELECT 
    con_id, 
    name AS pdb_name, 
    open_mode 
FROM v$pdbs;