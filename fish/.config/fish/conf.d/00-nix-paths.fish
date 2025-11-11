set -l nix_user    "$HOME/.nix-profile"
set -l nix_default "/nix/var/nix/profiles/default"

for p in $nix_default/bin $nix_user/bin
    if test -d $p
        fish_add_path --prepend --move $p
    end
end

set -l vendor_roots
for root in $nix_user $nix_default
    if test -d $root/share/fish
        set -a vendor_roots $root/share/fish
    end
end

for d in $vendor_roots
    if test -d "$d/vendor_functions.d"
        contains -- "$d/vendor_functions.d" $fish_function_path; or \
            set -gx fish_function_path "$d/vendor_functions.d" $fish_function_path
    end
    if test -d "$d/vendor_completions.d"
        contains -- "$d/vendor_completions.d" $fish_complete_path; or \
            set -gx fish_complete_path "$d/vendor_completions.d" $fish_complete_path
    end
end

for d in $vendor_roots
    if test -d "$d/vendor_conf.d"
        for f in $d/vendor_conf.d/*.fish
            if test -f $f
                source $f
            end
        end
    end
end
