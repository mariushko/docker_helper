#!/bin/bash

#        $0 start_containers   [--stopped | NAME(s)]  - start stopped containers
#        $0 stop_containers    [--running | NAME(s)]  - stop running containers
#        $0 kill_containers    [--running | NAME(s)]  - kill running cintainers
#        $0 list_running_containers                   - list running containers
#        $0 list_all_containers                       - list all containers
#        $0 list_non_running_containers               - list non running containers
#        $0 remove_containers [--all|--stopped|--running|NAME(s)] - remove containers
#        $0 remove_images [--all|NAME(s)]             - remove images

_parser_options()
{
  local curr_arg;
#	local $commands="start_containers stop_containers kill_containers list_running_containers list_all_containers list_non_running_containers remove_containers remove_images"
  curr_arg=${COMP_WORDS[COMP_CWORD]};
  XXX='-f'
  if [[ ${COMP_CWORD} -eq 1 ]]
  then
    COMPREPLY=( $(compgen -W ${XXX} -- $curr_arg ) );
  fi
}
complete -F _parser_options dhelper

