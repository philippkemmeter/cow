function cow_action_help_desc {
    echo "Outputs this screen."
}

function cow_action_help {

    (
        function extract_args_list {
            declare action=$1
            echo "${ACTION_ARGS[$action]}"  | cut -d " " -f 1 | paste -sd ' ' -
        }
        function echo_action_shortcut_args_formatted {
            declare action=$1 shortcut=$2 args=$3
            if [[ $action != $shortcut ]]; then
                echo -n "$shortcut, $action $args"
            else
                echo -n "$action $args"
            fi
        }
        function echo_argument_table_for_action {
            declare action=$1 indent=$2
            local max_width=0
            local arg=
            for arg in $(extract_args_list $action | sed -E 's/\[([a-zA-Z_]*)\]/\1/g'); do
                [[ ${#arg} -gt $max_width ]] && max_width=${#arg}
            done
            echo
            echo "${ACTION_ARGS[$action]}" \
                | sed -E 's/\[([A-Za-z_]*)\]/\1/g' \
                | awk '{first=$1; $1=""; printf "%'$indent's%-'$max_width's %s\n", " ", first, $0}'
        }
        function echo_action_table {
            local max_width=0
            local tmp=
            local action=
            local shortcut=
            for shortcut in "${!ACTION_SHORTCUTS[@]}"; do
                action=${ACTION_SHORTCUTS[$shortcut]}
                tmp=$(echo_action_shortcut_args_formatted $action $shortcut "$(extract_args_list $action)")
                [[ ${#tmp} -gt $max_width ]] && max_width=${#tmp}
            done

            for shortcut in "${!ACTION_SHORTCUTS[@]}"; do
                action=${ACTION_SHORTCUTS[$shortcut]}
                tmp=$(echo_action_shortcut_args_formatted $action $shortcut "$(extract_args_list $action)")
                echo -n "    $tmp"
                ((tmp=$max_width-${#tmp}+2))
                printf "%${tmp}s"

                [[ -v ACTION_DESC[$action] ]] && echo -n ${ACTION_DESC[$action]}
                [[ -v ACTION_ARGS[$action] ]] && echo_argument_table_for_action $action $((max_width+6))
                echo
            done
        }

        if [[ -v ACTIONS[default] ]]; then
            echo "Usage: $(basename $0) [ACTION] [ACTION_ARGS]"
        else
            echo "Usage: $(basename $0) ACTION [ACTION_ARGS]"
        fi

        echo "
ACTION may be one of:
$(echo_action_table)"

        if [[ -v ACTIONS[default] ]]; then
            echo "If no ACTION is given, $(basename $0) will issue the default one."
        fi
    )
}
