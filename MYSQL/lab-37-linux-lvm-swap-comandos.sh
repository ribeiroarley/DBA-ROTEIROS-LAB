#!/bin/bash
/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : lab-37-linux-lvm-swap-comandos.sh
  Objetivo     : Script de referencia com comandos para gestao LVM, Swap e Basicos
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Ubuntu Server Official Docs / LVM Administrator Guide
*******************************************************************************/

# AVISO: ESTE ARQUIVO E UM SCRIPT DE REFERENCIA. 
# NAO EXECUTE ESTE ARQUIVO DIRETAMENTE COMO UM SCRIPT INTEIRO SEM REVISAO, 
# OS COMANDOS DEVEM SER EXECUTADOS PASSO A PASSO CONFORME A NECESSIDADE DO LABORATORIO.

# ==============================================================================
# 1. ATUALIZACAO DE PACOTES (APT)
# ==============================================================================
echo "--- Atualizacao de repositorios e pacotes do sistema ---"

# Atualizar lista de repositorios
# sudo apt update -y

# Mostrar pacotes que podem ser atualizados
# apt list --upgradable

# Instalar os pacotes desatualizados
# sudo apt upgrade -y

# ==============================================================================
# 2. GERENCIAMENTO DO USUARIO ROOT
# ==============================================================================
echo "--- Gerenciamento do usuario root ---"

# Habilitar conta root (definindo uma senha, requer privilegios sudo)
# sudo passwd root

# Logar no shell nivel de sistema (como root)
# sudo -s

# Desabilitar root (se habilitado temporariamente)
# logout / exit do shell do root

# ==============================================================================
# 3. CONFIGURACAO DE LVM (LOGICAL VOLUME MANAGER)
# ==============================================================================
echo "--- Configuracao de discos e LVM ---"

# 3.1. VERIFICACAO DE DISCOS
# sudo fdisk -l

# 3.2. PARTICIONAMENTO PARA LVM (Exemplo disco novo sdb e sdc)
# sudo fdisk /dev/sdb
# Comandos no fdisk: n (nova particao), p (primaria), 1 (numero), enter (setor inicio), +3G (tamanho)
# Mudar tipo para LVM: t (tipo), 8e (codigo LVM Linux)
# Gravar: w

# 3.3. VOLUMES FISICOS (PV - Physical Volume)
# Criar volumes fisicos nas particoes LVM criadas (ex: sdb1, sdb2, sdc1, sdc2)
# sudo pvcreate /dev/sdb1
# sudo pvcreate /dev/sdb2
# sudo pvcreate /dev/sdc1
# sudo pvcreate /dev/sdc2
# Verificar PVs:
# sudo pvdisplay

# 3.4. GRUPOS DE VOLUMES (VG - Volume Group)
# Criar Grupos de Volumes a partir dos Volumes Fisicos
# sudo vgcreate grupo-volume1 /dev/sdb1
# sudo vgcreate grupo-volume2 /dev/sdb2 /dev/sdc1 /dev/sdc2
# Verificar VGs:
# sudo vgdisplay
# sudo vgscan

# 3.5. VOLUMES LOGICOS (LV - Logical Volume)
# Criar Volumes Logicos nos VGs existentes
# sudo lvcreate -L 2GB -n vol01 grupo-volume1
# sudo lvcreate -L 2GB -n vol02 grupo-volume2
# sudo lvcreate -L 2GB -n vol03 grupo-volume2
# sudo lvcreate -L 2GB -n vol04 grupo-volume2
# Verificar LVs:
# sudo lvdisplay
# sudo lvscan

# 3.6. FORMATACAO E MONTAGEM
# Formatar com sistema de arquivos ext4
# sudo mkfs.ext4 /dev/grupo-volume1/vol01
# sudo mkfs.ext4 /dev/grupo-volume2/vol02
# sudo mkfs.ext4 /dev/grupo-volume2/vol03
# sudo mkfs.ext4 /dev/grupo-volume2/vol04

