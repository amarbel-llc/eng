
    function __direnv_export_eval --on-event fish_prompt;
        "/nix/store/vip71i9w458y607adcja01ik8lbq5n4g-direnv-2.36.0/bin/direnv" export fish | source;

        if test "$direnv_fish_mode" != "disable_arrow";
            function __direnv_cd_hook --on-variable PWD;
                if test "$direnv_fish_mode" = "eval_after_arrow";
                    set -g __direnv_export_again 0;
                else;
                    "/nix/store/vip71i9w458y607adcja01ik8lbq5n4g-direnv-2.36.0/bin/direnv" export fish | source;
                end;
            end;
        end;
    end;

    function __direnv_export_eval_2 --on-event fish_preexec;
        if set -q __direnv_export_again;
            set -e __direnv_export_again;
            "/nix/store/vip71i9w458y607adcja01ik8lbq5n4g-direnv-2.36.0/bin/direnv" export fish | source;
            echo;
        end;

        functions --erase __direnv_cd_hook;
    end;
