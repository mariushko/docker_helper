#!/bin/bash -e
# vim: ts=2 shiftwidth=2 expandtab

########################################################################
#
#  Copyright (C) 2014 Mariusz Bartusiak <mariushko@gmail.com>
#
#  http://github.com/mariushko
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
########################################################################

help(){
cat <<EOF

  usage: $0 command [OPTIONS]

  $0 start_containers   [--stopped | NAME(s)]  - start stopped containers
  $0 stop_containers    [--running | NAME(s)]  - stop running containers
  $0 kill_containers    [--running | NAME(s)]  - kill running cintainers
  $0 list_running_containers                   - list running containers
  $0 list_all_containers                       - list all containers
  $0 list_non_running_containers               - list non running containers
  $0 remove_containers [--all|--stopped|--running|NAME(s)] - remove containers

EOF
exit 1
}

########### Przetworzenie opcji
COMMAND=${1}; (( $# > 0 )) && shift

case "${COMMAND}" in
  start_containers )	OPTS=`getopt -l stopped -- "$@"`; eval set -- "$OPTS";;
  stop_containers	 )  OPTS=`getopt -l running -- "$@"`; eval set -- "$OPTS";;
  kill_containers	 )  OPTS=`getopt -l running -- "$@"`; eval set -- "$OPTS";;
  list_running_containers ) ;;
  list_all_containers	    ) ;;
  list_non_running_containers	) ;;
  remove_containers ) OPTS=`getopt -l all -l stopped -l running  -- "$@"`; eval set -- "$OPTS";;
  *) help;;
esac

ALL=0
STOPPED=0
RUNNING=0

if (( $# > 0 )); then
  while true ; do
    case "$1" in
      --stopped     ) STOPPED=1; shift;;
      --running     ) RUNNING=1; shift;;
      --all					) ALL=1; shift;;
      --						) shift; break;;
      *							) help;;
    esac
  done
fi

# Tylko jedna z opcji ALL, STOPPED, RUNNING może być ustawiona...
(( $(( ALL + STOPPED + RUNNING )) <= 1 )) || help
# Jak jedna z opcji ALL, STOPPED, RUNNING jest ustawiona, to żadnych więcej argumentów już nie trzeba...
(( $(( ALL + STOPPED + RUNNING )) == 1 )) && { (( $# == 0 )) || help; }


case
  start_containers )	;;
  stop_containers	 )  ;;
  kill_containers	 )  ;;
  list_running_containers )     list_running_containers_by_name;;
  list_all_containers	    )     list_all_containers_by_name;;
  list_non_running_containers	) list_non_running_containers_by_name;;
  remove_containers ) ;;
  *) help;;
esac


exit 0

_normalize_and_verify_image_name_(){
  local NAME=${1}
  local REPO TAG
  [[ -n ${NAME} ]] || return
  REPO=$(echo ${NAME} | cut -d: -f1)
  TAG=$(echo ${NAME} | cut -d: -f2)
  [[ ${NAME} == ${REPO} ]] && NAME=${NAME}:latest
  list_all_images | grep -q "^${NAME}$" || return
  echo ${NAME}
}

list_all_containers_by_name(){
  local LIST=$(docker ps --all --quiet --no-trunc)
  [[ -n ${LIST} ]] || return
  docker inspect --format='{{.Name}}' ${LIST} | sed 's#^/##' | sort
}

list_running_containers_by_name(){
  local LIST=$(docker ps --quiet --no-trunc)
  [[ -n ${LIST} ]] || return
  docker inspect --format='{{.Name}}' ${LIST} | sed 's#^/##' | sort
}

list_non_running_containers_by_name(){
  local A B
  while read A
  do
    while read B
    do
      [[ ${A} == ${B} ]] && continue 2
    done < <(list_running_containers_by_name)
    echo ${A}
  done < <(list_all_containers_by_name)
}

list_containers_created_from_image(){
  local NAME=${1}
  local ID LIST
  [[ -n ${NAME} ]] || return
  NAME=$(_normalize_and_verify_image_name_ ${NAME})
  ID=$(docker images --format='{{.ID}}' ${NAME})
  LIST=$(docker ps --all --quiet --no-trunc --filter ancestor=${ID})
  [[ -n ${LIST} ]] || return
  docker inspect --format='{{.Name}}' ${LIST} | sed 's#^/##'
}

list_all_images(){
  docker images --format='{{.Repository}}:{{.Tag}}'
}

remove_non_running_containers(){
  local LIST=$(list_non_running_containers_by_name)
  [[ -n ${LIST} ]] || return
  docker rm ${LIST}
}

kill_running_containers(){
  local LIST=$(list_running_containers_by_name)
  [[ -n ${LIST} ]] || return
  docker kill ${LIST}
}

kill_and_remove_all_containers(){
  kill_running_containers
  remove_non_running_containers
}

remove_all_images_from_repo(){
  local REPO=${1}
  [[ -n ${REPO} ]] || return
  docker images --format='{{.Repository}}' | grep -q "^${REPO}$" || return
  docker rmi -f $(docker images --format='{{.Repository}}:{{.Tag}}' ${REPO})
}
