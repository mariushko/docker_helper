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
  $0 remove_images [--all|NAME(s)]             - remove images

EOF
exit 1
}

########### Przetworzenie opcji
COMMAND=${1}; (( $# > 0 )) && shift

case "${COMMAND}" in
  start_containers )
    OPTS=`getopt -l stopped -- "$@"`; eval set -- "$OPTS"
    STOPPED=0
    if (( $# > 0 )); then
      while true ; do
        case "$1" in
          --stopped     ) STOPPED=1; shift;;
          --						) shift; break;;
          *							) help;;
        esac
      done
    fi
    ((STOPPED)) && { (( $# == 0 )) || help; }
    ((STOPPED)) && start_containers || start_containers "$@"
    ;;
  stop_containers	 )
    OPTS=`getopt -l running -- "$@"`; eval set -- "$OPTS"
    RUNNING=0
    if (( $# > 0 )); then
      while true ; do
        case "$1" in
          --running     ) RUNNING=1; shift;;
          --						) shift; break;;
          *							) help;;
        esac
      done
    fi
    ((RUNNING)) && { (( $# == 0 )) || help; }
    ((RUNNING)) && stop_containers || stop_containers "$@"
    ;;
  kill_containers	 )
    OPTS=`getopt -l running -- "$@"`; eval set -- "$OPTS"
    RUNNING=0
    if (( $# > 0 )); then
      while true ; do
        case "$1" in
          --running     ) RUNNING=1; shift;;
          --						) shift; break;;
          *							) help;;
        esac
      done
    fi
    ((RUNNING)) && { (( $# == 0 )) || help; }
    ((RUNNING)) && kill_containers || kill_containers "$@"
    ;;
  list_running_containers )
    (( $# > 0 )) && help || list_running_containers_by_name
    ;;
  list_all_containers	    )
    (( $# > 0 )) && help || list_all_containers_by_name
    ;;
  list_non_running_containers	)
    (( $# > 0 )) && help || list_non_running_containers_by_name
    ;;
  remove_containers )
    OPTS=`getopt -l all -l stopped -l running  -- "$@"`; eval set -- "$OPTS"
    ALL=0
    STOPPED=0
    RUNNING=0
    if (( $# > 0 )); then
      while true ; do
        case "$1" in
          --running     ) RUNNING=1; shift;;
          --stopped     ) STOPPED=1; shift;;
          --all         ) ALL=1; shift;;
          --						) shift; break;;
          *							) help;;
        esac
      done
    fi
    (( $(( ALL + STOPPED + RUNNING )) <= 1 )) || help
    (( $(( ALL + STOPPED + RUNNING )) == 1 )) && { (( $# == 0 )) || help }
    ((STOPPED)) && remove_non_running_containers
    ((RUNNING)) && remove_containers $(kill_running_containers
    ((ALL)) && remove_containers
    ;;
  remove_images )
    OPTS=`getopt -l all -- "$@"`; eval set -- "$OPTS"
    WITH_ALL_CONTAINERS=0
    ALL=0
    if (( $# > 0 )); then
      while true ; do
        case "$1" in
          --all         ) ALL=1; shift;;
          --						) shift; break;;
          *							) help;;
        esac
      done
    fi
    ((ALL)) && remove_images || remove_images "$@"
    ;;
  *) help;;
esac

exit 0

###################################### Functions

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

start_containers(){
  local LIST
  if (( $# == 0 )); then
    LIST=$(list_non_running_containers_by_name)
  else
    LIST="$@"
  fi
  [[ -n ${LIST} ]] || return
  docker start ${LIST}
}

stop_containres(){
  local LIST
  if (( $# == 0 )); then
    LIST=$(list_running_containers_by_name)
  else
    LIST="$@"
  fi
  [[ -n ${LIST} ]] || return
  docker stop ${LIST}
}

kill_containres(){
  local LIST
  if (( $# == 0 )); then
    LIST=$(list_running_containers_by_name)
  else
    LIST="$@"
  fi
  [[ -n ${LIST} ]] || return
  docker kill ${LIST}
}

remove_containers(){
  local LIST
  if (( $# == 0 )); then
    LIST=$(list_non_running_containers_by_name)
  else
    LIST="$@"
  fi
  [[ -n ${LIST} ]] || return
  docker kill ${LIST}
}

remove_images(){
  local LIST
  if (( $# == 0 )); then
    LIST=$(list_all_images)
  else
    LIST="$@"
  fi
  for IMAGE in ${LIST}
  do
    echo ${IMAGE}
    for CONTAINER in $(list_containers_created_from_image)
    do
      [[ is_running ${CONTAINER} ]] && kill_running_containers ${CONTAINER}
      remove_non_running_containers ${CONTAINER}
    done
    docker rmi ${IMAGE}
  done
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
  local LIST
  if (( $# == 0 )); then
    LIST=$(list_running_containers_by_name)
  else
    LIST="$@"
  fi
  local CONTAINER
  for CONTAINER in ${LIST}
  do
    echo ${CONTAINER}
    docker kill ${CONTAINER} > /dev/null 2>&1
  done
}

remove_all_images_from_repo(){
  local REPO=${1}
  [[ -n ${REPO} ]] || return
  docker images --format='{{.Repository}}' | grep -q "^${REPO}$" || return
  docker rmi -f $(docker images --format='{{.Repository}}:{{.Tag}}' ${REPO})
}
