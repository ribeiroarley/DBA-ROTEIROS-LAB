### Sugestão de Caminho e Nome do Arquivo

**Caminho:** `C:\Users\arsx_\Documents\DBA\dba-education-lab\02-setup-ambiente\scripts-automacao\`

**Arquivo:** `lab-19-seguranca-login-path-mysql_config_editor-mysql8.md`

```markdown
# DBA EDUCATION LAB - AUTOMAÇÃO DE BACKUP COM LOGIN-PATH CRIPTOGRAFADO (MYSQL_CONFIG_EDITOR)

**Autor:** Arley Ribeiro (DBA Júnior)[cite: 19]  
**Objetivo:** Roteiro prático para configuração do utilitário `mysql_config_editor`, eliminando senhas em texto claro de scripts Batch (.bat) e PowerShell (.ps1) no Windows[cite: 19]. Utiliza o arquivo seguro de credenciais obfustacadas `.mylogin.cnf` via `--login-path` para autenticação nos utilitários `mysql` e `mysqldump`[cite: 18, 19].  
**Referências:** MySQL 8.0 Reference Manual / mysql_config_editor & mysqldump[cite: 19]  

---

## PARTE 1: CRIAÇÃO DO USUÁRIO DE BACKUP COM MENOR PRIVILÉGIO (POLE)

Em vez de expor a conta `root`, cria-se um usuário dedicado exclusivamente a rotinas de backup[cite: 19]:

```sql
/*******************************************************************************
  SEÇÃO SQL: CRIAÇÃO DO USUÁRIO E CONCESSÃO DE PRIVILÉGIOS DE BACKUP
*******************************************************************************/

-- Criar o usuário de backup restrito ao acesso local
CREATE USER IF NOT EXISTS 'arley_backup'@'localhost' 
IDENTIFIED WITH caching_sha2_password BY 'Arley@2026!BkPass';[cite: 19]

-- Conceder permissões globais necessárias para dumps sem bloqueios e consistente
GRANT RELOAD, SUPER, PROCESS, REPLICATION CLIENT, LOCK TABLES, SHOW DATABASES
ON *.* TO 'arley_backup'@'localhost';[cite: 19]

-- Conceder permissões para leitura de tabelas de metadados e performance
GRANT SELECT ON performance_schema.* TO 'arley_backup'@'localhost';[cite: 19]
GRANT SELECT ON mysql.* TO 'arley_backup'@'localhost';[cite: 19]

FLUSH PRIVILEGES;

```

---

## PARTE 2: CONFIGURAÇÃO DO LOGIN-PATH CRIPTOGRAFADO (CMD)

Executar no Prompt de Comando (cmd.exe) para criar o perfil de conexão cifrado no arquivo `%APPDATA%\MySQL\.mylogin.cnf`:

```cmd
REM 1. Listar perfis de login atualmente salvos
mysql_config_editor print --all[cite: 19]

REM 2. Criar perfil cifrado 'arley_bk_profile' para a conta de backup
mysql_config_editor set --login-path=arley_bk_profile --host=localhost --user=arley_backup --password[cite: 19]
REM (Digite a senha quando solicitado pelo prompt seguro)

REM 3. Validar a criação do perfil criptografado
mysql_config_editor print --login-path=arley_bk_profile[cite: 19]

REM 4. Testar a conexão com o MySQL sem informar usuário ou senha na CLI
mysql --login-path=arley_bk_profile -e "SELECT USER(), CURRENT_USER();"[cite: 19]

```

---

## PARTE 3: SCRIPT BATCH OTIMIZADO USANDO LOGIN-PATH (C:\mysqlapoio\bk_seguro.bat)

Script em lote adaptado para extração de timestamp via WMIC, eliminação de parâmetros de credencial e uso exclusivo do `--login-path`:

```cmd
@echo off
REM ===============================================================================
REM  ARQUIVO     : bk_seguro.bat
REM  OBJETIVO    : Backup Lógico Seguro via --login-path (Sem Senhas Expostas)
REM  AUTOR       : Arley Ribeiro
REM ===============================================================================

REM Captura da data e hora formatada (YYYYMMDD_HHMM)
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"[cite: 18, 19]
set "YYYY=%dt:~0,4%"[cite: 18, 19]
set "MM=%dt:~4,2%"[cite: 18, 19]
set "DD=%dt:~6,2%"[cite: 18, 19]
set "HH=%dt:~8,2%"[cite: 18, 19]
set "Min=%dt:~10,2%"[cite: 18, 19]

set "dirname=%YYYY%%MM%%DD%_%HH%%Min%"[cite: 18, 19]

set "workdir=C:\mysqlapoio\backups"[cite: 18, 19]
set "mysqldb=arley_cliente2"[cite: 18, 19]
set "sqlfile=%workdir%\bk_%mysqldb%_%dirname%.sql"[cite: 18, 19]
set "zipfile=%workdir%\bk_%mysqldb%_%dirname%.zip"[cite: 18, 19]

if not exist "%workdir%" mkdir "%workdir%"

REM Executar mysqldump utilizando a conexão cifrada do perfil
mysqldump.exe --login-path=arley_bk_profile --single-transaction --flush-logs --routines --events %mysqldb% > "%sqlfile%"[cite: 18, 19]

REM Compactar o arquivo gerado via 7-Zip
7z.exe a -tzip "%zipfile%" "%sqlfile%"[cite: 18, 19]

REM Remover o dump SQL temporário não compactado
if exist "%zipfile%" del /q /f "%sqlfile%"[cite: 18, 19]

```

---

## PARTE 4: AGENDAMENTO SEGURO DA TAREFA (TASK SCHEDULER)

Para agendar o script seguro via linha de comando:

```cmd
schtasks /create /tn "MySQL_Backup_LoginPath_Arley" /tr "C:\mysqlapoio\bk_seguro.bat" /sc daily /st 01:00 /ru "SYSTEM"

```

---

## PARTE 5: ROTINA DE LIMPEZA DO LABORATÓRIO (CLEANUP)

Comandos para remover o perfil de conexão, script e artefatos criados no laboratório:

```cmd
REM 1. Remover o login-path cifrado do registro do usuário no Windows
mysql_config_editor remove --login-path=arley_bk_profile[cite: 19]

REM 2. Excluir o script Batch e os backups de teste
del /q /f "C:\mysqlapoio\bk_seguro.bat"
del /q /f "C:\mysqlapoio\backups\bk_arley_cliente2_*.zip"

REM 3. Apagar a tarefa agendada
schtasks /delete /tn "MySQL_Backup_LoginPath_Arley" /f

```

```sql
-- 4. Excluir o usuário de backup do banco de dados MySQL
DROP USER IF EXISTS 'arley_backup'@'localhost';

```

```

```