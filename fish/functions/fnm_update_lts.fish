function fnm_update_lts
    echo "🔄 Updating Node LTS..."

    # install latest LTS
    fnm install --lts

    # detect current version
    set new_version (fnm current)

    # set as default
    fnm default $new_version

    echo "✅ Now using Node $new_version"
end
