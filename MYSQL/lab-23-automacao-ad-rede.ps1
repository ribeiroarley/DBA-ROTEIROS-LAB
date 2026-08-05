<#
/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-23-automacao-ad-rede.ps1
  Objetivo     : Automação de rede, discos e criação de conta de serviço no AD
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : MySQL 8.0 Reference Manual / Microsoft Windows Server Docs
*******************************************************************************/
#>

# Requer privilegios administrativos
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Este script requer privilegios de Administrador. Execute o PowerShell como Administrador."
    exit
}

# Importar modulo do Active Directory
Import-Module ActiveDirectory -ErrorAction Stop

# ==============================================================================
# FUNCAO: Configurar IP Estatico
# ==============================================================================
function Set-StaticIP {
    param (
        [string]$InterfaceAlias = "Ethernet",
        [string]$IPAddress = "192.168.10.100",
        [int]$PrefixLength = 24,
        [string]$DefaultGateway = "192.168.10.1",
        [string]$DNSServer = "192.168.10.10"
    )
    
    Write-Output "Iniciando configuracao de rede para a interface: $InterfaceAlias"
    
    try {
        Get-NetAdapter -Name $InterfaceAlias -ErrorAction Stop | Out-Null
        
        # Remove configuracoes existentes e desabilita DHCP
        Remove-NetIPAddress -InterfaceAlias $InterfaceAlias -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceAlias $InterfaceAlias -Confirm:$false -ErrorAction SilentlyContinue
        
        Write-Output "Aplicando IP estatico: $IPAddress/$PrefixLength"
        New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IPAddress -PrefixLength $PrefixLength -DefaultGateway $DefaultGateway -ErrorAction Stop | Out-Null
        
        Write-Output "Aplicando servidor DNS: $DNSServer"
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $DNSServer -ErrorAction Stop
        
        Write-Output "Configuracao de rede concluida com exito."
    }
    catch {
        Write-Error "Falha ao configurar rede. Detalhes: $($_.Exception.Message)"
    }
}

# ==============================================================================
# FUNCAO: Inicializar e Formatar Discos para Banco de Dados
# ==============================================================================
function Initialize-DatabaseDisks {
    Write-Output "Iniciando preparacao de discos para o Banco de Dados..."
    
    try {
        # Busca discos raw (nao inicializados)
        $rawDisks = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' }
        
        if ($rawDisks.Count -eq 0) {
            Write-Output "Nenhum disco novo (RAW) localizado para inicializacao."
            return
        }
        
        foreach ($disk in $rawDisks) {
            Write-Output "Inicializando disco $($disk.Number)..."
            
            # Inicializa como GPT, cria particao utilizando todo espaco, formata como NTFS (bloco de 64k ideal para BD) e atribui letra
            $disk | Initialize-Disk -PartitionStyle GPT -PassThru -ErrorAction Stop |
                    New-Partition -UseMaximumSize -AssignDriveLetter -ErrorAction Stop |
                    Format-Volume -FileSystem NTFS -NewFileSystemLabel "MYSQL_DATA" -AllocationUnitSize 65536 -Confirm:$false -ErrorAction Stop | Out-Null
                    
            Write-Output "Disco $($disk.Number) inicializado e formatado com sucesso."
        }
    }
    catch {
        Write-Error "Falha ao preparar discos. Detalhes: $($_.Exception.Message)"
    }
}

# ==============================================================================
# FUNCAO: Criar Conta de Servico no Active Directory
# ==============================================================================
function New-ADServiceAccountForMySQL {
    param (
        [string]$AccountName = "usuarioteste",
        [string]$DomainPath = "DC=teste,DC=local"
    )
    
    Write-Output "Iniciando criacao de conta de servico no Active Directory: $AccountName"
    
    try {
        $userExists = Get-ADUser -Filter "SamAccountName -eq '$AccountName'" -ErrorAction SilentlyContinue
        
        if ($userExists) {
            Write-Output "A conta de servico '$AccountName' ja existe no dominio."
        } else {
            # Solicita senha de forma segura, sem expor em texto plano
            Write-Output "Por favor, insira a senha para a nova conta de servico '$AccountName':"
            $securePassword = Read-Host "Senha" -AsSecureString
            
            # Cria o usuario de servico (nao expira senha, sem alteracao no prox logon)
            New-ADUser -Name $AccountName `
                       -SamAccountName $AccountName `
                       -UserPrincipalName "$AccountName@teste.local" `
                       -AccountPassword $securePassword `
                       -Enabled $true `
                       -PasswordNeverExpires $true `
                       -Path "CN=Users,$DomainPath" `
                       -Description "Conta de servico para execucao do MySQL Enterprise" `
                       -ErrorAction Stop
                       
            Write-Output "Conta de servico '$AccountName' criada com sucesso no dominio teste.local."
        }
    }
    catch {
        Write-Error "Falha ao criar conta de servico no AD. Detalhes: $($_.Exception.Message)"
    }
}

# ==============================================================================
# EXECUCAO PRINCIPAL
# ==============================================================================
Write-Output "=== INICIO DA AUTOMACAO DE INFRAESTRUTURA ==="

# 1. Configurar IP Estatico (Ajuste as variaveis conforme ambiente local)
# Set-StaticIP -InterfaceAlias "Ethernet" -IPAddress "192.168.10.101" -PrefixLength 24 -DefaultGateway "192.168.10.1" -DNSServer "192.168.10.10"

# 2. Inicializar Discos (Descomente se houver discos anexados a VM para o DB)
# Initialize-DatabaseDisks

# 3. Criar Conta de Servico (Executar apenas a partir do Domain Controller ou com modulo ADDS RSAT)
# New-ADServiceAccountForMySQL -AccountName "usuarioteste"

Write-Output "=== FIM DA AUTOMACAO ==="