# Criar diretorios base e montar os volumes
# sudo mkdir /lvm1 /lvm2 /lvm3 /lvm4
# sudo mount -t ext4 /dev/grupo-volume1/vol01 /lvm1
# sudo mount -t ext4 /dev/grupo-volume2/vol02 /lvm2
# sudo mount -t ext4 /dev/grupo-volume2/vol03 /lvm3
# sudo mount -t ext4 /dev/grupo-volume2/vol04 /lvm4

# Validar montagem
# df -h

# Persistir montagem editando o arquivo fstab (adicionar ao final do arquivo)
# sudo vi /etc/fstab
# Adicionar linhas (com tabs):
# /dev/grupo-volume1/vol01    /lvm1    ext4    defaults    0    2
# /dev/grupo-volume2/vol02    /lvm2    ext4    defaults    0    2
# /dev/grupo-volume2/vol03    /lvm3    ext4    defaults    0    2
# /dev/grupo-volume2/vol04    /lvm4    ext4    defaults    0    2

# Testar montagem via fstab
# sudo mount -a

# 3.7 REDIMENSIONAMENTO DE VOLUMES (Exemplo Expandir)
# 1. Desmontar volume
# sudo umount /lvm2
# 2. Expandir LV
# sudo lvresize -L 3GB /dev/grupo-volume2/vol02
# 3. Verificar erros e Atualizar File System ext4
# sudo e2fsck -f /dev/grupo-volume2/vol02
# sudo resize2fs /dev/grupo-volume2/vol02
# 4. Montar novamente
# sudo mount -t ext4 /dev/grupo-volume2/vol02 /lvm2

# ==============================================================================
# 4. CRIACAO E MONTAGEM DE SWAP FILES
# ==============================================================================
echo "--- Configuracao de Swap Files ---"

# Verificar memoria e swap atual
# free -h
# swapon -s

# Criar arquivo de Swap de 2GB (1G count=2)
# sudo dd if=/dev/zero of=/swapfile bs=1G count=2

# Protecao e Permissoes
# sudo chown root:root /swapfile
# sudo chmod 0600 /swapfile

# Configurar e Habilitar arquivo como Swap
# sudo mkswap /swapfile
# sudo swapon /swapfile

# Persistir montagem de swap no boot
# sudo vi /etc/fstab
# Adicionar linha:
# /swapfile    swap    swap    defaults    0    0

# Para remover (caso precise)
# sudo swapoff /swapfile
# sudo rm -f /swapfile
# E remover linha correspondente do /etc/fstab

# ==============================================================================
# 5. COMANDOS BASICOS DE NAVEGACAO E DIRETORIOS
# ==============================================================================
echo "--- Comandos Basicos de Navegacao Linux ---"

# whoami      : Mostra o usuario logado atualmente.
# pwd         : Mostra o caminho do diretorio corrente (print working directory).
# ls          : Lista os arquivos e diretorios no local corrente.
# ls -l       : Lista com detalhes de permissoes, dono e data.
# cd /        : Navega para a raiz do sistema.
# cd ~        : Navega para a pasta home do usuario logado (/home/usuarioteste).
# cd ..       : Navega para o diretorio pai.
# clear       : Limpa a tela do terminal.
# mkdir       : Cria um novo diretorio (ex: mkdir novosdados).
# rmdir       : Remove diretorio vazio.
# rm -r       : Remove diretorio e seu conteudo interno recursivamente.
# cp          : Copia arquivos (ex: cp orig.txt dest.txt).
# chown       : Altera o dono e grupo de um arquivo/diretorio. (ex: chown usuarioteste:root arquivo.txt)
# chmod       : Altera permissoes (ex: chmod 764 arquivo.txt) onde:
#               4 = read (r), 2 = write (w), 1 = execute (x)
# df -h       : Mostra uso do disco.
# top / htop  : Mostra uso de CPU, memoria e processos rodando (sair com q).
# kill -9 PID : Mata um processo forcado pelo ID do processo.
# sudo reboot : Reinicia o servidor.
# sudo poweroff: Desliga o servidor.

echo "Revisao de comandos completa."
