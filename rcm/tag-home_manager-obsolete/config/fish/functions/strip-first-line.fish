function strip-first-line --description "helper function that uses awk to drop the first line of input"
  awk '{if(NR>1)print}'
end
