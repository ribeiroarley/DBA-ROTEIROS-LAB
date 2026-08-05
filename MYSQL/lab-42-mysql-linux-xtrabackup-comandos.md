/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-42-mysql-linux-xtrabackup-comandos.md
  Objetivo     : Manual pratico para backup e restore fisico com XtraBackup
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Percona XtraBackup Docs
*******************************************************************************/

# Percona XtraBackup - MySQL Database Backup Software

Este roteiro cobre o uso prático do Percona XtraBackup para realização de backups físicos no MySQL 8.x no Linux.

## 1. Instalação do XtraBackup

```bash
# Baixar pacote percona-release
sudo wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb

# Instalar o pacote
sudo dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
sudo apt-get update

# Habilitar o repositório
sudo percona-release enable-only tools release
sudo apt-get update

# Instalar XtraBackup e utilitarios de compactacao
sudo apt install percona-xtrabackup-80 qpress zstd -y
```

## 2. Criação de Usuário de Backup no MySQL

Antes de realizar os backups, é necessário um usuário com permissões adequadas:

```sql
-- No terminal do MySQL:
CREATE USER 'usuarioteste'@'localhost' IDENTIFIED BY 'SenhaForte123!';
GRANT BACKUP_ADMIN, PROCESS, RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'usuarioteste'@'localhost';
GRANT SELECT ON performance_schema.log_status TO 'usuarioteste'@'localhost';
GRANT SELECT ON performance_schema.keyring_component_status TO 'usuarioteste'@'localhost';
GRANT SELECT ON performance_schema.replication_group_members TO 'usuarioteste'@'localhost';
FLUSH PRIVILEGES;
```

## 3. Backup Full

Realiza o backup de todo o servidor sem parar a instância do MySQL.

```bash
# Criar diretório de destino
sudo mkdir -p /lvm3/xtrabackup/bkfull

# Executar backup full
sudo xtrabackup --no-server-version-check --user=usuarioteste --password='SenhaForte123!' --backup --target-dir=/lvm3/xtrabackup/bkfull
```

## 4. Prepare e Restore Full

Para restaurar um backup físico, é obrigatório prepará-lo (sincronizar logs) e então copiá-lo para o diretório de dados (datadir).

```bash
# PREPARE: Prepara o backup para restauracao (consolida as transacoes pendentes)
sudo xtrabackup --prepare --target-dir=/lvm3/xtrabackup/bkfull

# Parar o servico MySQL
sudo service mysql stop

# Fazer backup preventivo do datadir e depois esvazia-lo
sudo cp -r /var/lib/mysql /var/lib/mysql_bkp
sudo rm -rf /var/lib/mysql/*

# RESTORE: Copia os dados preparados de volta para o datadir
sudo xtrabackup --copy-back --datadir=/var/lib/mysql --target-dir=/lvm3/xtrabackup/bkfull

# Ajustar permissoes e reiniciar o servico
sudo chown -R mysql:mysql /var/lib/mysql
sudo service mysql start
```

## 5. Backup Incremental

Backups incrementais copiam apenas os dados que mudaram desde um backup específico.

```bash
# Realizar o primeiro backup incremental (baseado no bkfull)
sudo xtrabackup --backup --no-server-version-check --user=usuarioteste --password='SenhaForte123!' --target-dir=/lvm3/xtrabackup/bk_inc1 --incremental-basedir=/lvm3/xtrabackup/bkfull

# Realizar o segundo backup incremental (baseado no bk_inc1)
sudo xtrabackup --backup --no-server-version-check --user=usuarioteste --password='SenhaForte123!' --target-dir=/lvm3/xtrabackup/bk_inc2 --incremental-basedir=/lvm3/xtrabackup/bk_inc1
```

## 6. Restore Incremental

A preparação de backups incrementais exige que todos os deltas sejam aplicados ao backup full.

```bash
# Preparar o Backup Full (COM apply-log-only para evitar rollback prematuro)
sudo xtrabackup --prepare --apply-log-only --target-dir=/lvm3/xtrabackup/bkfull

# Aplicar o primeiro incremental ao Full (COM apply-log-only)
sudo xtrabackup --prepare --apply-log-only --target-dir=/lvm3/xtrabackup/bkfull --incremental-dir=/lvm3/xtrabackup/bk_inc1

# Aplicar o ultimo incremental ao Full (SEM apply-log-only)
sudo xtrabackup --prepare --target-dir=/lvm3/xtrabackup/bkfull --incremental-dir=/lvm3/xtrabackup/bk_inc2

# Com todos os deltas aplicados, o diretório bkfull contém os dados mais recentes.
# Parar o serviço, esvaziar o datadir e aplicar o restore.
sudo service mysql stop
sudo rm -rf /var/lib/mysql/*
sudo xtrabackup --copy-back --datadir=/var/lib/mysql --target-dir=/lvm3/xtrabackup/bkfull
sudo chown -R mysql:mysql /var/lib/mysql
sudo service mysql start
```

## 7. Restore de Tabelas Específicas (Sem Parar a Instância)

Para tabelas em `.ibd` (file_per_table habilitado), é possível restaurar os arquivos isoladamente usando o parâmetro `--export`.

```bash
# 1. Executar um backup full novo
sudo xtrabackup --backup --no-server-version-check --user=usuarioteste --password='SenhaForte123!' --target-dir=/lvm3/xtrabackup/bkfull_tabela

# 2. Preparar o backup com a flag --export
sudo xtrabackup --prepare --export --target-dir=/lvm3/xtrabackup/bkfull_tabela

# 3. No MySQL, descarte o tablespace da tabela que deseja restaurar (Ex: tabela 'teste')
# mysql> USE meubanco;
# mysql> ALTER TABLE teste DISCARD TABLESPACE;

# 4. No Linux, copie os arquivos .ibd e .cfg do backup para o datadir
sudo cp /lvm3/xtrabackup/bkfull_tabela/meubanco/teste.* /var/lib/mysql/meubanco/
sudo chown -R mysql:mysql /var/lib/mysql/meubanco/teste.*

# 5. No MySQL, importe o tablespace para reconectar a tabela fisicamente
# mysql> USE meubanco;
# mysql> ALTER TABLE teste IMPORT TABLESPACE;
```
