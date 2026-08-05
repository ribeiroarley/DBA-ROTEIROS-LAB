<#
/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-21-backup-full-all-db.ps1
  Objetivo     : Backup logico completo de todas as bases via PowerShell
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual
*******************************************************************************/
#>

$ErrorActionPreference = "Stop"

try {
    $backuppath = "C:\mysqlapoio\backups\"
    if (-not (Test-Path -Path $backuppath)) {
        New-Item -ItemType Directory -Path $backuppath | Out-Null
    }

    $config = "C:\mysqlapoio\config.cnf"
    $errorLog = "C:\mysqlapoio\backups\erros\error_dump.log"
    
    $errorDir = "C:\mysqlapoio\backups\erros"
    if (-not (Test-Path -Path $errorDir)) {
        New-Item -ItemType Directory -Path $errorDir | Out-Null
    }

    $days = 30
    $date = Get-Date
    $timestamp = $date.ToString("yyyyMMdd_HHmmss")
    $backupfile = $backuppath + "AllDbs_" + $timestamp + ".sql"
    $backupzip = $backuppath + "AllDbs_" + $timestamp + ".zip"
      
    mysqldump.exe --defaults-extra-file=$config --log-error=$errorLog --result-file=$backupfile --all-databases --single-transaction --flush-logs --routines --events
    
    if (Test-Path -Path $backupfile) {
        7z.exe a -tzip $backupzip $backupfile
        Remove-Item -Path $backupfile -Force
    }

    $oldbackups = Get-ChildItem -Path $backuppath -Filter "*.zip"
    foreach ($file in $oldbackups) { 
        if ($file.CreationTime -lt $date.AddDays(-$days)) { 
            Remove-Item -Path $file.FullName -Force
        } 
    }
}
catch {
    Write-Error "Ocorreu um erro durante o backup: $_"
}
