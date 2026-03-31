function essence --description "generate a diff gist from the current git repo"
  switch (count $argv)
  case '0'
    __essence_gist_head

  case '1'
    set repo_name (basename (git rev-parse --show-toplevel))
    set range (git rev-parse $argv)..(git rev-parse HEAD)
    set gist_description "$repo_name: $range"
    git show $argv..HEAD | gist -t diff -d "$gist_description"

  case '*'
    echo 'Unsupported argument count'
    return 1
  end
end

function __essence_gist_head
  set repo_name (basename (git rev-parse --show-toplevel))
  set head_commit (git show --oneline --no-patch HEAD)
  set gist_description "$repo_name: $head_commit"
  git show HEAD | gist -t diff -d "$gist_description"
end
