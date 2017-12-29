###############################################################################
# Lynx' .zshrc
# A lot of stuff is taken from grml's zshrc (see <http://grml.org/zsh/>, GPLv2)
###############################################################################

###############################################################################
#     PREREQUISITES
###############################################################################

# loaded early since it's needed at various places
autoload -U add-zsh-hook


###############################################################################
#     SETUP ENVIRONMENT
###############################################################################

# enable 265 colors
if [[ "$TERM" = "xterm" ]]; then
    export TERM="xterm-256color"
fi

export EDITOR=vim

###############################################################################
#     ALIASES
###############################################################################

# colors for ls. Also, human-readable sizes are great.
alias ls='ls -b -CF -h --color=auto'

# don't grep in binary files by default
alias grep='grep -I'


###############################################################################
#     OPTIONS
###############################################################################

# append history list to the history file and share it between instances
setopt append_history
#setopt share_history

# save timestamp and duration for each command executed in history
setopt extended_history

# keep only the newest invocation of a command in history
setopt histignorealldups

# don't add commands prefixed with a whitespace to the history
setopt histignorespace

# enable #, ~ and ^ in globbing
setopt extended_glob

# display PID when suspending processes
setopt longlistjobs

# try to avoid the 'zsh: no matches found...'
setopt nonomatch

# report the status of backgrounds jobs immediately
setopt notify

# when a command completion is attempted, make sure the command path is hashed
setopt hash_list_all

# not just at the end
setopt completeinword

# Don't send SIGHUP to background processes when the shell exits
setopt nohup

# make cd push the old directory onto the directory stack
setopt auto_pushd

# avoid "beep"ing
setopt nobeep

# don't push the same dir twice.
setopt pushd_ignore_dups

# * shouldn't match dotfiles. ever.
setopt noglobdots

# use zsh style word splitting
setopt noshwordsplit

# don't error out when unset parameters are used
setopt unset

# report times as if invoked with `time' when a command takes more than 5 secs
REPORTTIME=5

# history
HISTFILE=${HOME}/.zsh/history
HISTSIZE=5000
SAVEHIST=10000


###############################################################################
#     COLORS
###############################################################################

autoload -U colors && colors

# support colors in ls
eval $(dircolors -b)

# support colors in less
export LESS_TERMCAP_mb=$'\e[01;31m'
export LESS_TERMCAP_md=$'\e[01;31m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;44;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[01;32m'

# colors in zsh itself
export ZLSCOLORS="${LS_COLORS}"


###############################################################################
#     KEYBINDINGS
###############################################################################


# initialize
bindkey -e

# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -A key

key[Home]=${terminfo[khome]}
key[End]=${terminfo[kend]}
key[Insert]=${terminfo[kich1]}
key[Delete]=${terminfo[kdch1]}
key[Up]=${terminfo[kcuu1]}
key[Down]=${terminfo[kcud1]}
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}
key[PageUp]=${terminfo[kpp]}
key[PageDown]=${terminfo[knp]}
key[Ctrl+H]='^H'
key[Ctrl+Z]='^Z'
key[Ctrl+Up]='^[Oa'
key[Ctrl+Down]='^[Ob'
key[Ctrl+Left]='^[Od'
key[Ctrl+Right]='^[Oc'

# setup key accordingly
bindkey "${key[Home]}"     beginning-of-line
bindkey "${key[End]}"      end-of-line
bindkey "${key[Insert]}"   overwrite-mode
bindkey "${key[Delete]}"   delete-char
bindkey "${key[Up]}"       up-line-or-history
bindkey "${key[Down]}"     down-line-or-history
bindkey "${key[Left]}"     backward-char
bindkey "${key[Right]}"    forward-char
bindkey "${key[PageUp]}"   beginning-of-buffer-or-history
bindkey "${key[PageDown]}" end-of-buffer-or-history

# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
    function zle-line-init () {
        printf '%s' "${terminfo[smkx]}"
    }
    function zle-line-finish () {
        printf '%s' "${terminfo[rmkx]}"
    }
    zle -N zle-line-init
    zle -N zle-line-finish
fi

# ctrl+h sends command to history without executing it
commit-to-history() {
    print -s ${(z)BUFFER}
    zle send-break
}
zle -N commit-to-history
bindkey "${key[Ctrl+H]}" commit-to-history

