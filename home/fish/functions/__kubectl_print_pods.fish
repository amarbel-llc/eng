function __kubectl_print_pods
  if test -n "$argv[1]"
    kubectl get pods -n "$argv[1]" -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace | strip-first-line | spaces-to-tabs | cut -f1,2
  else
    kubectl get pods --all-namespaces -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace | strip-first-line | spaces-to-tabs | cut -f1,2
  end
end

