function try
  if test -e ./bin/jenkins/try > /dev/null
    ./bin/jenkins/try $argv
  else
    command try $argv
  end
end

