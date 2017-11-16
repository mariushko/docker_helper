#!/bin/bash

_parser_options()
{
  local curr_arg;
  curr_arg=${COMP_WORDS[COMP_CWORD]};
  if [[ ${COMP_CWORD} -eq 1 ]]
  then
    COMPREPLY=( $(compgen -W 'stop_container start_container kill_container list_running_containers list_all_containers list_non_running_containers remove' -- $curr_arg ) );
  fi
}
complete -F _parser_options dh

