
function plot-histogram
  set -l binwidth $argv[1]
  grep -o '\d\+' \
  | gnuplot -p -e "
  set terminal dumb;
  set boxwidth 0.5;
  set style fill solid;
  set autoscale;

  binwidth=$binwidth;
  bin(x,width)=width*floor(x/width);

  plot \"/dev/stdin\" using (bin(\$1,binwidth)):(1.0) smooth freq with boxes notitle;
  "
end
