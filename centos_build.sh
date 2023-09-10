#!/bin/bash

#----------------------------------------------

# 함수 list

conform() {
  local conformMessage=$1
  while true; do
    read -rp "$conformMessage [y/n] : " yn
    case $yn in
    [Yy])
      echo true
      break
      ;;
    [Nn])
      echo false
      break
      ;;
    esac
  done
}

firewall_port_open() {
  # 방화벽 open 함수
  local open_port=$1
  echo -e "\033[32m"["OPEN PORT"] - OPEN FIREWALL"\033[0m"
  {
    firewall-cmd -permanenet --add-port="$open_port"/tcp && firewall-cmd --reload &&
      # then
      echo -e "\033[34m"firewall - PORT "$open_port" is Opened"\033[0m"
  } || {
    # else
    echo -e "\033[31m"firewall - PORT "$open_port" open failed"\033[0m"
  }
}

install_if_not_installed() {
  # 설치되지 않은 경우, 설치하는 함수
  local target=$1
  local is_installed=false
  echo -e "\033[32m"[INSTALL $target]"\033[0m"
  echo -e "\033[32m"[INSTALL $target] - check $target installed"\033[0m"
  which "$target" >/dev/null || has_Target=$?
  if [ -n "$has_Target" ]; then
    echo -e "\033[32m"$target is not installed."\033[0m"
    yum install -y "$target"
    echo -e "\033[34m"$target installed DONE."\033[0m"
  else
    echo -e "\033[31m"$target is installed."\033[0m"
  fi
}

regist_service() {
  # systemctl service 등록 함수
  local target=$1
  echo -e "\033[32m"[REGIST SERVICE $target]"\033[0m"
  systemctl enable "$target"
  systemctl start "$target" &&
    # then
    echo -e "\033[32m"$target start successed"\033[0m" ||
    # else
    echo -e "\033[31m"$target start failed"\033[0m"
}

update_service() {
  # systemctl service 업데이트 함수
  local target=$1
  echo -e "\033[32m"[UPDATE SERVICE $target]"\033[0m"
  systemctl stop "$target" &&
    systemctl daemon-reload &&
    systemctl start "$target" &&
    # then
    echo -e "\033[32m"$target update successed"\033[0m" ||
    # else
    echo -e "\033[31m"$target update failed"\033[0m"
}

# Docker 함수 list

docker_build_image_use_dockerfile() {
  local dockerfilePath=$1
  local imageName=$2
  docker build "$dockerfilePath" -t "$imageName"

}
docker_create_volume() {
  local imageName=$1
  docker volume create "$imageName"
}

docker_create_container() {
  local imageName=$1
  local ports=$3
  local need_privileged=$2
  local user=$4
  local port
  local command
  command="docker run -d -e TZ=Asia/Seoul --name $1"

  if [[ -v "$need_privileged" ]]; then
    command+=" --privileged"
  fi

  if [[ -v "$user" ]]; then
    command+=" -u $user"
  fi
  for port in $ports; do
    command+=" -p $port:$port"
  done
  command+=" -v $imageName"
  command+=" $imageName"
  # 명령어 실행
  eval "$command"
}

#----------------------------------------------

