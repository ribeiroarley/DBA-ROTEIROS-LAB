/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-43-mysql-linux-xtrabackup-auto.sh
  Objetivo     : Rotina automatizada de backup fisico com XtraBackup
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Percona XtraBackup Docs
*******************************************************************************/
#!/bin/bash

# ==============================================================================
# CONFIGURACAO PREVIA (LOGIN-PATH)
# O usuário deve ter um profiler do login-path criado antes da execucao.
# Exemplo: 
# mysql_config_editor set --login-path=multiuseaccesslinux_mysql_bkpuser --host=localhost --user=usuarioteste --password 
# ==============================================================================

TMPFILE="/tmp/xtrabackup-runner.$$.tmp"

# Usando a senha criptografada com mysql_config_editor
USEROPTIONS="--login-path=multiuseaccesslinux_mysql_bkpuser --host=localhost"

# Diretorio base para backups
BACKDIR="/lvm3/xtrabackupautomatico"
BASEBACKDIR="$BACKDIR/base"
INCRBACKDIR="$BACKDIR/incr"

# Ciclo de Backup Full em segundos (28800 = 8 horas)
FULLBACKUPCYCLE=28800

# Numero de ciclos adicionais a reter
KEEP=43

START=$(date +%s)

echo "--------------------------------------------------------"
echo " run-xtrabackup.sh: MySQL automatic physical backup"
echo " Started: $(date)"
echo "--------------------------------------------------------"

# Criacao de diretorios se nao existirem
mkdir -p "$BASEBACKDIR"
mkdir -p "$INCRBACKDIR"

# Check de integridade do diretorio base
if [ ! -d "$BASEBACKDIR" ] || [ ! -w "$BASEBACKDIR" ]; then
  echo "ERRO: $BASEBACKDIR does not exist or is not writable"
  exit 1
fi

# Check de integridade do diretorio incremental
if [ ! -d "$INCRBACKDIR" ] || [ ! -w "$INCRBACKDIR" ]; then
  echo "ERRO: $INCRBACKDIR does not exist or is not writable"
  exit 1
fi

# Checar conectividade do MySQL
if ! mysqladmin $USEROPTIONS status | grep -q 'Uptime'; then
  echo "HALTED: MySQL does not appear to be running."
  exit 1
fi

if ! echo 'exit' | mysql $USEROPTIONS -s; then
  echo "HALTED: Supplied mysql connection properties appear to be incorrect."
  exit 1
fi

echo "Check completed OK"

# Descobrir o diretorio do backup full mais recente
LATEST=$(find "$BASEBACKDIR" -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1)

if [ -n "$LATEST" ]; then
    AGE=$(stat -c %Y "$BASEBACKDIR/$LATEST")
else
    AGE=0
fi

# Decisao logica: Realizar Full ou Incremental
if [ -n "$LATEST" ] && [ $((AGE + FULLBACKUPCYCLE + 5)) -ge "$START" ]; then
  echo 'New incremental backup'
  
  # Criar diretorio incremental base se nao existir
  mkdir -p "$INCRBACKDIR/$LATEST"

  if [ ! -w "$INCRBACKDIR/$LATEST" ]; then
    echo "ERRO: $INCRBACKDIR/$LATEST is not writable"
    exit 1
  fi

  LATESTINCR=$(find "$INCRBACKDIR/$LATEST" -mindepth 1 -maxdepth 1 -type d | sort -nr | head -1)
  
  if [ -z "$LATESTINCR" ]; then
    # Primeiro backup incremental (baseado no full)
    INCRBASEDIR="$BASEBACKDIR/$LATEST"
  else
    # Segundo ou mais (baseado no incremental anterior)
    INCRBASEDIR="$LATESTINCR"
  fi

  TARGETDIR="$INCRBACKDIR/$LATEST/$(date +%F_%H-%M-%S)"

  # Criar Incremental
  xtrabackup --no-server-version-check --compress --backup $USEROPTIONS --target-dir="$TARGETDIR" --incremental-basedir="$INCRBASEDIR" > "$TMPFILE" 2>&1
else
  echo 'New full backup'

  TARGETDIR="$BASEBACKDIR/$(date +%F_%H-%M-%S)"

  # Criar Full
  xtrabackup --no-server-version-check --compress --backup $USEROPTIONS --target-dir="$TARGETDIR" > "$TMPFILE" 2>&1
fi

# Verificar se o backup ocorreu com sucesso
if ! tail -1 "$TMPFILE" | grep -q 'completed OK!'; then
  echo "xtrabackup failed:"
  echo "---------- ERROR OUTPUT from xtrabackup ----------"
  cat "$TMPFILE"
  rm -f "$TMPFILE"
  exit 1
fi

THISBACKUP=$(awk -F"'" '/Backup created in directory/ {print $2}' "$TMPFILE")

echo "Databases backed up successfully to: $THISBACKUP"

MINS=$(( (FULLBACKUPCYCLE * (KEEP + 1)) / 60 ))
echo "Cleaning up old backups (older than $MINS minutes) and temporary files"

# Deletar arquivo temporario e limpar backups antigos
rm -f "$TMPFILE"

find "$BASEBACKDIR" -mindepth 1 -maxdepth 1 -type d -mmin +$MINS -printf "%P\n" | while read -r DEL; do
  echo "deleting $DEL"
  rm -rf "$BASEBACKDIR/$DEL"
  rm -rf "$INCRBACKDIR/$DEL"
done

SPENT=$(( ($(date +%s) - START) / 60 ))
echo "Took $SPENT minutes"
echo "Completed: $(date)"

exit 0
