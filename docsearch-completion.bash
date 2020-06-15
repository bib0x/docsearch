#!/usr/bin/env bash

function __docsearch_completions() {
    local cur prev

    COMPREPLY=()
    
    cur=${COMP_WORDS[COMP_CWORD]}
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    case $prev in
        '-t'|'--topics')
            files=$(IFS=:; for path in $DOCSEARCH_PATH; do find -L $path -type f -name "$cur*.yaml" -printf '%f\n'; done | sort -u | sed -E 's/\.yaml$//g')

            COMPREPLY=( $(compgen -W "$files" -- $cur) )
            return 0
            ;;
         *)
            options=('-C ' '-G ' '-L ' '-c ' '-e ' '-h ' '-i ' '-m ' '-p ' '-s ' '-t ')
            nopts=${#options[@]}

            opts=""
            for ((i=0; i < $nopts; i++)); do
                if [[ ! "${COMP_WORDS[@]}" =~ "${options[i]}" ]]; then
                    opts="$opts ${options[i]}"
                fi
            done

            COMPREPLY=( $(compgen -W "$opts" -- $cur) ) 
            return 0
            ;;
    esac
}

complete -F __docsearch_completions docsearch
