# TODO move to devenv-go
function go-refactor
  if test (count $argv) -lt 3
    echo "Not enough arguments" >&2
    return 1
  end

  set -l pattern $argv[1]
  set -l replacement $argv[2]
  set -l files $argv[3..-1]
  set -l base_gofmt_cmd gofmt -r "$pattern -> $replacement"
  set -l file_diff (mktemp)
  $base_gofmt_cmd -d $files > $file_diff

  if test (wc -l < $file_diff) -eq 0
    echo "Refactor produces no changes" >&2
    return 1
  else
    less "$file_diff"
  end

  set -l prompt_cmd "Proceed with refactor? (Y/n):" >&2
  set -l answer (read -n 1 -l -P $prompt_cmd)
  if test (string lower $answer) = y
    $base_gofmt_cmd -w $files
  end

  goimports -w $files
end

