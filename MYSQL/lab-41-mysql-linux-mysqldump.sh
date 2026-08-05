/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-41-mysql-linux-mysqldump.sh
  Objetivo     : Rotina de backup e restore logico usando mysqldump
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Percona XtraBackup Docs
*******************************************************************************/
#!/bin/bash

# ==============================================================================
# 1. COMANDOS DE BACKUP MANUAL
# ==============================================================================
# Backup de banco específico:
# mysqldump -u usuarioteste -p teste --single-transaction > /lvm3/mysqlbackup/bkfull.sql

# Backup de todos os bancos com rotinas e eventos:
# mysqldump -u usuarioteste -p --all-databases --routines --events --single-transaction > /lvm3/mysqlbackup/allbkfull.sql

# ==============================================================================
# 2. COMANDOS DE RESTORE MANUAL
# ==============================================================================
# Restaurando um banco de dados:
# mysql -u usuarioteste -p teste_restaurado < /lvm3/mysqlbackup/bkfull.sql

# ==============================================================================
# 3. COMPACTACAO E DESCOMPACTACAO
# ==============================================================================
# Compactar com bzip2:
# bzip2 /lvm3/mysqlbackup/bkfull.sql

# Descompactar com bzip2:
# bzip2 -d /lvm3/mysqlbackup/bkfull.sql.bz2

# Compactar com tar/gzip:
# tar -czvf /lvm3/mysqlbackup/bkfull.tar.gz /lvm3/mysqlbackup/bkfull.sql

# Descompactar com tar/gzip:
# tar -xzvf /lvm3/mysqlbackup/bkfull.tar.gz

# ==============================================================================
# 4. ROTINA DE AUTOMAÇÃO COM LOGIN-PATH
# ==============================================================================
# OBS: O comando abaixo deve ser executado previamente para criar a credencial criptografada:
# mysql_config_editor set --login-path=multiuseaccesslinux_mysql_bkpuser --host=localhost --user=usuarioteste --password

DB_PARAM="--all-databases --routines --events --single-transaction"
MYSQLDUMP="/usr/bin/mysqldump"
BACKUP_DIR="/lvm3/mysqlbackup"
DIAS=7

DATE=$(date +%Y-%m-%d-%Hh-%M)
BACKUP_NAME="mysql-Alldb-$DATE.sql"
BACKUP_BZ2="mysql-Alldb-$DATE.sql.bz2"
LOG_FILE="$BACKUP_DIR/backupalldb.log"

echo "Iniciando o processo de backup logico..."

# Criar diretorio se nao existir
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
fi

# Gerando arquivo sql
echo "Gerando backup no arquivo $BACKUP_DIR/$BACKUP_NAME"
$MYSQLDUMP --login-path=multiuseaccesslinux_mysql_bkpuser $DB_PARAM > "$BACKUP_DIR/$BACKUP_NAME"

# Compactando arquivo com bzip2
echo "Compactando arquivo em bzip2 ..."
bzip2 "$BACKUP_DIR/$BACKUP_NAME"

# Verificacao de integridade basica do arquivo gerado
if [[ $? -eq 0 ]]; then
    filesize=$(stat -c %s "$BACKUP_DIR/$BACKUP_BZ2")

    # Checar se o tamanho do backup tem ao menos 10K (exemplo)
    if [[ $filesize -gt 10000 ]]; then
        echo "Backup Completado com Sucesso - $(date)" >> "$LOG_FILE"

        # Excluindo backups antigos
        echo "Excluindo arquivos mais antigos que $DIAS dias..."
        find "$BACKUP_DIR/" -name "*.bz2" -type f -mtime +$DIAS -exec rm -f {} \;
    else
        echo "ERROR encontrado no Backup do Banco (Tamanho Invalido) - $(date)" >> "$LOG_FILE"
    fi
else
    echo "ERROR encontrado no Backup do Banco (Falha no mysqldump) - $(date)" >> "$LOG_FILE"
fi

echo "Processo finalizado."
