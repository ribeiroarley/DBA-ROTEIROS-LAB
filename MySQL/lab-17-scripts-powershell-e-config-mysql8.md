### Sugestão de Caminho e Nome do Arquivo

**Caminho:** `C:\Users\arsx_\Documents\DBA\dba-education-lab\02-setup-ambiente\scripts-automacao\`

**Arquivo:** `lab-17-scripts-powershell-e-config-mysql8.md`

```markdown
# DBA EDUCATION LAB - SCRIPTS DE AUTOMAÇÃO E CONFIGURAÇÃO DE BACKUP NO MYSQL 8.X

**Autor:** Arley Ribeiro (DBA Júnior)  
**Objetivo:** Guia consolidado com o ajuste individual de cada arquivo de recurso (`config.cnf`, `backupfulldb.ps1`, `backupfullALLdb.ps1` e `backupLOGdb.ps1`) utilizado para automação de backups lógicos e logs binários no MySQL 8.x no Windows.  
**Referências:** MySQL 8.0 Reference Manual / mysqldump & Windows PowerShell  

---

## ESTRUTURA DOS ARQUIVOS NO REPOSITÓRIO


```

C:\mysqlapoio

├── config.cnf
├── backupfulldb.ps1
├── backupfullALLdb.ps1
├── backupLOGdb.ps1
└── backups

└── erros\

```

---

## ARQUIVO 1: `config.cnf` (Arquivo de Configuração e Credenciais)

**Caminho Absoluto:** `C:\mysqlapoio\config.cnf`

```ini
# ===============================================================================
#  ARQUIVO     : config.cnf
#  OBJETIVO    : Credenciais seguras para execução dos utilitários do MySQL
#  AUTOR       : Arley Ribeiro
# ===============================================================================

[mysqldump]
user=arleyribeiro
password=Arley@2026!MySQLPass

[mysqladmin]
user=arleyribeiro
password=Arley@2026!MySQLPass

[mysqlcheck]
user=arleyribeiro
password=Arley@2026!MySQLPass

```

---

## ARQUIVO 2: `backupfulldb.ps1` (Backup Full de Schema Específico)

**Caminho Absoluto:** `C:\mysqlapoio\backupfulldb.ps1`

```powershell
<#
===============================================================================
  ARQUIVO     : backupfulldb.ps1
  OBJETIVO    : Backup Lógico Full de Schema Específico + Compactação 7z + Purge
  AUTOR       : Arley Ribeiro
===============================================================================
#>

$backuppath = "C:\mysqlapoio\backups\"
$config     = "C:\mysqlapoio\config.cnf"
$database   = "arley_cliente2"
$errorLog   = "C:\mysqlapoio\backups\erros\error_dump_db.log"
$days       = 30

$date       = Get-Date
$timestamp  =$date.ToString("yyyyMMdd_HHmm")
$backupfile = Join-Path -Path $backuppath -ChildPath "$database`_$timestamp.sql"
$backupzip  = Join-Path -Path $backuppath -ChildPath "$database`_$timestamp.zip"

# Executa o dump lógico da base de dados especificada sem bloquear tabelas
mysqldump.exe --defaults-extra-file=$config --log-error=$errorLog --result-file=$backupfile --databases$database --single-transaction --flush-logs --routines --events

# Compacta o arquivo SQL utilizando o 7-Zip
7z.exe a -tzip $backupzip$backupfile

# Deleta o arquivo SQL original mantendo apenas o .zip
Remove-Item -Path $backupfile -Force

# Aplica a política de retenção excluindo backups antigos
$oldbackups = Get-ChildItem -Path$backuppath -Filter *.zip
foreach ($file in$oldbackups) {
    if ($file.CreationTime -lt $date.AddDays(-$days)) {
        Remove-Item -Path $file.FullName -Confirm:$false -Force
    }
}

