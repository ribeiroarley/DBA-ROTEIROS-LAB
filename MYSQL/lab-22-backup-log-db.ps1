<#
/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-22-backup-log-db.ps1
  Objetivo     : Backup de binlogs via PowerShell e flush-logs
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual
*******************************************************************************/
#>

$ErrorActionPreference = "Stop"

try {
    $dadosoriginaispath = "C:\ProgramData\MySQL\MySQL Server 8.0\Data\*-bin.*"
    $backuppath = "C:\mysqlapoio\backups\"
    if (-not (Test-Path -Path $backuppath)) {
        New-Item -ItemType Directory -Path $backuppath | Out-Null
    }

    $config = "C:\mysqlapoio\config.cnf"
    $date = Get-Date
    $timestamp = $date.ToString("yyyyMMdd_HHmmss")
    
    $backupfile = $backuppath + "*-bin.*"
    $backupzip = $backuppath + "BINLOGBK_" + $timestamp + ".zip"

    mysqladmin --defaults-extra-file=$config flush-logs

    Copy-Item -Path $dadosoriginaispath -Destination $backuppath -Force
    
    if (Test-Path -Path $backupfile) {
        7z.exe a -tzip $backupzip $backupfile
        Remove-Item -Path $backupfile -Force
    }

    $days = 30
    $oldbackups = Get-ChildItem -Path $backuppath -Filter "BINLOGBK_*.zip"
    foreach ($file in $oldbackups) { 
        if ($file.CreationTime -lt $date.AddDays(-$days)) { 
            Remove-Item -Path $file.FullName -Force
        } 
    }
}
catch {
    Write-Error "Ocorreu um erro durante o backup dos logs: $_"
}
