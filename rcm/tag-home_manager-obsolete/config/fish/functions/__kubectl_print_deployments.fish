function __kubectl_print_deployments --description "prints all kubernetes deployments"
  kubectl get deployments | strip-first-line | spaces-to-tabs | cut -f1
end

