@echo off
:: /*******************************************************************************
::   REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
::   Arquivo      : lab-18-bk-plugin-clone.bat
::   Objetivo     : Automacao de compactacao para clone do banco (Plugin Clone)
::   Autor        : Arley Ribeiro (DBA Júnior)
::   Referências  : MySQL 8.0 Reference Manual
:: *******************************************************************************/

set workdir=C:\mysqlapoio\clonebackup\
set BKclonedir=C:\mysqlapoio\backups\BACKUPS_PluginClone\

if not exist "%BKclonedir%" mkdir "%BKclonedir%"
if not exist "%workdir%" (
    echo Pasta clone nao existe
    exit /b 1
)

for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "dirname=%dt:~6,2%_%dt:~4,2%_%dt:~2,2%_%dt:~8,2%%dt:~10,2%"

7z.exe a -t7z %BKclonedir%\cloneBK%dirname%.7z %workdir%\

if %ERRORLEVEL% EQU 0 (
    del /q /f %workdir%\*.*
    rd /q /s %workdir%
) else (
    echo Erro ao compactar clone
)
