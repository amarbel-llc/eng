function __kubectl_print_contexts --description "prints all contexts"
  kubectl config get-contexts -o name
end

