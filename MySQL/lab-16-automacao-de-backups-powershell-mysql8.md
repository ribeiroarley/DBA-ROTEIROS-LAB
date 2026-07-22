### Sugestão de Caminho e Nome do Arquivo

**Caminho:** `C:\Users\arsx_\Documents\DBA\dba-education-lab\02-setup-ambiente\scripts-automacao\`

**Arquivo:** `lab-16-automacao-de-backups-powershell-mysql8.md`

```markdown
# DBA EDUCATION LAB - AUTOMAÇÃO DE BACKUPS NO MYSQL 8.X COM POWERSHELL

**Autor:** Arley Ribeiro (DBA Júnior)  
**Objetivo:** Guia de referência técnica e documentação dos arquivos de recursos (`.ps1` e `.cnf`) para automação de backups lógicos (Full por Schema, Full da Instância e Binlog/Incremental) e compactação no MySQL 8.x no Windows.  
**Referências:** MySQL 8.0 Reference Manual / mysqldump / Windows PowerShell Automation  

---

## PARTE 1: ESTRUTURA DE DIRETÓRIOS E CONFIGURAÇÃO DE SEGURANÇA

Para garantir o correto funcionamento dos scripts sem expor credenciais em texto puro nas chamadas de terminal, crie a seguinte estrutura de diretórios no Windows:

```cmd
C:\mysqlapoio\
├── config.cnf
├── backupfulldb.ps1
├── backupfullALLdb.ps1
├── backupLOGdb.ps1
└── backups\
    └── erros\

```

### Arquivo de Credenciais (`C:\mysqlapoio\config.cnf`)

> **Atenção de Segurança:** Restrinja as permissões de leitura deste arquivo no Windows Explorer apenas para a conta de serviço/administrador.

```ini
[mysqldump]
user=arleyribeiro
password=SuaSenhaSegura2026!

[mysqladmin]
user=arleyribeiro
password=SuaSenhaSegura2026!

```

---

## PARTE 2: SCRIPT DE BACKUP FULL DE BANCO ESPECÍFICO (`backupfulldb.ps1`)

Este script realiza o backup lógico completo de um único schema sem bloquear tabelas (`--single-transaction`), realiza rotação de logs binários, compacta o arquivo `.sql` gerado em `.zip` via 7-Zip e aplica retenção expurgando backups antigos.

```powershell
<#
===============================================================================
  Arquivo     : backupfulldb.ps1
  Objetivo    : Backup Full Lógico de Schema Específico + Compactação 7z + Purge
  Autor       : Arley Ribeiro
===============================================================================
#>

$backuppath = "C:\mysqlapoio\backups\"
$config     = "C:\mysqlapoio\config.cnf"
$database   = "arley_cliente2"
$errorLog   = "C:\mysqlapoio\backups\erros\error_dump.log"
$days       = 30

$date       = Get-Date
$timestamp  = $date.ToString("yyyyMMdd_HHmm")
$backupfile = "$backuppath$database`_$timestamp.sql"
$backupzip  = "$backuppath$database`_$timestamp.zip"

# Executa o dump lógico da base especificada
mysqldump.exe --defaults-extra-file=$config --log-error=$errorLog --result-file=$backupfile --databases $database --single-transaction --flush-logs --routines --events

# Compacta o arquivo SQL gerado utilizando o 7-Zip
7z.exe a -tzip $backupzip $backupfile

# Remove o arquivo .sql não compactado
Remove-Item $backupfile -Force

# Aplica a política de retenção removendo backups compactados mais antigos que $days
$oldbackups = Get-ChildItem -Path $backuppath -Filter *.zip
foreach ($file in $oldbackups) {
    if ($file.CreationTime -lt $date.AddDays(-$days)) {
        Remove-Item $file.FullName -Confirm:$false -Force
    }
}

```

---

## PARTE 3: SCRIPT DE BACKUP FULL DE TODAS AS BASES (`backupfullALLdb.ps1`)

Este script realiza o backup de todas as bases de dados da instância MySQL, incluindo dicionário, rotinas e eventos armazenados.

```powershell
<#
===============================================================================
  Arquivo     : backupfullALLdb.ps1
  Objetivo    : Backup Full Lógico de Todos os Schemas + Compactação 7z + Purge
  Autor       : Arley Ribeiro
