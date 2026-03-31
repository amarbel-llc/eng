
complete \
  --command gcloud \
  --no-files \
  --arguments "(__complete_with config set project __gcloud_print_projects)"

complete \
  --command gcloud \
  --no-files \
  --arguments "(__complete_with config configurations activate __gcloud_print_configurations)"

function __gcloud_q
  command gcloud $argv ^ /dev/null
end

function __gcloud_print_projects
  __gcloud_q projects list | strip-first-line | spaces-to-tabs | cut -f1,2
end

function __gcloud_print_configurations
  __gcloud_q config configurations list | strip-first-line | awk '{ print $1, "\t", $4",", $5 }'
end