```

---

## ARQUIVO 3: `backupfullALLdb.ps1` (Backup Full de Todos os Schemas)

**Caminho Absoluto:** `C:\mysqlapoio\backupfullALLdb.ps1`

```powershell
<#
===============================================================================
  ARQUIVO     : backupfullALLdb.ps1
  OBJETIVO    : Backup Lógico Full da Instância Completa + Compactação 7z + Purge
  AUTOR       : Arley Ribeiro
===============================================================================
#>

$backuppath = "C:\mysqlapoio\backups\"
$config     = "C:\mysqlapoio\config.cnf"
$database   = "AllBkDbs"
$errorLog   = "C:\mysqlapoio\backups\erros\error_dump_all.log"
$days       = 1

$date       = Get-Date
$timestamp  =$date.ToString("yyyyMMdd_HHmm")
$backupfile = Join-Path -Path $backuppath -ChildPath "$database`_$timestamp.sql"
$backupzip  = Join-Path -Path $backuppath -ChildPath "$database`_$timestamp.zip"

# Executa o dump lógico de todos os bancos de dados da instância
mysqldump.exe --defaults-extra-file=$config --log-error=$errorLog --result-file=$backupfile --all-databases --single-transaction --flush-logs --routines --events

# Compacta o arquivo SQL gerado utilizando o 7-Zip
7z.exe a -tzip $backupzip$backupfile

# Deleta o arquivo .sql original
Remove-Item -Path $backupfile -Force

# Expurgar backups antigos conforme o limite estipulado em $days
$oldbackups = Get-ChildItem -Path$backuppath -Filter *.zip
foreach ($file in$oldbackups) {
    if ($file.CreationTime -lt $date.AddDays(-$days)) {
        Remove-Item -Path $file.FullName -Confirm:$false -Force
    }
}

```

---

## ARQUIVO 4: `backupLOGdb.ps1` (Backup Incremental de Binlogs)

**Caminho Absoluto:** `C:\mysqlapoio\backupLOGdb.ps1`

```powershell
<#
===============================================================================
  ARQUIVO     : backupLOGdb.ps1
  OBJETIVO    : Rotação, Cópia e Compactação de Logs Binários (Point-in-Time)
  AUTOR       : Arley Ribeiro
===============================================================================
#>

$dadosoriginaispath = "C:\ProgramData\MySQL\MySQL Server 8.0\Data\*bin.*"
$backuppath         = "C:\mysqlapoio\backups\"
$config             = "C:\mysqlapoio\config.cnf"
$days               = 30

$date               = Get-Date
$timestamp          =$date.ToString("yyyyMMdd_HHmm")
$backupfile         = "C:\mysqlapoio\backups\*bin.*"
$backupzip          = Join-Path -Path $backuppath -ChildPath "BINLOGBK_$timestamp.zip"

# Força a reciclagem/rotação do log binário ativo no MySQL Server
mysqladmin.exe --defaults-extra-file=$config flush-logs

# Copia os arquivos de log binários fechados para a pasta de staging do backup
Copy-Item -Path $dadosoriginaispath -Destination$backuppath -Force

# Compacta os arquivos binlog copiados
7z.exe a -tzip $backupzip$backupfile

# Remove os arquivos binlog descompactados da pasta de backup
Remove-Item -Path $backupfile -Force

# Expurgar arquivos compactados de log binário antigos
$oldbackups = Get-ChildItem -Path$backuppath -Filter BINLOGBK_*.zip
foreach ($file in$oldbackups) {
    if ($file.CreationTime -lt $date.AddDays(-$days)) {
        Remove-Item -Path $file.FullName -Confirm:$false -Force
    }
}

```

---

## PARTE 5: ROTINA DE LIMPEZA E MANUTENÇÃO (CLEANUP)

Para limpar os arquivos criados nos testes do laboratório via PowerShell:

```powershell
# Executar no PowerShell como Administrador
Remove-Item -Path "C:\mysqlapoio\config.cnf" -Force
Remove-Item -Path "C:\mysqlapoio\*.ps1" -Force
Remove-Item -Path "C:\mysqlapoio\backups\*" -Recurse -Force

```

```

```