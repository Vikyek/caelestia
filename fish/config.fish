########################################
# ENVIRONMENT & PATH (ALL SHELLS)
########################################

fish_add_path "$HOME/.local/bin"

set -gx ANDROID_HOME "$HOME/Android/Sdk"
set -gx ANDROID_SDK_ROOT "$ANDROID_HOME"
fish_add_path "$ANDROID_HOME/cmdline-tools/latest/bin" "$ANDROID_HOME/platform-tools"

if test -S "$HOME/.goldwarden-ssh-agent.sock"
    set -gx SSH_AUTH_SOCK "$HOME/.goldwarden-ssh-agent.sock"
end

# Antigravity Manager proxy routing
set -gx GEMINI_API_BASE "http://127.0.0.1:8045/v1"
set -gx OPENAI_BASE_URL "http://127.0.0.1:8045/v1"
set -gx WIKSR_MODEL "qwen2.5:1.5b"

# Python & Containers
set -gx PYTHON_KEYRING_BACKEND "keyring.backends.null.Keyring"
set -gx DOCKER_HOST "unix://$XDG_RUNTIME_DIR/podman/podman.sock"

# Editors & Pager
set -gx EDITOR "micro"
set -gx VISUAL "micro"
set -gx PAGER "bat"
set -gx LESS "-R"

########################################
# INTERACTIVE CONFIGURATION
########################################

if status is-interactive
    # Remove default greeting
    set -g fish_greeting

    # Tool Integrations
    if type -q fnm
        fnm env --use-on-cd | source
    end

    if type -q starship
        starship init fish | source
    end

    if type -q zoxide
        zoxide init fish | source
    end

    if type -q atuin
        atuin init fish | source
    end

    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
    set -gx FZF_DEFAULT_OPTS "
    --height=80%
    --layout=reverse
    --border
    --preview 'bat --style=numbers --color=always --line-range=:500 {}'
    "

    # Shortcuts & Aliases
    alias yay='paru'
    alias gemini='agy'

    alias soft-reboot="sudo /usr/local/bin/soft-reboot"
    alias kernel-reboot="sudo /usr/local/bin/kernel-reboot"

    alias ..='cd ..'
    alias ...='cd ../..'
    alias ....='cd ../../../..'
    alias c='clear'
    alias j='z'

    if type -q eza
        alias ls='eza --icons=auto'
        alias ll='eza -lah --icons=auto --git'
        alias la='eza -a --icons=auto'
        alias lt='eza --tree --icons=auto --level=2'

        # Auto-replace inline "cd " with eza
        function _eza_inline_cd_expand
            if test (commandline -c) = "cd"
                commandline -r "eza --icons=auto --group-directories-first "
            else
                commandline -i ' '
            end
        end
        bind ' ' _eza_inline_cd_expand
    end

    if type -q batcat
        alias cat='batcat'
    else if type -q bat
        alias cat='bat'
    end

    if type -q rg
        alias grep='rg'
    end

    if type -q fd
        alias find='fd'
    end

    # Git
    alias g='git'
    alias gs='git status'
    alias ga='git add'
    alias gaa='git add .'
    alias gc='git commit'
    alias gcm='git commit -m'
    alias gp='git push'
    alias gpf='git push --force-with-lease'
    alias gl='git pull'
    alias gf='git fetch --all --prune'
    alias gd='git diff'
    alias gb='git branch'
    alias gco='git checkout'
    alias gsw='git switch'
    alias glog='git log --graph --decorate --oneline --all'

    # Containers & Kubernetes
    alias d='docker'
    alias dc='docker compose'
    alias dps='docker ps'
    alias di='docker images'
    alias pod='podman'

    alias k='kubectl'
    alias kgp='kubectl get pods'
    alias kgs='kubectl get svc'
    alias kgn='kubectl get nodes'
    alias kctx='kubectl config current-context'

    # Dev Tools
    alias tf='terraform'
    alias py='python3'
    alias pip='pip3'

    # Quick Info
    alias ports='ss -tulpn'
    alias myip='curl -s https://api.ipify.org'
    alias weather='curl wttr.in'

    # Startup Banner
    if type -q fastfetch
        fastfetch
    end

    # At the very bottom of the if status is-interactive block:
    functions --erase ls 2>/dev/null
    function ls --wraps=eza --description 'eza replacement for ls'
        eza --icons=auto --group-directories-first -1 $argv
    end
end

########################################
# FUNCTIONS
########################################

function mkcd
    mkdir -p $argv[1]; and cd $argv[1]
end

function fkill
    ps -ef | sed 1d | fzf -m | awk '{print $2}' | xargs -r kill -9
end

function fcd
    set -l dir (fd --type d --hidden --follow --exclude .git 2>/dev/null | fzf)
    and cd $dir
end

function extract
    if test -f "$argv[1]"
        switch "$argv[1]"
            case '*.tar.bz2'; tar xjf "$argv[1]"
            case '*.tar.gz';  tar xzf "$argv[1]"
            case '*.bz2';     bunzip2 "$argv[1]"
            case '*.rar';     unrar x "$argv[1]"
            case '*.gz';      gunzip "$argv[1]"
            case '*.tar';     tar xf "$argv[1]"
            case '*.tbz2';    tar xjf "$argv[1]"
            case '*.tgz';     tar xzf "$argv[1]"
            case '*.zip';     unzip "$argv[1]"
            case '*.Z';       uncompress "$argv[1]"
            case '*.7z';      7z x "$argv[1]"
            case '*';         echo "Cannot extract '$argv[1]'"
        end
    else
        echo "'$argv[1]' is not a valid file"
    end
end

function gapply
    if test (count $argv) -eq 0
        echo "Usage: gapply <patch_file>"
        return 1
    end

    if git apply $argv 2>/dev/null
        echo "Applied cleanly via git apply."
        return 0
    end

    echo "git apply failed. Falling back to GNU patch merge mode..."
    patch -p0 --merge --batch < "$argv[1]" 2>/dev/null
    or patch -p1 --merge --batch < "$argv[1]" 2>/dev/null
    or true

    set -l conflicted_files
    for f in (git diff --name-only 2>/dev/null)
        if test -f "$f"; and grep -q "^<<<<<<< " "$f" 2>/dev/null
            set -a conflicted_files "$f"
        end
    end

    if test (count $conflicted_files) -gt 0
        echo "Conflict markers detected. Launching meld..."
        for cf in $conflicted_files
            if type -q meld
                meld "$cf"
            else
                echo "Conflict in $cf (please resolve manually)"
            end
        end
    end

    find . -maxdepth 4 \( -name "*.porig" -o -name "*.orig" -o -name "*.bak" \) -delete 2>/dev/null
end
set -e CC; set -e CXX

# devkitPro Switch Homebrew Toolchain
set -gx DEVKITPRO /opt/devkitpro
set -gx DEVKITARM /opt/devkitpro/devkitARM
set -gx DEVKITA64 /opt/devkitpro/devkitA64
fish_add_path $DEVKITPRO/tools/bin $DEVKITA64/bin
