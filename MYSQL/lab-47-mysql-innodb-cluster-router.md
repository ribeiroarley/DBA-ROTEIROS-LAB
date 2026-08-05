/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-47-mysql-innodb-cluster-router.md
  Objetivo     : Implantação e Administração de InnoDB Cluster, MySQL Shell e Router
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / InnoDB Cluster
*******************************************************************************/

# InnoDB Cluster e MySQL Router - Laboratório de Alta Disponibilidade

Este laboratório descreve os passos para configurar um ambiente de alta disponibilidade (HA) com MySQL Shell, Group Replication (InnoDB Cluster) e MySQL Router em ambiente Windows Server, utilizando múltiplas instâncias na mesma máquina.

---

## 1. Ajustes Obrigatórios no `my.ini` para Suporte ao InnoDB Cluster

Configuração do arquivo `my.ini` para as três instâncias MySQL (portas 3306, 3307 e 3308). Realize o backup do arquivo antigo, pare os serviços, aplique as configurações abaixo e inicie os serviços novamente.

```ini
# SERVER SECTION
# ----------------------------------------------------------------------

[mysqld]
basedir="C:\\Program Files\\MySQL\\mysql8"
innodb_flush_log_at_trx_commit=1
sync_binlog=1
log-bin="DBSRV-bin"
innodb_log_buffer_size=1M
innodb_buffer_pool_size=512M
innodb_log_file_size=100M

# ----------------------------------------------------------------------
[mysql83306]
port=3306
server-id=1
datadir=C:\\Program Files\\MySQL\\mysql8\\data3306\\Data
log-output=FILE
general-log=0
general_log_file="C:\\Program Files\\MySQL\\mysql8\\data3306\\log\\LogDBSRV.log"
slow-query-log=1
slow_query_log_file="C:\\Program Files\\MySQL\\mysql8\\data3306\\log\\DBSRV-slow.log"
long_query_time=10
log-error="C:\\Program Files\\MySQL\\mysql8\\data3306\\log\\DBSRV.err"

# ----------------------------------------------------------------------
[mysql83307]
port=3307
server-id=2
datadir=C:\\Program Files\\MySQL\\mysql8\\data3307\\Data
log-output=FILE
general-log=0
general_log_file="C:\\Program Files\\MySQL\\mysql8\\data3307\\log\\LogDBSRV.log"
slow-query-log=1
slow_query_log_file="C:\\Program Files\\MySQL\\mysql8\\data3307\\log\\DBSRV-slow.log"
long_query_time=10
log-error="C:\\Program Files\\MySQL\\mysql8\\data3307\\log\\DBSRV.err"

# ----------------------------------------------------------------------
[mysql83308]
port=3308
server-id=3
datadir=C:\\Program Files\\MySQL\\mysql8\\data3308\\Data
log-output=FILE
general-log=0
general_log_file="C:\\Program Files\\MySQL\\mysql8\\data3308\\log\\LogDBSRV.log"
slow-query-log=1
slow_query_log_file="C:\\Program Files\\MySQL\\mysql8\\data3308\\log\\DBSRV-slow.log"
long_query_time=10
log-error="C:\\Program Files\\MySQL\\mysql8\\data3308\\log\\DBSRV.err"
```

---

## 2. Preparação de Instâncias e Usuários

Antes de criar o cluster, garanta que não existam replicações ativas remanescentes e crie o usuário de administração.

### 2.1. Reset de Replicações Existentes

Acesse cada instância e execute o reset.

```sql
SHOW REPLICA STATUS\G;
STOP REPLICA;
RESET REPLICA ALL;
```

### 2.2. Criação do Usuário Administrativo (`usuarioteste`)

Acesse cada instância (3306, 3307, 3308) e crie um usuário com privilégios administrativos.

```sql
DROP USER IF EXISTS 'usuarioteste'@'%';
CREATE USER 'usuarioteste'@'%' IDENTIFIED BY 'SenhaSegura123!';
GRANT ALL PRIVILEGES ON *.* TO 'usuarioteste'@'%' WITH GRANT OPTION;
```

*(Nota: Caso encontre erro `super-read-only`, altere com `SET GLOBAL super_read_only = OFF;`)*

---

## 3. Configuração do InnoDB Cluster via MySQL Shell

Execute o MySQL Shell (`mysqlsh.exe`) localizado em `C:\Program Files\mysql\mysql8\bin`.

