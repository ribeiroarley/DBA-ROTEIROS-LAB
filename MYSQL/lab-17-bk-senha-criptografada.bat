@echo off
:: /*******************************************************************************
::   REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
::   Arquivo      : lab-17-bk-senha-criptografada.bat
::   Objetivo     : Backup logico usando senha criptografada via login-path
::   Autor        : Arley Ribeiro (DBA Júnior)
::   Referências  : MySQL 8.0 Reference Manual
:: *******************************************************************************/

if not exist "C:\mysqlapoio\backups\" mkdir "C:\mysqlapoio\backups\"

for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "dirname=%dt:~6,2%_%dt:~4,2%_%dt:~2,2%_%dt:~8,2%%dt:~10,2%"
 
set workdir=C:\mysqlapoio\backups\
set mysqldb=teste
 
:: Usando login-path criptografado
mysqldump --login-path=backup_user %mysqldb% > %workdir%\bk_%dirname%.sql

if %ERRORLEVEL% NEQ 0 (
    echo Erro ao realizar backup
    exit /b %ERRORLEVEL%
)

7z.exe a -tzip %workdir%\bk_%dirname%.zip %workdir%\bk_%dirname%.sql
if exist %workdir%\bk_%dirname%.zip (
    del %workdir%\bk_%dirname%.sql
)
