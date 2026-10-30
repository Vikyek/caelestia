function gapply --description 'Apply patch using git apply first, falling back to GNU patch merge mode with automatic meld conflict resolution'
    set -l patch_file $argv[1]
    if test -z "$patch_file"
        echo "Usage: gapply <patch_file>"
        return 1
    end

    # Stage 1: Try strict git apply
    if git apply $argv 2>/dev/null
        echo "Applied cleanly via git apply."
        return 0
    end

    echo "git apply failed. Falling back to GNU patch merge mode..."
    # Stage 2: Fall back to GNU patch with --merge (inserts conflict markers)
    patch -p0 --merge --batch < $patch_file
    set -l patch_status $status
    if test $patch_status -gt 1
        echo "Trying with -p1 strip level..."
        patch -p1 --merge --batch < $patch_file
    end

    # Stage 3: Scan working tree for conflict markers and launch meld instantly
    set -l conflicted_files
    for f in (git diff --name-only 2>/dev/null)
        if test -f "$f"
            if grep -q "^<<<<<<< " "$f" 2>/dev/null
                set -a conflicted_files "$f"
            end
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

    # Stage 4: Clean backup files
    find . -maxdepth 4 \( -name "*.porig" -o -name "*.orig" -o -name "*.bak" \) -delete 2>/dev/null
end
