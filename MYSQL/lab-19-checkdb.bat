@echo off
:: /*******************************************************************************
::   REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
::   Arquivo      : lab-19-checkdb.bat
::   Objetivo     : Execucao automatizada do utilitario mysqlcheck
::   Autor        : Arley Ribeiro (DBA Júnior)
::   Referências  : MySQL 8.0 Reference Manual
:: *******************************************************************************/

set logdir=C:\mysqlapoio\logcheckdb\
if not exist "%logdir%" mkdir "%logdir%"

for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "dirname=%dt:~6,2%_%dt:~4,2%_%dt:~2,2%_%dt:~8,2%%dt:~10,2%"
 
mysqlcheck --defaults-file=C:\mysqlapoio\config.cnf --all-databases > %logdir%\checkdb%dirname%.txt

if exist "forfiles.exe" (
    forfiles /p "%logdir%" /s /m *.* /D -15 /C "cmd /c del @path"
)
