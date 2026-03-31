function __kubectl_print_clusters --description "prints all kubernetes clusters"
  kubectl config get-clusters | strip-first-line
end

