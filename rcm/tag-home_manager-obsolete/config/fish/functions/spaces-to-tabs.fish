function spaces-to-tabs --description "helper function that uses sed to separate 2 or more spaces into tabs"
  sed 's/[[:space:]][[:space:]][[:space:]]*/'\t'/g'
end
