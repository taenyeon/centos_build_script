#!/bin/bash

#----------------------------------------------

# 함수 list
firewall_port_open() {
  # 방화벽 open 함수
  local step_name=$1
  local open_port=$2
  echo -e "\033[32m"["$step_name"] - OPEN FIREWALL"\033[0m"
  {
    firewall-cmd -permanenet --add-port="$open_port"/tcp && firewall-cmd --reload &&
      # then
      echo -e "\033[34m"firewall - PORT "$open_port" is Opened"\033[0m"
  } || {
    # else
    echo -e "\033[31m"firewall - PORT "$open_port" open failed"\033[0m"
  }
}

#----------------------------------------------

# ROOT user check
# 현재 user가 root 인지 확인 -> root로 실행한 경우에만 정상 동작하기 때문에 추가
echo -e "\033[32m"[ROOT USER CHECK]"\033[0m"
currentUser="$(whoami)"

if [ "$currentUser" != "root" ]; then
  exit
fi
echo -e "\033[31m"user is \""$currentUser"\""\033[0m"
#----------------------------------------------

# TIMEZONE setting
echo -e "\033[32m"[TIMEZONE SETTING]"\033[0m"
timedatectl set-timezone Asia/Seoul

#----------------------------------------------

# system update
echo -e "\033[32m"[YUM UPDATE]"\033[0m"
yum -y upgrade
yum -y update

#----------------------------------------------

# firewall 방화벽 install
echo -e "\033[32m"[CHECK INSTALLED FIREWALL ]"\033[0m"
which firewalld >/dev/null || has_firewall=$?
if [ -n "$has_firewall" ]; then
  echo -e "\033[32m"firewalld is not installed."\033[0m"
  yum install -y firewalld &&
    systemctl unmask firewalld &&
    systemctl enable firewalld &&
    systemctl start firewalld
  echo -e "\033[34m"firewalld installed DONE."\033[0m"
else
  echo -e "\033[31m"firewalld is installed."\033[0m"
fi

#----------------------------------------------

# openSSH 설정
echo -e "\033[32m"[OPEN SSH SETTING]"\033[0m"
echo -e "\033[32m"[OPEN SSH SETTING] - CHECK SSH INSTALLED"\033[0m"
which sshd >/dev/null || has_SSH=$?
if [ -n "$has_SSH" ]; then
  echo -e "\033[32m"openSSH is not installed."\033[0m"
  yum -y install openssh-server || true
  echo -e "\033[34m"openSSH installed DONE."\033[0m"
else
  echo -e "\033[31m"openSSH is installed."\033[0m"
fi

echo -e "\033[32m"[OPEN SSH SETTING] - EDIT /etc/ssh/sshd_config"\033[0m"
#cat /etc/ssh/sshd_config | grep -v '^#' | grep -E "PasswordAuthentication|PORT 22" > /dev/null || has_SSH_setting=$?
cat /etc/ssh/sshd_config | grep -E "#centos_build setting" >/dev/null || has_SSH_setting=$?
if [ -n "$has_SSH_setting" ]; then
  ssh_text="#centos_build setting
PasswordAuthentication yes
PORT 22"
  echo -e "\033[34m"insert - PasswordAuthentication Yes"\033[0m"
  echo -e "\033[34m"insert - PORT 22"\033[0m"
  echo "$ssh_text" >> /etc/ssh/sshd_config
  echo -e "\033[32m"EDIT DONE."\033[0m"
else
  echo -e "\033[31m"already settinged"\033[0m"
fi

# firewall 설정
firewall_port_open "[OPEN SSH SETTING]" 22
systemctl sshd start &&
  # then
  echo -e "\033[32m"sshd start successed"\033[0m" ||
  # else
  echo -e "\033[31m"sshd start failed"\033[0m"

#----------------------------------------------

# VIM setting
echo -e "\033[32m"[VIM SETTING]"\033[0m"
echo -e "\033[32m"[VIM SETTING] - check vim installed"\033[0m"
which vim >/dev/null || has_vim=$?
if [ -n "$has_vim" ]; then
  echo -e "\033[32m"vim is not installed."\033[0m"
  yum install -y vim
  echo -e "\033[34m"vim installed DONE."\033[0m"
else
  echo -e "\033[31m"vim is installed."\033[0m"
fi

vim_text="
set number
set ai
set si
set cindent
set shiftwidth=4
set tabstop=4
set ignorecase
set hlsearch
set nocompatible
set fileencodings=utf-8,euc-kr
set fencs=ucs-bom,utf-8,euc-kr
set bs=indent,eol,start
set ruler
set title
set showmatch
set wmnu
syntax on
filetype indent on
set mouse=a
set encoding=utf-8
set fileencodings=utf-8,euc-kr
"
echo -e "\033[32m""[VIM SETTING] - EDIT ~/.vimrc""\033[0m"
echo "$vim_text" >~/.vimrc
echo -e "\033[32m"EDIT DONE."\033[0m"

#----------------------------------------------

# bash PROMPT setting
echo -e "\033[32m"[BASH PROMPT SETTING]"\033[0m"
prompt_text="
export PS1='[\[\e[36;1m\]\u@\[\e[32;1m\]\h] : \[\e[31;1m\]\w >> \[\e[0m\]'
alias agi='apt-get install'
alias agr='apt-get remove --purge'
alias c='clear'
alias cp='cp -i'
alias df='df -h'
alias du='du -h'
alias duh='du -h --max-depth=1 ./'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias gg='exit'
alias grep='grep --color=auto'
alias iwannadie='rm -rf'
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias ls='ls --color=auto'
alias mv='mv -i'
alias ps='ps -ef'
alias rm='rm -i'
alias sysupdate='apt-get update && apt-get dselect-upgrade -y'
alias vi='vim $*'
"
echo -e "\033[32m""[PROMPT SETTING] - EDIT ~/.bashrc""\033[0m"
echo "$prompt_text" >>~/.bashrc
echo -e "\033[32m"EDIT DONE."\033[0m"
echo -e "\033[32m""[PROMPT SETTING] - APPLY ~/.bashrc""\033[0m"
source ~/.bashrc

#---------------------------------------------

# DOCKER setting
echo -e "\033[32m"[DOCKER SETTING]"\033[0m"
yum install -y yum-utils

# DOCKER repository add
echo -e "\033[32m""yum add docker repository""\033[0m"
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --enable docker-ce-nightly

# check docker installed
echo -e "\033[32m"[DOCKER SETTING]"\033[0m"
echo -e "\033[32m"[DOCKER SETTING] - CHECK DOCKER INSTALLED"\033[0m"
which docker >/dev/null || has_docker=$?
if [ -n "$has_docker" ]; then
  echo -e "\033[32m"docker is not installed."\033[0m"
  yum -y install docker-ce docker-ce-cli containerd.io || true
  echo -e "\033[32m"docker installed DONE."\033[0m"
else
  echo -e "\033[31m"docker is installed."\033[0m"
fi

# check docker running
echo -e "\033[32m"[DOCKER SETTING] - CHECK DOCKER RUNNING"\033[0m"
systemctl status docker >/dev/null || is_running_docker=$?
if [ -n "$is_running_docker" ]; then
  echo -e "\033[32m"docker is not running."\033[0m"
  systemctl start docker
  systemctl enable docker
  echo -e "\033[32m"docker running DONE."\033[0m"
else
  echo -e "\033[31m"docker is running."\033[0m"
fi

# change docker default directory
echo -e "\033[32m""[DOCKER SETTING] - CHANGE DEFAULT DIRECTORY -> /etc/docker/daemon.json""\033[0m"
docker_default_directory_text="
{
 'data-root':'/home/docker/data'
}
"
echo -e "\033[32m""[DOCKER SETTING] - EDIT /etc/docker/daemon.json""\033[0m"
echo "$docker_default_directory_text" > /etc/docker/daemon.json
echo -e "\033[32m"EDIT DONE."\033[0m"
echo -e "\033[32m""[DOCKER SETTING] - APPLY /etc/docker/daemon.json""\033[0m"
systemctl stop docker
systemctl daemon-reload
systemctl start docker

#----------------------------------------------