===============================================================================
#>

$backuppath = "C:\mysqlapoio\backups\"
$config     = "C:\mysqlapoio\config.cnf"
$database   = "AllBkDbs"
$errorLog   = "C:\mysqlapoio\backups\erros\error_dump_all.log"
$days       = 30

$date       = Get-Date
$timestamp  = $date.ToString("yyyyMMdd_HHmm")
$backupfile = "$backuppath$database`_$timestamp.sql"
$backupzip  = "$backuppath$database`_$timestamp.zip"

# Executa o dump lógico de toda a instância
mysqldump.exe --defaults-extra-file=$config --log-error=$errorLog --result-file=$backupfile --all-databases --single-transaction --flush-logs --routines --events

# Compacta o dump da instância
7z.exe a -tzip $backupzip $backupfile

# Remove o arquivo SQL original
Remove-Item $backupfile -Force

# Expurgo de backups antigos
$oldbackups = Get-ChildItem -Path $backuppath -Filter *.zip
foreach ($file in $oldbackups) {
    if ($file.CreationTime -lt $date.AddDays(-$days)) {
        Remove-Item $file.FullName -Confirm:$false -Force
    }
}

```

---

## PARTE 4: SCRIPT DE BACKUP INCREMENTAL DE BINLOGS (`backupLOGdb.ps1`)

Este script força o fechamento e reciclagem do log binário ativo (`flush-logs`) e realiza a cópia e compactação dos binlogs consolidados para o diretório de destino.

```powershell
<#
===============================================================================
  Arquivo     : backupLOGdb.ps1
  Objetivo    : Rotação, Cópia e Compactação de Logs Binários (Point-in-Time)
  Autor       : Arley Ribeiro
===============================================================================
#>

$dadosoriginaispath = "C:\ProgramData\MySQL\MySQL Server 8.0\Data\*bin.*"
$backuppath         = "C:\mysqlapoio\backups\"
$config             = "C:\mysqlapoio\config.cnf"
$days               = 30

$date               = Get-Date
$timestamp          = $date.ToString("yyyyMMdd_HHmm")
$backupfile         = "C:\mysqlapoio\backups\*bin.*"
$backupzip          = "$backuppath`BINLOGBK_$timestamp.zip"

# Força a reciclagem do binlog atual
mysqladmin.exe --defaults-extra-file=$config flush-logs

# Copia os logs binários fechados para o diretório de staging de backup
Copy-Item -Path $dadosoriginaispath -Destination$backuppath -Force

# Compacta os arquivos binlog copiados
7z.exe a -tzip $backupzip$backupfile

# Limpa os arquivos descompactados do diretório de backup
Remove-Item -Path $backupfile -Force

# Expurgar pacotes de log binário compactados antigos
$oldbackups = Get-ChildItem -Path$backuppath -Filter BINLOGBK_*.zip
foreach ($file in$oldbackups) {
    if ($file.CreationTime -lt $date.AddDays(-$days)) {
        Remove-Item $file.FullName -Confirm:$false -Force
    }
}

```

---

## PARTE 5: AGENDAMENTO NO WINDOWS TASK SCHEDULER

Para agendar a execução automática dos scripts no Windows, abra o **Agendador de Tarefas** e configure as Ações conforme abaixo:

1. **Backup Full Diário (00:00):**
* **Programa/script:** `powershell.exe`
* **Argumentos:** `-ExecutionPolicy RemoteSigned -File "C:\mysqlapoio\backupfullALLdb.ps1"`


2. **Backup Incremental de Binlogs (A cada 1 hora):**
* **Programa/script:** `powershell.exe`
* **Argumentos:** `-ExecutionPolicy RemoteSigned -File "C:\mysqlapoio\backupLOGdb.ps1"`



---

## PARTE 6: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)

Caso deseje remover a estrutura e os agendamentos criados:

```powershell
# Executar no PowerShell como Administrador para remover os arquivos gerados no lab:
Remove-Item -Path "C:\mysqlapoio\backups\*" -Recurse -Force
Remove-Item -Path "C:\mysqlapoio\*.ps1" -Force
Remove-Item -Path "C:\mysqlapoio\config.cnf" -Force

```

```

```