### 3.1. Verificação das Instâncias (`dba.checkInstanceConfiguration`)

Verifique se cada instância está preparada para participar do cluster.

```javascript
dba.checkInstanceConfiguration('usuarioteste@127.0.0.1:3306')
dba.checkInstanceConfiguration('usuarioteste@127.0.0.1:3307')
dba.checkInstanceConfiguration('usuarioteste@127.0.0.1:3308')
```

### 3.2. Configuração das Instâncias (`dba.configureInstance`)

Configure cada instância para uso no cluster, criando um usuário interno para a comunicação.

```javascript
dba.configureInstance('usuarioteste@127.0.0.1:3306', {clusterAdmin:'clusteruser_teste', clusterAdminPassword:'PasswordCluster123!'})
dba.configureInstance('usuarioteste@127.0.0.1:3307', {clusterAdmin:'clusteruser_teste', clusterAdminPassword:'PasswordCluster123!'})
dba.configureInstance('usuarioteste@127.0.0.1:3308', {clusterAdmin:'clusteruser_teste', clusterAdminPassword:'PasswordCluster123!'})
```

Responda `y` (yes) quando questionado sobre realizar as mudanças necessárias e reiniciar a instância.

---

## 4. Criação do Cluster e Adição de Instâncias

### 4.1. Conexão na Instância Primária e Criação do Cluster (`dba.createCluster`)

Conecte-se à primeira instância (3306) e inicie o cluster.

```javascript
\connect usuarioteste@127.0.0.1:3306
```

Crie o cluster:

```javascript
dba.createCluster('clustermysql', {expelTimeout:600, autoRejoinTries:10})
```

Atribua o status do cluster a uma variável e verifique:

```javascript
var cluster = dba.getCluster()
cluster.status()
```

### 4.2. Adição de Instâncias ao Cluster (`cluster.addInstance`)

Adicione as instâncias 3307 e 3308 para garantir alta disponibilidade. Selecione a opção `c` (Clone) durante o processo, se solicitado, para sincronização do snapshot.

```javascript
cluster.addInstance('usuarioteste@127.0.0.1:3307', {waitRecovery:3, autoRejoinTries:10})
cluster.addInstance('usuarioteste@127.0.0.1:3308', {waitRecovery:3, autoRejoinTries:10})
```

Após adicionar todas as instâncias, verifique novamente o status, o qual deve exibir tolerância a falhas.

```javascript
cluster.status()
```

---

## 5. Administração e Recuperação de Falhas

### 5.1. Eleição de Nova Instância Primária

Para alterar manualmente a instância primária (por exemplo, retornando para a 3306):

```javascript
var cluster = dba.getCluster()
cluster.setPrimaryInstance('usuarioteste@127.0.0.1:3306')
cluster.status()
```

### 5.2. Recuperação de Falha Completa (Outage)

Caso o cluster sofra indisponibilidade total e seja reiniciado, será necessário restaurá-lo. Conecte-se pelo MySQL Shell e utilize o comando de reboot:

```javascript
dba.rebootClusterFromCompleteOutage()
```

---

## 6. Configuração e Inicialização do MySQL Router

O MySQL Router atuará como proxy para roteamento transparente de conexões da aplicação.

### 6.1. Bootstrap do MySQL Router

Abra o prompt de comando (como Administrador) e crie um diretório base para o Router:

```bash
mkdir C:\mysqlrouter
```

Execute o bootstrap conectando-se a uma instância do cluster:

```bash
cd "C:\Program Files\mysql\mysql8\bin"
mysqlrouter --bootstrap usuarioteste@127.0.0.1:3306 --directory C:\mysqlrouter --account routeruser_teste --force
```

### 6.2. Instalação e Gerenciamento do Serviço

Instale o serviço do MySQL Router no Windows:

```bash
mysqlrouter --config C:\mysqlrouter\mysqlrouter.conf --install-service
```

O Router disponibilizará portas para conexão:
- **Porta 6446**: R/W (Read/Write) - Conexões direcionadas automaticamente à Instância Primária.
- **Porta 6447**: R/O (Read/Only) - Conexões balanceadas entre as Instâncias Secundárias.

Para remover o serviço, caso necessário, pare o serviço no Windows e execute:

```bash
mysqlrouter --config C:\mysqlrouter\mysqlrouter.conf --remove-service
```
