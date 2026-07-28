/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-29-mysql-enterprise-backup-restore.ps1
  Objetivo     : Rotina de restauracao de instancia MySQL via Enterprise Backup
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Enterprise Backup
*******************************************************************************/

<#
  Bloco acima inserido conforme padrão exigido pelo laboratório.
#>

# Configurações
$MEB_PATH = "C:\Program Files\MySQL\MySQL Enterprise Backup 8.0\mysqlbackup.exe"
$BACKUP_IMAGE = "C:\Backup\MySQL\full_backup.mbi"
$DATA_DIR = "C:\ProgramData\MySQL\MySQL Server 8.0\Data"
$OLD_DATA_DIR = "C:\ProgramData\MySQL\MySQL Server 8.0\Data_old"

Write-Host "Iniciando processo de Restore (MySQL Enterprise Backup)..."

# Parar o serviço do MySQL antes do restore
Write-Host "Parando servico do MySQL..."
Stop-Service -Name "MySQL80" -Force

# Renomear o diretório de dados atual por segurança
If (Test-Path $DATA_DIR) {
    Write-Host "Renomeando diretorio de dados atual para backup de seguranca..."
    Rename-Item -Path $DATA_DIR -NewName $OLD_DATA_DIR
}

# Criar novo diretório de dados limpo
New-Item -ItemType Directory -Force -Path $DATA_DIR | Out-Null

# O restore de uma imagem única (MBI) na documentação oficial exige que 
# os dados sejam extraídos para um diretório temporário, que em seguida é 
# preparado (apply-log) e restaurado ao DataDir (copy-back).
$TEMP_DIR = "C:\Backup\Temp"
If (!(Test-Path $TEMP_DIR)) { New-Item -ItemType Directory -Force -Path $TEMP_DIR | Out-Null }

Write-Host "Extraindo imagem de backup para diretorio temporario..."
& $MEB_PATH --backup-image=$BACKUP_IMAGE --backup-dir=$TEMP_DIR extract

Write-Host "Aplicando logs e restaurando a base de dados (copy-back-and-apply-log)..."
& $MEB_PATH --backup-dir=$TEMP_DIR --datadir=$DATA_DIR copy-back-and-apply-log

# (Opcional/Recomendado) Ajustar permissões para o usuário de serviço no novo DataDir
# icacls $DATA_DIR /grant "usuarioteste:(OI)(CI)F" /T

# Iniciar o serviço do MySQL
Write-Host "Iniciando servico do MySQL..."
Start-Service -Name "MySQL80"

Write-Host "Processo de restore concluido com sucesso." -ForegroundColor Green
