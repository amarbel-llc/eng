function mr-build-and-watch2
  set -l file $argv[1]
  set -l format $argv[2]
  fswatch -o0 $file | xargs -0 -L1 bash -c "echo $file changed && zit format-zettel -mode blob $format $file | timg --center --clear --upscale -"
end
