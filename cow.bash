# Initialization {{{

# The readlink is used, that you may simply have a link to cow in one of your bin folders.
declare -r WORKDIR="$(dirname $(readlink $0 || echo $0))"

# In this file COWSTATE is declared. You may store anything here using
# store_cowstate command and read it by simple sourcing this file.
# See cow_store_cowstate for more.
declare -r STATEFILE=~/.cowstate
[[ ! -f $STATEFILE ]] && "declare -A COWSTATE" > $STATEFILE
source $STATEFILE


# All actions are defined in this directory.
declare -r ACTION_DIR="$WORKDIR/action.d"

# This is the result of an successful action - things you might print to stdout
COW_RESULT=
# This is the result of an unsuccessful action - things you might print to stderr
COW_FAIL=
# This contains the suggested exit code of you application
COW_EXIT=0

# Actions defined as $ACTION => 1
declare -A ACTIONS

# Shortcut map as $SHORTCUT => $ACTION
declare -A ACTION_SHORTCUTS

# Argument list with description per argument
declare -A ACTION_ARGS

# Each action may have an description. This is shown by "cow help".
declare -A ACTION_DESC


# Read all actions from action.d folder.
# An action file is named ${ACTION_SHORTCUT}-${ACTION}.${EXTENSION}. The
# EXTIONSION might be anything, but we source the actions files, though .bash
# or .sh is recommended.
# In this file there has to be defined the action by a function called
# cow_action_${ACTION}. This is the action function. Optional a description
# string for the help screen might be defined in cow_action_${ACTION}_desc.
# Also optional the arguments of the action may be explained in
# cow_action_${ACTION}_args.
#
# All actions are sourced, because on action might call another action.
for f in $ACTION_DIR/*; do
    action=$(basename $f | cut -d '-' -f 2 | cut -d '.' -f 1)
    ACTION_SHORTCUTS[$(basename $f | cut -d '-' -f 1 | cut -d '.' -f 1)]=$action
    ACTIONS[$action]=1
    source $f

    action_desc=cow_action_${action}_desc
    declare -F $action_desc > /dev/null && \
        ACTION_DESC[$action]="$($action_desc)"
    action_args=cow_action_${action}_args
    declare -F $action_args > /dev/null && \
        ACTION_ARGS[$action]="$($action_args)"
done

# Determine action string.
ACTION=$1

if [[ -z $ACTION ]]; then
    if [[ ! -v ACTIONS[default] ]];
    then
        COW_FAIL="No action given. Run $(basename $0) help for help."
    else
        ACTION=default
    fi
else
    # Handle shortcuts
    [[ -v ACTION_SHORTCUTS[$ACTION] ]] && ACTION=${ACTION_SHORTCUTS[$ACTION]}

    # Validate action
    if [[ ! -v ACTIONS[$ACTION] ]]; then
        if [[ ! -v ACTIONS[default] ]]; then
            COW_FAIL="Action unknown $ACTION. Run $(basename $0) help for help."
        else
            ACTION=default
        fi
    else
        shift 1
    fi
fi

# }}}

# Functions {{{

function cow_store_cowstate {
    local file_contents="declare -A COWSTATE"
    for opt in "${!COWSTATE[@]}"
    do
        file_contents="$file_contents\nCOWSTATE[$opt]=\"${COWSTATE[$opt]}\""
    done
    echo -e $file_contents > $STATEFILE
}


# }}}

if [[ -z "$COW_FAIL" ]]; then
    # read the state
    fnname=cow_action_$ACTION

    result=$($fnname "$@")
    COW_EXIT=$?
    if [[ $? -eq 0 ]]; then
        COW_RESULT=$result
    else
        COW_FAIL=$result
    fi
else
    COW_EXIT=1
fi
