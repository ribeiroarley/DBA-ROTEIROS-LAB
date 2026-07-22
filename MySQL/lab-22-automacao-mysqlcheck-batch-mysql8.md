### Sugestão de Caminho e Nome do Arquivo

**Caminho:** `C:\Users\arsx_\Documents\DBA\dba-education-lab\02-setup-ambiente\scripts-automacao\`

**Arquivo:** `lab-22-automacao-mysqlcheck-batch-mysql8.md`

```markdown
/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-22-automacao-mysqlcheck-batch-mysql8.md
  Objetivo     : Roteiro prático para automação de auditoria de integridade e 
                 manutenção de tabelas no MySQL 8.x utilizando script Batch (.bat) 
                 no Windows, com arquivo de opções seguro, timestamp ISO 
                 e purga automática de relatórios antigos.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / mysqlcheck Utility & Windows CMD
*******************************************************************************/

# DBA EDUCATION LAB - AUTOMAÇÃO DE AUDITORIA DE INTEGRIDADE COM MYSQLCHECK

---

## PARTE 1: ARQUIVO DE CONFIGURAÇÃO DE CREDENCIAIS (C:\mysqlapoio\config.cnf)

Para prevenir a exposição de senhas e evitar avisos de segurança na execução agendada, utilize o arquivo de opções centralizado[cite: 16]:

```ini
# ===============================================================================
#  ARQUIVO     : C:\mysqlapoio\config.cnf
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

## PARTE 2: SCRIPT BATCH OTIMIZADO (C:\mysqlapoio\checkdb.bat)

Script em lote atualizado para extração de data/hora no padrão ISO (`YYYYMMDD_HHMM`), execução do `mysqlcheck` com opções explícitas de segurança e remoção de relatórios antigos via `forfiles`:

```cmd
@echo off
REM ===============================================================================
REM  ARQUIVO     : checkdb.bat
REM  OBJETIVO    : Auditoria Automatizada com Log Temporizado e Purge de 15 Dias
REM  AUTOR       : Arley Ribeiro
REM ===============================================================================

REM Captura da data e hora formatada em ISO (YYYYMMDD_HHMM) via WMIC
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"[cite: 16]
set "YYYY=%dt:~0,4%"[cite: 16]
set "MM=%dt:~4,2%"[cite: 16]
set "DD=%dt:~6,2%"[cite: 16]
set "HH=%dt:~8,2%"[cite: 16]
set "Min=%dt:~10,2%"[cite: 16]

set "dirname=%YYYY%%MM%%DD%_%HH%%Min%"[cite: 16]

set "configfile=C:\mysqlapoio\config.cnf"[cite: 16]
set "logdir=C:\mysqlapoio\logcheckdb"[cite: 16]
set "logfile=%logdir%\checkdb_%dirname%.txt"[cite: 16]

REM Garantir a existência do diretório de destino dos relatórios
if not exist "%logdir%" mkdir "%logdir%"

REM Executar verificação de integridade em todas as bases da instância
mysqlcheck.exe --defaults-file="%configfile%" --all-databases > "%logfile%"[cite: 16]

REM Expurgo automático de relatórios com retenção superior a 15 dias
forfiles /p "%logdir%" /s /m *.txt /D -15 /C "cmd /c del /q /f @path"[cite: 16]

```

---

## PARTE 3: AGENDAMENTO NO WINDOWS TASK SCHEDULER

Para agendar a execução da auditoria sem intervenção humana, execute o comando abaixo no Prompt de Comando (`cmd.exe`) como Administrador:

```cmd
REM Criar tarefa agendada semanal para os domingos às 03:00 da manhã:
schtasks /create /tn "MySQL_Integrity_Check_Arley" /tr "C:\mysqlapoio\checkdb.bat" /sc weekly /d SUN /st 03:00 /ru "SYSTEM"

```

---

## PARTE 4: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)

Comandos para remover os scripts, diretórios de logs e agendamentos de teste criados no laboratório:

```cmd
REM Executar no Prompt de Comando (cmd.exe) como Administrador:
schtasks /delete /tn "MySQL_Integrity_Check_Arley" /f
del /q /f "C:\mysqlapoio\checkdb.bat"
del /q /f "C:\mysqlapoio\config.cnf"
rmdir /s /q "C:\mysqlapoio\logcheckdb"

```

```

```