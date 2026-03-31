
function bucket
  grep -o '\d\+' \
  | awk "{print (int(\$1 / "$argv[1]") * "$argv[1]")}" \
  | sort -h \
  | uniq -c
end

