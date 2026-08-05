/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-44-mysql-instancias-manuais.md
  Objetivo     : Criacao e configuracao de multiplas instancias manuais (Windows)
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Replication
*******************************************************************************/

# Configuração de Múltiplas Instâncias Manuais no Mesmo Host (Windows)

Este laboratório demonstra como configurar múltiplas instâncias nomeadas do MySQL 8.0+ no mesmo servidor Windows.

## 1. Estrutura de Diretórios
Crie a estrutura de diretórios para os binários e dados de cada instância:
- `C:\Program Files\MySQL\mysql8\bin` (Binários do MySQL)
- `C:\Program Files\MySQL\mysql8\data3306` (Dados Instância 1)
- `C:\Program Files\MySQL\mysql8\data3307` (Dados Instância 2)
- `C:\Program Files\MySQL\mysql8\data3308` (Dados Instância 3)

## 2. Inicialização dos Diretórios de Dados
Inicialize o diretório de dados base a partir dos binários:
```cmd
cd "C:\Program Files\MySQL\mysql8\bin"
mysqld --initialize-insecure
```
Mova o conteúdo gerado para as pastas específicas de cada instância. Remova o arquivo `auto.cnf` na pasta Data para que um novo UUID seja gerado para cada instância durante o startup.

## 3. Configuração do Arquivo my.ini
Crie o arquivo de configuração `C:\Program Files\MySQL\my.ini` contendo as seções compartilhadas e específicas de cada instância.

```ini
[mysqld]
basedir="C:\\Program Files\\MySQL\\mysql8"
innodb_flush_log_at_trx_commit=1
sync_binlog=1
log-bin="DBSRV-bin"
innodb_log_buffer_size=1M
innodb_buffer_pool_size=512M
innodb_log_file_size=100M

[mysql83306]
port=3306
server-id=1
datadir="C:\\Program Files\\MySQL\\mysql8\\data3306\\Data"
log-error="C:\\Program Files\\MySQL\\mysql8\\data3306\\log\\DBSRV.err"

[mysql83307]
port=3307
server-id=2
datadir="C:\\Program Files\\MySQL\\mysql8\\data3307\\Data"
log-error="C:\\Program Files\\MySQL\\mysql8\\data3307\\log\\DBSRV.err"

[mysql83308]
port=3308
server-id=3
datadir="C:\\Program Files\\MySQL\\mysql8\\data3308\\Data"
log-error="C:\\Program Files\\MySQL\\mysql8\\data3308\\log\\DBSRV.err"
```

## 4. Liberação de Portas no Firewall (Windows)
Libere o tráfego de rede para as instâncias:
```powershell
New-NetFirewallRule -DisplayName "MySQL_Instances" -Direction Inbound -LocalPort 3306,3307,3308 -Protocol TCP -Action Allow
```

## 5. Criação e Gerenciamento dos Serviços no Windows
Instale os serviços apontando para o arquivo de configuração customizado:

```cmd
cd "C:\Program Files\MySQL\mysql8\bin"

mysqld --install mysql83306 --defaults-file="C:\Program Files\MySQL\my.ini"
mysqld --install mysql83307 --defaults-file="C:\Program Files\MySQL\my.ini"
mysqld --install mysql83308 --defaults-file="C:\Program Files\MySQL\my.ini"
```

Inicie os serviços via Prompt de Comando:
```cmd
net start mysql83306
net start mysql83307
net start mysql83308
```

Para parar ou remover um serviço:
```cmd
net stop mysql83306
sc delete mysql83306
```
