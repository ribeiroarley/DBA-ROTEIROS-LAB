```markdown
/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-21-manutencao-integridade-mysqlcheck-mysql8.md
  Objetivo     : Guia prático de manutenção de integridade, checagem e reparo de 
                 tabelas com o utilitário mysqlcheck no MySQL 8.x, incluindo 
                 recuperação emergencial InnoDB, gerenciamento de credenciais 
                 seguras e script Batch automatizado com política de purge.
  Autor        : Arley Ribeiro (DBA Júnior)
  Referencias  : MySQL 8.0 Reference Manual / mysqlcheck Utility & InnoDB Recovery
*******************************************************************************/

# DBA EDUCATION LAB - INTEGRIDADE, MANUTENÇÃO E REPARO COM MYSQLCHECK NO MYSQL 8.X

---

## PARTE 1: EXECUÇÃO DE CHECAGENS VIA LINHA DE COMANDO (CLI)

Abaixo estão dispostos os comandos para verificação, auditoria física e análise do dicionário de dados através da CLI do Windows (cmd.exe ou PowerShell)[cite: 16]:

```cmd
REM 1. Checagem padrão de todas as tabelas de um schema específico
mysqlcheck.exe --login-path=arley_bk_profile arley_cliente2

REM 2. Checagem específica das tabelas 'order' e 'product'
mysqlcheck.exe --login-path=arley_bk_profile arley_cliente2 order product

REM 3. Checagem estendida (Deep Check) em múltiplos schemas
mysqlcheck.exe --login-path=arley_bk_profile --extended --databases arley_cliente2 arley_clube

REM 4. Checagem geral de integridade em todas as bases da instância
mysqlcheck.exe --login-path=arley_bk_profile --all-databases

```

---

## PARTE 2: DDL DE SUPORTE PARA RECUPERAÇÃO EM TABELAS INNODB

Caso uma tabela sob a engine InnoDB apresente inconformidade física e necessite de tratamento DDL temporário para reparo legado ou reconversão de metadados:

```sql
/*******************************************************************************
  SEÇÃO SQL: SUPORTE À MANUTENÇÃO E ALTERAÇÃO DE STORAGE ENGINE
*******************************************************************************/

USE arley_cliente2;

-- Desativar temporariamente a verificação de chaves estrangeiras
SET FOREIGN_KEY_CHECKS = 0;

-- Alteração temporária para MyISAM (Caso seja estritamente necessário utilizar mysqlcheck -r)
ALTER TABLE arley_cliente2.account ENGINE = MyISAM;

-- (Neste momento, executa-se na CLI: mysqlcheck -r arley_cliente2 account)

-- Restauração obrigatória da tabela para a engine padrão InnoDB do MySQL 8.x
ALTER TABLE arley_cliente2.account ENGINE = InnoDB;

-- Reativar a verificação de chaves estrangeiras
SET FOREIGN_KEY_CHECKS = 1;

```

---

## PARTE 3: ARQUIVOS DE RECURSO DA AUTOMAÇÃO

### Arquivo 1: `C:\mysqlapoio\config.cnf` (Configuração do Utilitário)

```ini
# ===============================================================================
#  ARQUIVO     : C:\mysqlapoio\config.cnf
#  OBJETIVO    : Credenciais centralizadas para utilitários do MySQL
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

### Arquivo 2: `C:\mysqlapoio\checkdb.bat` (Script Batch de Auditoria)

```cmd
@echo off
REM ===============================================================================
REM  ARQUIVO     : checkdb.bat
REM  OBJETIVO    : Auditoria Automatizada com Log Temporizado e Purge de 15 Dias
REM  AUTOR       : Arley Ribeiro
REM ===============================================================================

REM Captura da data e hora formatada em ISO (YYYYMMDD_HHMM) via WMIC
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YYYY=%dt:~0,4%"
set "MM=%dt:~4,2%"
set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%"
set "Min=%dt:~10,2%"

set "dirname=%YYYY%%MM%%DD%_%HH%%Min%"

set "configfile=C:\mysqlapoio\config.cnf"
set "logdir=C:\mysqlapoio\logcheckdb"
set "logfile=%logdir%\checkdb_%dirname%.txt"

REM Garantir a existência do diretório de logs
if not exist "%logdir%" mkdir "%logdir%"

REM Executar auditoria de consistência em todas as bases gravando o relatório de saída
mysqlcheck.exe --defaults-file="%configfile%" --all-databases > "%logfile%"

REM Expurgo automático de relatórios de integridade com mais de 15 dias
forfiles /p "%logdir%" /s /m *.txt /D -15 /C "cmd /c del /q /f @path"

```

---

## PARTE 4: AGENDAMENTO DE TAREFA NO WINDOWS (TASK SCHEDULER)

Comando para agendar a rotina de verificação no Prompt de Comando como Administrador:

```cmd
REM Criar tarefa para rodar semanalmente aos domingos às 03:00 da manhã:
schtasks /create /tn "MySQL_Integrity_Check_Arley" /tr "C:\mysqlapoio\checkdb.bat" /sc weekly /d SUN /st 03:00 /ru "SYSTEM"

```

---

## PARTE 5: PROCEDIMENTO DE EMERGÊNCIA (FORCED INNODB RECOVERY)

Em cenários de *crash* crítico onde a instância falha ao inicializar o InnoDB, configure o arquivo `my.ini`:

```ini
[mysqld]
# Nível recomendado de recuperação para inicialização de diagnóstico: 1 a 4
innodb_force_recovery = 3

```

1. **Reinicie o serviço do MySQL** (A instância iniciará em modo Somente Leitura / Read Only).


2. **Execute a extração emergencial de dump:**
```cmd
mysqldump.exe --defaults-extra-file="C:\mysqlapoio\config.cnf" --all-databases > "C:\mysqlapoio\emergency_dump.sql"

```


3. **Remova a instrução `innodb_force_recovery**` do `my.ini` e reinicie o serviço.


4. **Recrie as estruturas danificadas** importando o dump gerado.



---

## PARTE 6: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)

Comandos para remover os scripts, diretórios de log e tarefas agendadas de teste:

```cmd
REM Executar no Prompt de Comando (cmd.exe) como Administrador:
schtasks /delete /tn "MySQL_Integrity_Check_Arley" /f
del /q /f "C:\mysqlapoio\checkdb.bat"
del /q /f "C:\mysqlapoio\config.cnf"
rmdir /s /q "C:\mysqlapoio\logcheckdb"

```

```

```