# ROOT user check
# 현재 user가 root 인지 확인 -> root로 실행한 경우에만 정상 동작하기 때문에 추가
check_is_ROOT() {
  echo -e "\033[32m"[ROOT USER CHECK]"\033[0m"
  local currentUser="$(whoami)"

  if [ "$currentUser" != "root" ]; then
    exit
  fi
  echo -e "\033[31m"user is \""$currentUser"\""\033[0m"
}
#----------------------------------------------

# TIMEZONE setting
setting_TIMEZONE() {
  echo -e "\033[32m"[TIMEZONE SETTING]"\033[0m"
  timedatectl set-timezone Asia/Seoul
}

#----------------------------------------------

# system update
update_system() {
  echo -e "\033[32m"[YUM UPDATE]"\033[0m"
  yum -y upgrade
  yum -y update
}

#----------------------------------------------

# firewall 방화벽 install
install_firewall() {
  install_if_not_installed firewalld
  systemctl unmask firewalld
  regist_service firewalld
}

#----------------------------------------------

# openSSH 설정
setting_openssh() {
  echo -e "\033[32m"[OPEN SSH SETTING]"\033[0m"
  install_if_not_installed sshd

  echo -e "\033[32m"[OPEN SSH SETTING] - EDIT /etc/ssh/sshd_config"\033[0m"
  #cat /etc/ssh/sshd_config | grep -v '^#' | grep -E "PasswordAuthentication|PORT 22" > /dev/null || has_SSH_setting=$?
  cat /etc/ssh/sshd_config | grep -E "#centos_build setting" >/dev/null || has_SSH_setting=$?
  if [ -n "$has_SSH_setting" ]; then
    ssh_text="
    #centos_build setting
PasswordAuthentication yes
PORT 22"
    echo -e "\033[34m"insert - PasswordAuthentication Yes"\033[0m"
    echo -e "\033[34m"insert - PORT 22"\033[0m"
    echo "$ssh_text" >>/etc/ssh/sshd_config
    echo -e "\033[32m"EDIT DONE."\033[0m"
  else
    echo -e "\033[31m"already settinged"\033[0m"
  fi

  # firewall 설정
  firewall_port_open 22
  regist_service sshd
}

#----------------------------------------------

# VIM setting
setting_vim() {
  echo -e "\033[32m"[VIM SETTING]"\033[0m"
  install_if_not_installed vim

  local vim_text="
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
}

#----------------------------------------------

# bash PROMPT setting
setting_bash_prompt() {
  echo -e "\033[32m"[BASH PROMPT SETTING]"\033[0m"

  local prompt_text="
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
alias vi='vim \$*'
"
  echo -e "\033[32m""[PROMPT SETTING] - EDIT ~/.bashrc""\033[0m"
  echo "$prompt_text" >>~/.bashrc
  echo -e "\033[32m"EDIT DONE."\033[0m"
  echo -e "\033[32m""[PROMPT SETTING] - APPLY ~/.bashrc""\033[0m"
  source ~/.bashrc
}

#---------------------------------------------

# DOCKER setting
setting_docker() {

  echo -e "\033[32m"[DOCKER SETTING]"\033[0m"
  yum install -y yum-utils

  # DOCKER repository add
  echo -e "\033[32m""yum add docker repository""\033[0m"
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  yum-config-manager --enable docker-ce-nightly

  # check docker installed
  echo -e "\033[32m"[DOCKER SETTING]"\033[0m"
  echo -e "\033[32m"[DOCKER SETTING] - CHECK DOCKER INSTALLED"\033[0m"
  install_if_not_installed docker-ce
  install_if_not_installed docker-ce-cli
  install_if_not_installed containerd.io

  regist_service docker

  # change docker default directory
  echo -e "\033[32m""[DOCKER SETTING] - CHANGE DEFAULT DIRECTORY -> /etc/docker/daemon.json""\033[0m"
  local docker_default_directory_text="
{
 'data-root':'/home/docker/data'
}
"
  echo -e "\033[32m""[DOCKER SETTING] - EDIT /etc/docker/daemon.json""\033[0m"
  echo "$docker_default_directory_text" >/etc/docker/daemon.json
  echo -e "\033[32m"EDIT DONE."\033[0m"
  echo -e "\033[32m""[DOCKER SETTING] - APPLY /etc/docker/daemon.json""\033[0m"
  update_service docker

  mkdir /home/docker
}

create_container_redis() {
  echo -e "\033[32m"[CREATE CONTAINER REDIS]"\033[0m"
  local redis_dockerfile="
FROM redis

COPY conf/redis.conf /usr/local/etc/redis/redis.conf
CMD ['redis-server','/usr/local/etc/redis/redis.conf']

EXPOSE 6379
"
  local redis_conf="
bind 0.0.0.0
port 6379
requirepass 1q2w3e4r
maxmemory 1gb
"
  mkdir -p /home/docker/redis/dockerfile/conf
  echo "$redis_dockerfile" >/home/docker/redis/dockerfile/dockerfile
  echo "$redis_conf" >/home/docker/redis/dockerfile/conf/redis.conf
  docker_build_image_use_dockerfile "/home/docker/redis/dockerfile/dockerfile" "redis"
  docker_create_volume "redis"
  docker_create_container "redis" "6379"

}

#----------------------------------------------
# 사용할 function 등록
start() {
  local need_docker_default_container_setting=$(conform "need docker default container setting?")

  check_is_ROOT
  setting_TIMEZONE
  update_system
  install_firewall
  setting_openssh
  setting_vim
  setting_bash_prompt
  setting_docker
  if [[ $need_docker_default_container_setting = true ]]; then

  fi
}
#----------------------------------------------
# START SHELL
start
