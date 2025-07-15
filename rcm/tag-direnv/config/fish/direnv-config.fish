
function __direnv_export_eval --on-event fish_prompt;
	"/nix/store/g0y8q1v5gash235qqbw5187bd4qsp149-direnv-2.37.0/bin/direnv" export fish | source;

	if test "$direnv_fish_mode" != "disable_arrow";
		function __direnv_cd_hook --on-variable PWD;
			if test "$direnv_fish_mode" = "eval_after_arrow";
				set -g __direnv_export_again 0;
			else;
				"/nix/store/g0y8q1v5gash235qqbw5187bd4qsp149-direnv-2.37.0/bin/direnv" export fish | source;
			end;
		end;
	end;
end;

function __direnv_export_eval_2 --on-event fish_preexec;
	if set -q __direnv_export_again;
		set -e __direnv_export_again;
		"/nix/store/g0y8q1v5gash235qqbw5187bd4qsp149-direnv-2.37.0/bin/direnv" export fish | source;
		echo;
	end;

	functions --erase __direnv_cd_hook;
end;
