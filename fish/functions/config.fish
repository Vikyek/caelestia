function config --wraps git --description 'Dotfiles git wrapper with auto-symlink resolution and link tracking'
    set -l git_dir $HOME/.cfg/
    set -l work_tree $HOME
    set -l git_exe /usr/bin/git

    if test (count $argv) -gt 0; and test "$argv[1]" = "add"
        set -l targets
        for arg in $argv[2..-1]
            if test -e "$arg"
                # 1. Resolve to the actual file path to stage the content
                set -l real_path (realpath $arg)
                set -a targets $real_path
                
                # 2. Walk up the path and also track any symlinks found along the way
                # This ensures the link structure is preserved in the repo
                set -l current_path (realpath -s $arg)
                while test "$current_path" != "." -a "$current_path" != "/" -a "$current_path" != "$HOME"
                    if test -L "$current_path"
                        set -a targets $current_path
                    end
                    set current_path (dirname "$current_path")
                end
            else
                # Pass through globs or non-existent files as is
                set -a targets $arg
            end
        end
        
        # Remove duplicates and stage everything
        set -l unique_targets (printf "%s\n" $targets | sort -u)
        $git_exe --git-dir=$git_dir --work-tree=$work_tree add $unique_targets
    else
        $git_exe --git-dir=$git_dir --work-tree=$work_tree $argv
    end
end
