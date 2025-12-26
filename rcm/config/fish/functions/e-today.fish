function e-today
  set -l file "$PWD"(date +%Y-%m-%d)".md"
  e "$file"
end
