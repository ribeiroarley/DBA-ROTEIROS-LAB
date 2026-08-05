/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-39-mysql-linux-performance-mycnf.md
  Objetivo     : Tuning Avançado de Performance no my.cnf (Linux)
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Linux Optimizations
*******************************************************************************/

# Tuning Avançado de Performance no my.cnf

Este laboratório detalha a configuração dinâmica e estática dos parâmetros críticos de I/O, memória e ACID do InnoDB em servidores Linux.

## 1. Tuning de Memória: Buffer Pool e Instâncias

O `innodb_buffer_pool_size` define a memória alocada para caches de dados e índices. Recomenda-se configurar entre 70% a 80% da memória RAM em servidores dedicados ao MySQL. O parâmetro `innodb_buffer_pool_instances` melhora a concorrência em buffer pools maiores que 1GB.

### Alteração Dinâmica (A Quente)
```sql
-- Verifica a alocacao atual em Bytes
SHOW GLOBAL VARIABLES LIKE 'innodb_buffer_pool_size';
SHOW GLOBAL VARIABLES LIKE 'innodb_buffer_pool_instances';

-- Altera o Buffer Pool para 2GB (2147483648 bytes)
SET GLOBAL innodb_buffer_pool_size = 2147483648;
```

### Alteração Estática (Definitiva no my.cnf)
Para persistir a configuração, adicione ao `my.cnf`:
```ini
[mysqld]
innodb_buffer_pool_size = 2G
innodb_buffer_pool_instances = 8
```

## 2. Procedimento Seguro: Alteração do Local dos Redo Logs

Separar os arquivos de Redo Log (logs de transação) dos arquivos de dados (Tablespaces) em volumes físicos diferentes reduz a contenção de I/O.

### Execução via Shell
```bash
# 1. Parar o serviço do MySQL
sudo systemctl stop mysql

# 2. Criar o novo diretório para os Redo Logs
sudo mkdir -p /dbfiles/#innodb_redo

# 3. Alterar as permissões para o usuário de serviço do MySQL
sudo chown -R mysql:mysql /dbfiles/
sudo chmod -R 750 /dbfiles/

# 4. Ajustar o arquivo de configuração
sudo nano /etc/mysql/my.cnf
```

### Configuração no my.cnf
Adicione a diretiva do novo caminho (Atenção: não utilizar aspas no diretório `innodb_log_group_home_dir` no arquivo de configuração):
```ini
[mysqld]
innodb_log_group_home_dir = /dbfiles/#innodb_redo
# Para versoes MySQL >= 8.0.30
innodb_redo_log_capacity = 104857600
```

```bash
# 5. Iniciar o serviço do MySQL
sudo systemctl start mysql

# 6. Monitorar o arquivo de log para garantir que nao houveram erros
tail -f /var/log/mysql/error.log
```
*Nota: Após confirmar a estabilidade, pode-se realizar o cleanup do diretório `#innodb_redo` antigo.*

## 3. Configuração de Parâmetros Cruciais de ACID e I/O

Estes parâmetros garantem um equilíbrio entre performance e durabilidade das transações.

Edite o arquivo de configuração `/etc/mysql/my.cnf` e adicione os seguintes parâmetros na sessão `[mysqld]`:

```ini
[mysqld]
# ----------------------------------------------------------------------
# ACID E DURABILIDADE
# ----------------------------------------------------------------------
# Define como as transacoes sao escritas e o flush para o disco
# 1 = Maxima seguranca, menor performance (Recomendado para Producao Critica)
# 2 = Maior performance, aceita perda de 1 segundo de dados em caso de crash do SO
innodb_flush_log_at_trx_commit = 1

# Sincronizacao do Binlog
# 1 = Sicrono e seguro (Recomendado)
# 0 = Delega a sincronizacao ao SO (Maior performance, menos seguro)
sync_binlog = 1

# ----------------------------------------------------------------------
# I/O METHOD
# ----------------------------------------------------------------------
# O_DIRECT ignora o cache do Sistema Operacional, evitando 
# double-buffering e otimizando a leitura/gravacao direta no disco.
innodb_flush_method = O_DIRECT

# ----------------------------------------------------------------------
# CAPACITY E CONCURRENCY
# ----------------------------------------------------------------------
# Define a capacidade de I/O do disco (IOPS). 
# Aumentar conforme a capacidade de leitura/gravacao do disco (ex: SSD = 5000+)
innodb_io_capacity = 750
innodb_io_capacity_max = 1000

# Limita a concorrencia de threads, balanceando o consumo de CPU.
# Ajuste conforme o numero de cores do servidor. (Default: 0 - ilimitado)
innodb_thread_concurrency = 8
```

Após todas as alterações, o serviço deve ser reiniciado para aplicação:
```bash
sudo systemctl restart mysql
```
