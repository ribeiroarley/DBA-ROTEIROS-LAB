@echo off
:: /*******************************************************************************
::   REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
::   Arquivo      : lab-16-bk.bat
::   Objetivo     : Script batch para backup logico basico
::   Autor        : Arley Ribeiro (DBA Júnior)
::   Referências  : MySQL 8.0 Reference Manual
:: *******************************************************************************/

if not exist "C:\mysqlapoio\backups\" mkdir "C:\mysqlapoio\backups\"

for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "dirname=%dt:~6,2%_%dt:~4,2%_%dt:~2,2%_%dt:~8,2%%dt:~10,2%"
 
set workdir=C:\mysqlapoio\backups\
set mysqldb=teste
 
:: Utilizando variaveis seguras via environment ou mysql_config_editor é recomendado.
:: Aqui utilizamos a configuracao basica, recomendando o uso de .cnf ou login-path
mysqldump --defaults-extra-file=C:\mysqlapoio\config.cnf %mysqldb% > %workdir%\bk_%dirname%.sql

if %ERRORLEVEL% NEQ 0 (
    echo Erro ao realizar backup
    exit /b %ERRORLEVEL%
)

7z.exe a -tzip %workdir%\bk_%dirname%.zip %workdir%\bk_%dirname%.sql
if exist %workdir%\bk_%dirname%.zip (
    del %workdir%\bk_%dirname%.sql
)
