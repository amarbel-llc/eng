function __essence_get_heads
  __essence_get_tags
  __essence_get_branches
end

function __essence_get_tags
  command git tag
end

function __essence_get_branches
  command git branch --list | string trim -c ' *'
  echo origin/master
end

complete -c essence -f -x -a '(__essence_get_heads)'
