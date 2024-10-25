# Cow

cow is a bash micro framework for creating scripts having different actions.

Every action is registered by creating shell files in an action.d directory.
Your app will be able to list all available commands including descriptions
automatically. Actions may depend on command line argumends or results of a
previous command.
It also supports default actions, which might be random for ultimative fun.

Oh, and generating a help screen is done automatically, too.

You'll love cow.

## macOS requirements

Make sure to use the latest bash version, not the version 3.X that comes
with macOS - ([brew bash](https://formulae.brew.sh/formula/bash) for example)

## Tutorial

### Tiny overview

After downloading the contents of this repository you will find one file 
called cow.bash and one directory action.d. The cow.bash does all the magic.
In action.d there is one file named h-help.sh. This is the help action.

In order to understand how to use cow, let's just create a funny app with it.

### First steps

Create a file called fun in the directory where cow.bash is located having this
content:
    
    #!/bin/bash

    source $(dirname $(readlink $0 || echo $0))/cow.bash
    [[ -n "$COW_RESULT" ]] && echo "$COW_RESULT"
    [[ -n "$COW_FAIL" ]] && >&2 echo "$COW_FAIL"
    exit $COW_EXIT

Give the file the executable flag by chmod +x ./fun. Now you can run it:

    $ ./fun
    No action given. Run fun help for help.

This is because there is no default action. So this is handled correctly.
Another thing works out of the box:


    $ ./fun help
    Usage: fun ACTION [ACTION_ARGS]
    
    ACTION may be one of:
        h, help   Outputs this screen.
    
Btw, ./fun h works as expected. Calling fun with an unkown action is also
already handled correctly.

    $ ./fun whateveryoulike
    Action unknown whateveryoulike. Run fun help for help.


### Hello World


Create the file action.d/helloworld.sh. The contents should be:

    function cow_action_helloworld {
        echo "Hello World"
    }

Now ./fun helloworld will print

    Hello World
    
./fun help will print

     Usage: fun ACTION [ACTION_ARGS]                                                        
                                                                                              
     ACTION may be one of:                                                                    
         helloworld                                                                           
         h, help     Outputs this screen.                                                     
         default     This is the default action. It is envoked if you do not pass any action. 
                                                                                              
The action is directly registered in the help screen. But the description is
missing.

### Adding descriptions to help screen

Add the following function to action.d/helloworld.sh in order to add the
description:

    function cow_action_helloworld_desc {
        echo "Our mighty cow will say 'Hello World'."
    }

./fun help will now print

     Usage: fun ACTION [ACTION_ARGS]                                                       
                                                                                             
     ACTION may be one of:                                                                   
         helloworld  Our mighty cow will say 'Hello World'.                                  
         h, help     Outputs this screen.                                                    
         default     This is the default action. It is envoked if you do not pass any action.
                                                                                             
Cool, but what is about short options?

### Adding short options to argument list

The action name equals the long option. It is defined by the file name. The
short option is also defined by the filename.
If we change the filename to H-helloworld.sh, ./fun help will print

    Usage: fun ACTION [ACTION_ARGS]                                                          
                                                                                               
    ACTION may be one of:                                                                      
        H, helloworld  Our mighty cow will say 'Hello World'.                                  
        h, help        Outputs this screen.                                                    
        default        This is the default action. It is envoked if you do not pass any action.
                                                                                               
And ./fun -H will print

    Hello World

Great, it worked! Now you are able to add any commands to ./fun using cow. But
what is about command line arguments? 

### Accessing command line arguments

Command line arguments are passed as is to your function.

Changing the action function a bit will demonstrate this.

    function cow_action_helloworld {
        declare salutation=$1 name=$2
        if [[ -n $salutation ]]; then
            echo -n "$salutation "
        else
            echo -n "Hello "
        fi
        if [[ -n $name ]]; then
            echo "$name"
        else
            echo "World"
        fi
        
    }

Now ./fun helloworld Heya Burld will print

    Heya Burld

Validation of the arguments is up to the action.

In order to add the description of the arguments to the help screen, we add the
following to our H-helloworld.sh:

    function cow_action_helloworld_args {
        echo "[SALUTATION] How to salute. Defaults to 'Hello'."
        echo "[NAME] Whom to salute. Defaults to 'World'."
    }

The output of ./fun help is now

    Usage: fun ACTION [ACTION_ARGS]
    
    ACTION may be one of:
        H, helloworld [SALUTATION] [NAME]  Our mighty cow will say 'Hello World'
                                           SALUTATION  How to salute. Defaults to 'Hello'.
                                           NAME       Whom to salute. Defaults to 'World'.
    
        h, help                                 Outputs this screen.
    
### The default action

You can specify a default action, that is triggered, when no action was pass to
the app. So ./fun will call this action.

Let's create a default action which calls the helloworld action with random
parameters prepared from a list.

Create a file in action.d called default.sh.

The contents should be

    function cow_action_default_desc {
        echo "Calls helloworld with random arguments."
    }

    function cow_action_default {
        local salutations=(Heya Hello Hey Gude)
        local names=(world boys girls "Ihr Mainzer")
        cow_action_helloworld "${salutations[$(($RANDOM % 4))]}" "${names[$(($RANDOM % 4))]}"
    }

The output of ./fun changes now each time, for instance

    Heya girls
    Hello Boys
    Gude Ihr Mainzer

In addition, the helpscreen has changed. The output of ./fun help is now

    Usage: fun [ACTION] [ACTION_ARGS]

    ACTION may be one of:
        H, helloworld [SALUTATION] [NAME]  Our mighty cow will say 'Hello world'
                                           SALUTATION  Will add to hello world directly after the d of World.
                                           NAME        Will be add after the first arg seperated by a blank.

        h, help                            Outputs this screen.
        default                            Calls helloworld with random arguments.

    If no ACTION is given, fun will issue the default one.

The default action is listed. In addition, the ACTION is marked as optional
([ACTION] vs ACTION) and the last line has been added.

#### Passing arguments to the default action

You might pass arguments to the default action as expected. But if the argument
equals a valid action (including "default"), this action will be triggered
instead. See the following example for clearification.

We add one argument to the default action: supplement. 
If set, this character is added at the very end of the created salutation.

The contents of default.sh should now be

    function cow_action_default_args {
        echo "[SUPPLEMENT] Will added after the random output."
    }

    function cow_action_default {
        declare supplement=$1
        local salutations=(Heya Hello Hey Gude)
        local names=(world boys girls "Ihr Mainzer")
        cow_action_helloworld "${salutations[$(($RANDOM % 4))]}" "${names[$(($RANDOM % 4))]}$supplement"
    }

Calling ./fun '!' might echo

    Heya Ihr Mainzer!

Whereas ./fun help will echo the help screen.

### Keep information using cow state

Calling ./fun multiple times will cause random output. But random includes
twice the same output. We don't like this. We want always a different random
output.

In order to achieve this, we need in our default action the information of the
ouput of the last run.

The pure bash way would be to create a file and store the output there.
Cow helps with that by offering a state file containing an assotiative array
you might fill with information you like.

#### Store the last output of the default action

In order to store the state two steps are required:
1. Setting the value in the COWSTATE variable
2. Storing COWSTATE

    function cow_action_default {
        declare supplement=$1
        local salutations=(Heya Hello Hey Gude)
        local names=(world boys girls "Ihr Mainzer")
        local output=$(cow_action_helloworld "${salutations[$(($RANDOM % 4))]}" "${names[$(($RANDOM % 4))]}$supplement")
        COWSTATE[last_default_output]=$output
        cow_store_cowstate
        echo $output
    }

After running ./fun, the state is stored. You can verify this by cat ~/.cowstate.

#### Reading the last 

Reading is easy. COWSTATE is always read at the beginning of cow. No explicit
reading is necessary.

    function cow_action_default {
        declare supplement=$1
        local salutations=(Heya Hello Hey Gude)
        local names=(world boys girls "Ihr Mainzer")
        local output=$(cow_action_helloworld "${salutations[$(($RANDOM % 4))]}" "${names[$(($RANDOM % 4))]}$supplement")
        while [[ "$output" == "${COWSTATE[last_default_output]}" ]]; do
            output=$(cow_action_helloworld "${salutations[$(($RANDOM % 4))]}" "${names[$(($RANDOM % 4))]}$supplement")
        done
        COWSTATE[last_default_output]=$output
        cow_store_cowstate
        echo $output
    }

### Error messages and return types

Until know, we considered the happy path, only. Now, let's have a look at error
handling.

As mentioned before validation of arguments passed to your action is up to you.
Let's define, that a supplement has to be exactly one character, either '!',
'.' or '?'.

First wie document this behavior.

    function cow_action_default_args {
        echo "[SUPPLEMENT] Will added after the random output. Only '!', '.' or '?' are allowed"
    }

The wie add the validation to our default action:

    function cow_action_default {
        declare supplement=$1
        if [[ "$supplement" != "!" && "$supplement" != "." && "$supplement" != "?" && "$supplement" != "" ]]; then
            echo "SUPPLEMENT has to be either '!', '.' or '?'"
            return 1
        fi
        local salutations=(Heya Hello Hey Gude)
        local names=(world boys girls "Ihr Mainzer")
        local output=$(cow_action_helloworld "${salutations[$(($RANDOM % 4))]}" "${names[$(($RANDOM % 4))]}$supplement")
        while [[ "$output" == "${COWSTATE[last_default_output]}" ]]; do
            output=$(cow_action_helloworld "${salutations[$(($RANDOM % 4))]}" "${names[$(($RANDOM % 4))]}$supplement")
        done
        COWSTATE[last_default_output]=$output
        cow_store_cowstate
        echo $output
    }

As you see, error messages are returned the same as success messages. The
return value of the action is used as exit code of the application.
Is the return value > 0, the echoed message is the error message.

More precisely:
$COW\_RESULT stores the success message (return value of the action was 0)
$COW\_FAIL stores the error message (return value of the action was > 0)
$COW\_EXIT stores the exit code of the application, i.e. the return value of the action.

Look again at the contents of "fun". You should now understand it.

Note: In order to pass '!' as an argument, you might need to escape it even if
in single quotes depending on your shell. If ./fun '!' is not working as
expected, try ./fun '\!' instead.

### Let the cow say the output

The current fun application is outputting everything as is. You may pipe the
output through any command you like. E.g. cowsay.

    #!/bin/bash

    source $(dirname $(readlink $0 || echo $0))/cow.bash
    [[ -n $COW_RESULT ]] && echo "$COW_RESULT"  | cowsay -n
    [[ -n "$COW_FAIL" ]] && >&2 echo "$COW_FAIL"
    exit $COW_EXIT

The output of ./fun '\!' might now be

     _____________
    < Hello boys! >
     -------------
            \   ^__^
             \  (oo)\_______
                (__)\       )\/\
                    ||----w |
                    ||     ||
    



Have fun!

### Summary

Perfect, you did it all. Now you are able to create new actions accepting
command line arguments, defining default actions and working with states.
The help screen is created automatically for you.

Actions may call other actions and use their results.

Cow knows success and error messages, let you work with them as you like.
You may wrap the output with whatever you like, e.g. cowsay :)
