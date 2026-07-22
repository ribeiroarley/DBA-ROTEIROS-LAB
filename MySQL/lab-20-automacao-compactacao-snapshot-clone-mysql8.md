### Sugestão de Caminho e Nome do Arquivo

**Caminho:** `C:\Users\arsx_\Documents\DBA\dba-education-lab\02-setup-ambiente\scripts-automacao\`

**Arquivo:** `lab-20-automacao-compactacao-snapshot-clone-mysql8.md`

```markdown
# DBA EDUCATION LAB - AUTOMAÇÃO DE COMPACTAÇÃO E EXPURGO DE SNAPSHOTS DO PLUGIN CLONE NO MYSQL 8.X

**Autor:** Arley Ribeiro (DBA Júnior)  
**Objetivo:** Guia prático para execução de scripts em lote Batch (.bat) no Windows destinados a integrar com o Plugin Clone do MySQL 8.x[cite: 20]. O script extrai a data/hora atual do sistema operacional via WMIC, realiza a compactação `.7z` do diretório temporário do snapshot criado pelo evento do MySQL, move o arquivo compactado para a pasta definitiva de armazenamento de segurança e executa a limpeza dos arquivos temporários para permitir execuções subsequentes sem conflitos no MySQL[cite: 20].  
**Referências:** MySQL 8.0 Reference Manual / The Clone Plugin & Windows Command Shell (cmd.exe)  

---

## PARTE 1: ESTRUTURA DE DIRETÓRIOS E PRÉ-REQUISITOS

Para a correta execução deste fluxo automatizado, garanta que os seguintes diretórios existam e que o utilitário **7-Zip** (`7z.exe`) esteja registrado no `%PATH%` das variáveis de ambiente do Windows:

```cmd
C:\mysqlapoio\
├── clonebackup\                      <-- Diretório temporário gerado pelo MySQL (CLONE LOCAL DATA DIRECTORY)
└── backups\
    └── BACKUPS_PluginClone\          <-- Repositório definitivo de snapshots compactados

```

---

## PARTE 2: SCRIPT BATCH OTIMIZADO (C:\mysqlapoio\bkPluginClone.bat)

Script em lote padronizado para tratamento seguro de strings de caminho, formato de data/hora ISO (`YYYYMMDD_HHMM`) e expurgo limpo do diretório temporário do clone:

```cmd
@echo off
REM ===============================================================================
REM  ARQUIVO     : bkPluginClone.bat
REM  OBJETIVO    : Compactação do Snapshot Físico do Plugin Clone + Limpeza
REM  AUTOR       : Arley Ribeiro
REM ===============================================================================

REM Captura da data e hora formatada (YYYYMMDD_HHMM) via WMIC
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"[cite: 20]
set "YYYY=%dt:~0,4%"[cite: 20]
set "MM=%dt:~4,2%"[cite: 20]
set "DD=%dt:~6,2%"[cite: 20]
set "HH=%dt:~8,2%"[cite: 20]
set "Min=%dt:~10,2%"[cite: 20]

set "dirname=%YYYY%%MM%%DD%_%HH%%Min%"[cite: 20]

REM Definição de diretórios de trabalho
set "workdir=C:\mysqlapoio\clonebackup"[cite: 20]
set "BKclonedir=C:\mysqlapoio\backups\BACKUPS_PluginClone"[cite: 20]
set "archiveName=cloneBK_%dirname%.7z"[cite: 20]

REM Validação da existência do diretório temporário de snapshot gerado pelo MySQL
if not exist "%workdir%" (
    echo [ALERTA] Diretório %workdir% não encontrado. Aguardando execução do Plugin Clone.
    exit /b 0
)

REM Garantir a existência do diretório de destino definitivo
if not exist "%BKclonedir%" mkdir "%BKclonedir%"[cite: 20]

REM Iniciar a compactação do diretório de snapshot utilizando o 7-Zip
7z.exe a -t7z "%archiveName%" "%workdir%\"[cite: 20]

REM Mover o arquivo compactado para o repositório definitivo
move /y "%archiveName%" "%BKclonedir%\"[cite: 20]

REM Limpeza do diretório temporário do snapshot para permitir novos eventos de clone sem erro
if exist "%BKclonedir%\%archiveName%" (
    del /q /f "%workdir%\*.*"[cite: 20]
    for /d %%p in ("%workdir%\*") do rmdir /s /q "%%p"[cite: 20]
    rmdir /s /q "%workdir%"[cite: 20]
)

echo Compactação e limpeza do clone finalizadas com sucesso: %BKclonedir%\%archiveName%

```

---

## PARTE 3: INTEGRAÇÃO COM EVENT SCHEDULER DO MYSQL E TASK SCHEDULER

O processo de clonagem física local do MySQL 8.x bloqueia novas execuções se o diretório de destino já existir. O fluxo de automação deve seguir a seguinte ordem temporal:

1. **Evento no MySQL Server (Executa o snapshot físico):**
```sql
USE sys;

-- O evento gera a pasta física C:\mysqlapoio\clonebackup
CREATE EVENT IF NOT EXISTS ev_executa_clone_local
    ON SCHEDULE EVERY 1 DAY
    STARTS '2026-07-22 02:00:00'
    DO
        CLONE LOCAL DATA DIRECTORY = 'C:\\mysqlapoio\\clonebackup';

```


2. **Tarefa Agendada no Windows (Executa o script Batch de movimentação/limpeza):**
* **Horário:** Configurar para executar 30 minutos após o início do evento MySQL (ex: 02:30:00).
* **Comando CMD:**
```cmd
schtasks /create /tn "MySQL_Clone_Compress_Arley" /tr "C:\mysqlapoio\bkPluginClone.bat" /sc daily /st 02:30 /ru "SYSTEM"

```





---

## PARTE 4: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)

Comandos para remover a estrutura de pastas, scripts e agendamentos de teste:

```cmd
REM Executar no Prompt de Comando (cmd.exe) como Administrador:
schtasks /delete /tn "MySQL_Clone_Compress_Arley" /f
del /q /f "C:\mysqlapoio\bkPluginClone.bat"
rmdir /s /q "C:\mysqlapoio\backups\BACKUPS_PluginClone"
rmdir /s /q "C:\mysqlapoio\clonebackup"

```

```sql
-- Executar no MySQL Workbench para remover o evento agendado:
DROP EVENT IF EXISTS sys.ev_executa_clone_local;

```

```

```