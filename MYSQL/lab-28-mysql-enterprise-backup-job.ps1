/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-28-mysql-enterprise-backup-job.ps1
  Objetivo     : Rotina automatizada de backup via MySQL Enterprise Backup
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Enterprise Backup
*******************************************************************************/

<#
  Bloco acima inserido conforme padrão exigido pelo laboratório.
#>

# Configurações do MySQL Enterprise Backup
$MEB_PATH = "C:\Program Files\MySQL\MySQL Enterprise Backup 8.0\mysqlbackup.exe"
$BACKUP_DIR = "C:\Backup\MySQL"
$TEMP_DIR = "C:\Backup\Temp"
$MYSQL_USER = "usuarioteste"
$MYSQL_PASSWORD = "Password123!" # Em ambiente de producao, evite senhas em texto plano

# Criar diretórios se não existirem
If (!(Test-Path $BACKUP_DIR)) { New-Item -ItemType Directory -Force -Path $BACKUP_DIR | Out-Null }
If (!(Test-Path $TEMP_DIR)) { New-Item -ItemType Directory -Force -Path $TEMP_DIR | Out-Null }

Write-Host "Iniciando rotina de Backup (MySQL Enterprise Backup)..."

# Comando de Backup Full
# Utiliza a flag backup-to-image para consolidar o backup em um único arquivo (.mbi)
& $MEB_PATH --user=$MYSQL_USER --password=$MYSQL_PASSWORD --backup-dir=$TEMP_DIR --backup-image="$BACKUP_DIR\full_backup.mbi" backup-to-image

If ($LASTEXITCODE -eq 0) {
    Write-Host "Backup Full executado com sucesso." -ForegroundColor Green
} Else {
    Write-Host "Erro durante a execucao do backup." -ForegroundColor Red
}