# ctrl+z continues the last stopped job
raise-stopped-to-fg() {
    if (( ${#jobstates} )); then
        zle .push-input
        [[ -o hist_ignore_space ]] && BUFFER=' ' || BUFFER=''
        BUFFER="${BUFFER}fg"
        zle .accept-line
    else
        zle -M 'No background jobs. Doing nothing.'
    fi
}
zle -N raise-stopped-to-fg
bindkey "${key[Ctrl+Z]}" raise-stopped-to-fg

# ctrl+up/ctrl+down search the history incremental
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end  history-search-end
bindkey "${key[Ctrl+Up]}" history-beginning-search-backward-end
bindkey "${key[Ctrl+Down]}" history-beginning-search-forward-end

# ctrl+left/ctrl+right jumps to previous/next word
bindkey "${key[Ctrl+Left]}" backward-word
bindkey "${key[Ctrl+Right]}" forward-word


###############################################################################
#     DIRSTACK HANDLING
###############################################################################

# Keep a stack of recent directories
DIRSTACKSIZE=${DIRSTACKSIZE:-20}
DIRSTACKFILE=${DIRSTACKFILE:-${HOME}/.zsh/dirs}

if [[ -f ${DIRSTACKFILE} ]] && [[ ${#dirstack[*]} -eq 0 ]] ; then
    dirstack=( ${(f)"$(< $DIRSTACKFILE)"} )
    # "cd -" won't work after login by just setting $OLDPWD, so
    [[ -d $dirstack[1] ]] && cd $dirstack[1] && cd $OLDPWD
fi

chpwd() {
    local -ax my_stack
    my_stack=( ${PWD} ${dirstack} )
    builtin print -l ${(u)my_stack} >! ${DIRSTACKFILE}
}


###############################################################################
#     AUTOCOMPLETION
###############################################################################

# NOTE: Disable 'HashKnownHosts' in /etc/ssh/ssh_config to allow
#       autocompletion to work with ssh

autoload -U compinit && compinit

setopt completealiases

zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:processes' command 'ps -au$USER'
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:descriptions' \
       format "%{$fg_bold[yellow]%}completing %d%{$reset_color%}"
zstyle ':completion:*:messages' \
       format "%{$fg_bold[green]%}completing %d%{$reset_color%}"
zstyle ':completion:*:warnings' \
       format "%{$fg_bold[red]%}no matches found%{$reset_color%}"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' \
        'r:|[._-]=* r:|=*' 'l:|=* r:|=*'


###############################################################################
#     VIRTUALENV
###############################################################################

#VIRTUAL_ENV_DISABLE_PROMPT=1

#virtualenv_prompt() {
#    if [[ -n $VIRTUAL_ENV ]]; then
#        _virtualenv_prompt="%{${fg_no_bold[magenta]}%}(%{${fg_bold[white]}%}?$(basename $VIRTUAL_ENV)%{${fg_no_bold[magenta]}%})%{$reset_color%}"
#    fi
#}

#add-zsh-hook precmd virtualenv_prompt

#source /usr/bin/virtualenvwrapper.sh


###############################################################################
#     PROMPT
###############################################################################

autoload -U promptinit && promptinit

setopt prompt_subst
setopt transient_rprompt

autoload -U vcs_info
zstyle ':vcs_info:*' formats "%{${fg_no_bold[magenta]}%}(%{${fg_bold[white]}%}%s%{${fg_no_bold[magenta]}%})[%{${fg_bold[green]}%}?%b%{${fg_no_bold[magenta]}%}]%{$reset_color%}"
zstyle ':vcs_info:*' actionformats "%{${fg_no_bold[magenta]}%}(%{${fg_bold[white]}%}%s%{${fg_no_bold[magenta]}%})[%{${fg_bold[green]}%}?%b%{${fg_no_bold[magenta]}%}] (%{${fg_bold[white]}%}%a%{${fg_no_bold[magenta]}%})%{$reset_color%}"

# Oh-my-Zsh prompt created by gianu
#
# github.com/gianu
# sgianazza@gmail.com

PROMPT='[%{$fg_bold[blue]%}%n%{$reset_color%}@%{$fg_bold[grey]%}%m%{$reset_color%} %{$fg[white]%}%30<..<%~%<<%{$reset_color%}%{$reset_color%}]$ '

#PROMPT='[%{${fg_bold[green]}%}%n@%m %{${fg_bold[blue]}%}%30<?<%~%<<%{${reset_color}%} %# '
#RPROMPT='%(?.${vcs_info_msg_0_}${_virtualenv_prompt}.%{${fg_bold[red]}%}?%?%{${reset_color}%})'
#PS2='\`%_> '
#PS3='?# '
#PS4='+%N:%i:%_> '

add-zsh-hook precmd vcs_info


###############################################################################
#     TERMINAL TITLE
###############################################################################

set_title() {
    case $TERM in
        (xterm*|rxvt*)
            builtin print -n "\e]0;$*\a"
            ;;
    esac
}

set_title_program_name() {
    set_title "${(%):-"%n@%m:"} $1"
}

set_title_pwd() {
    set_title ${(%):-"%n@%m: %~"}
}

add-zsh-hook preexec set_title_program_name
add-zsh-hook precmd set_title_pwd


###############################################################################
#     MISC
###############################################################################

# standard math functions like sin()
zmodload zsh/mathfunc

# some useful modules
zmodload -a zsh/stat zstat
zmodload -a zsh/zpty zpty
zmodload -ap zsh/mapfile mapfile

# zmv for batch renaming/moving
autoload -U zmv

###############################################################################
#     VBOX ALIASES
###############################################################################

alias start-buildsrv='VBoxManage startvm Debian\ Buildsrv --type headless'
alias stop-buildsrv='VBoxManage controlvm Debian\ Buildsrv acpipowerbutton'

###############################################################################
#     PATH ADDITIONS
###############################################################################
export PATH=$HOME/bin:$HOME/go/bin:$PATH

###############################################################################
#     KEYCHAIN
###############################################################################
keychain --nogui id_rsa
[ -z "$HOSTNAME" ] && HOSTNAME=`uname -n`
[ -f $HOME/.keychain/$HOSTNAME-sh ] && \
    . $HOME/.keychain/$HOSTNAME-sh
[ -f $HOME/.keychain/$HOSTNAME-sh-gpg ] && \
    . $HOME/.keychain/$HOSTNAME-sh-gpg

