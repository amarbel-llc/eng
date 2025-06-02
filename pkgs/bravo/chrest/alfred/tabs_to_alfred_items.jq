#! /usr/bin/env -S jq -f

{
  items: [
    .[]
    | {
      title: .title,
      subtitle: .url,
      arg: .id
    }
  ]
}
