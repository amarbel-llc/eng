
function __kubectl_c
  complete \
    --command kubectl \
    --no-files \
    --arguments "$argv"
end

__kubectl_c "(__complete_with config set-cluster __kubectl_print_clusters)"
__kubectl_c "(__complete_with config use-context __kubectl_print_contexts)"
__kubectl_c "(__complete_with logs __kubectl_print_pods)"
__kubectl_c "(__complete_with exec -it __kubectl_print_pods)"
__kubectl_c "(__complete_with describe __kubectl_print_pods)"
__kubectl_c "(__complete_with delete pod __kubectl_print_pods)"
__kubectl_c "(__complete_with delete deployment __kubectl_print_deployments)"
__kubectl_c "(__complete_with edit deployment __kubectl_print_deployments)"
__kubectl_c "(__complete_with apply -f __kubectl_print_yaml_configs)"

