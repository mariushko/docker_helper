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
  docker inspect --format='{{.Name}}' ${LIST} | sed 's#^/##'
}

list_running_containers_by_name(){
  local LIST=$(docker ps --quiet --no-trunc)
  [[ -n ${LIST} ]] || return
  docker inspect --format='{{.Name}}' ${LIST} | sed 's#^/##'
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

list_running_containers_created_from_image(){
  local NAME=${1}
  local ID
  [[ -n ${NAME} ]] || return
  NAME=$(_normalize_and_verify_image_name_ ${NAME})
  ID=$(docker images --format='{{.ID}}' ${NAME})
  docker inspect --format='{{.Name}}' $(docker ps --quiet --no-trunc --filter ancestor=${ID}) | sed 's#^/##'
}

list_all_images(){
  docker images --format='{{.Repository}}:{{.Tag}}'
}

remove_non_running_containers(){
  docker rm $(list_non_running_containers_by_name)
}

kill_running_containers(){
  docker kill $(list_running_containers_by_name)
}

kill_and_remove_all_containers(){
  kill_running_containers
  remove_non_running_containers
}
