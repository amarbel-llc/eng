function kubelogs
  command kubectl logs -f --all-containers=true -l $argv[1] | jql $argv[2..-1]
end

