
u=1cm;

grout=1/16;
color grout_color;
grout_color=blue;
subway_width=6;
subway_height=3;

subway_narrow_width=6;
subway_narrow_height=1.5;

subway_narrow_half_width=3;
subway_narrow_half_height=1.5;

trim_width=3/8;
trim_height=7+7/8;

def pickup_tile_pen =
  pickup pencircle scaled 2pt;
enddef;

def make_rect(expr x, y, width, height) =
  (x*u,y*u)--((x+width)*u,y*u)--((x+width)*u,(y+height)*u)--(x*u,(y+height) * u)--cycle;
enddef;

def make_rect_cutoff(expr x, y, width, height) =
  % begingroup
  %   save x1, y1, x2, y2, x3, y3, x4, y4;
  %   % z1 = (x*u, y*u);
  %   % o = (x*u, y*u);

  %   % o -- o+a*u -- o+a*u+b*u -- o+a*u+b*u+c*u --cycle;
  % endgroup;

  begingroup
    save a, b, c, d;
    pair a, b, c, d;

    a = (x,y);
    b = (x+width,y);
    c = (x+width,y+height);
    d = (x,y+height);

    a*u -- b*u -- c*u -- d*u -- cycle
  endgroup
enddef;

def make_quad(expr x, y, a, b, c) =
  begingroup
    save o;
    pair o;

    o = (x, y)*u;

    o -- o+a*u -- o+a*u+b*u -- o+a*u+b*u+c*u -- cycle
  endgroup
enddef;

def draw_tile(expr x, y, width, height, color) =
  begingroup
    save p;
    path p;
    p := make_rect(x, y, width, height);
    % draw p;
    fill p withcolor color;
  endgroup
enddef;

def draw_tiles(expr x, y, width, height, count, color) =
  for i=0 step 1 until count - 1:
    begingroup
      save xA;
      xA = x + grout + (i * (width + grout));
      draw_tile(xA, y+grout, width, height, color);
    endgroup;
  endfor
enddef;

def draw_tiles_v(expr x, y, width, height, count, color) =
  for i=0 step 1 until count - 1:
    begingroup
      save yA;
      yA = y + grout + (i * (width + grout));
      draw_tile(x, yA+grout, height, width, color);
    endgroup;
  endfor
enddef;

def calc_tiles(expr extent, tile_width) = 
  floor((extent - grout) / (tile_width + grout));
enddef;

def draw_subway_row_with_grout_odd(expr xA, yA, tile_w, tile_h, h_tile_count, color) =
  begingroup
    save xOffset, half;
    xOffset = xA;
    half = tile_h - (grout / 2);

    draw_tiles(xA, yA, half, tile_h, 1, color);
    xOffset := xOffset + half + grout;

    draw_tiles(xOffset, yA, tile_w, tile_h, h_tile_count - 1, color);
    xOffset := xOffset + ((h_tile_count - 1) * (tile_w + grout));

    draw_tiles(xOffset, yA, half, tile_h, 1, color);
  endgroup;
enddef;

def draw_subway_with_grout(expr xA, yA, h_tile_count, v_tile_count, evenFirst) =
  begingroup
    save x, y;
    x = 0;
    y = 0;
    path bg;

    stepSize := subway_height + grout;
    boolean isEven;
    isEven := evenFirst;

    % draw the evens
    for i=0 step 1 until v_tile_count - 1:
      begingroup
        save y;

        y = i*(subway_height + grout);

        if isEven:
          draw_tiles(xA, y+yA, subway_width, subway_height, h_tile_count, white);
          isEven := false;
        else:
          draw_subway_row_with_grout_odd(xA, y+yA, subway_width, subway_height, h_tile_count, white);
          isEven := true;
        fi
      endgroup;
    endfor
  endgroup;
enddef;

% assumes the inner border is grout
def draw_frame_corners_around(expr x, y, width, height, tile_w, tile_h, corner_w, corner_h, color) =
  begingroup
    save r, adj, hyp, w, h;

    w = width + tile_h * 2;
    h = height;

    % bottom corners
    path r;

    hyp = grout;
    sind(45) = adj / hyp;

    % bottom left
    r = make_quad(
      x - tile_h + adj, y - tile_h,
      (tile_h, tile_h),
      (corner_w - tile_h - adj, 0),
      (0, - tile_h)
    );

    fill r withcolor color;

    % top left
    r := make_quad(
      x - tile_h + adj, y + height + tile_h,
      (tile_h, -tile_h),
      (corner_w - tile_h - adj, 0),
      (0, tile_h)
    );

    fill r withcolor color;

    % left bottom
    r := make_quad(
      x - tile_h, y - tile_h + adj,
      (tile_h, tile_h),
      (0, corner_w - tile_h - adj),
      (-tile_h, 0)
    );

    fill r withcolor color;

    % left top
    r := make_quad(
      x - tile_h, y + height + tile_h - adj,
      (tile_h, -tile_h),
      (0, -(corner_w - tile_h - adj)),
      (-tile_h, 0)
    );

    fill r withcolor color;

    % bottom right
    r := make_quad(
      x + w - adj - corner_w + grout - tile_h, y - tile_h,
      (0, tile_h),
      (corner_w - tile_h - adj, 0),
      (tile_h, - tile_h)
    );

    fill r withcolor color;

    % top right
    r := make_quad(
      x + w - adj - corner_w + grout - tile_h, y + height + tile_h,
      (0, -tile_h),
      (corner_w - tile_h - adj, 0),
      (tile_h, tile_h)
    );

    fill r withcolor color;

    % right bottom
    r := make_quad(
      x + w - tile_h, y - tile_h + adj,
      (-tile_h, tile_h),
      (0, corner_w - tile_h),
      (tile_h, 0)
    );

    fill r withcolor color;

    % right top
    r := make_quad(
      x + w - tile_h, y + h + tile_h - adj,
      (-tile_h, - tile_h),
      (0, - corner_w + tile_h),
      (tile_h, 0)
    );

    fill r withcolor color;
  endgroup;
enddef;

def draw_frame(expr x, y, width, height, tile_w, tile_h, corner_w, corner_h, color) =
  begingroup
    save padding, count_h, count_v, w, h, rem_w, rem_h;

    w = width + (tile_h + grout) * 2;
    h = height + (tile_h + grout) * 2;

    path p;

    p = make_quad(
      x - tile_h - grout,
      y,
      (w, 0),
      (0, - tile_h - grout),
      (-w, 0)
    );

    % fill p withcolor green;

    count_h = calc_tiles(w - corner_w, tile_w);
    count_v = calc_tiles(h - corner_h, tile_w);

    rem_w = (w - (count_h * (grout + tile_w) + grout)) / 2;
    rem_h = (h - (count_v * (grout + tile_w) + grout)) / 2;

    draw_frame_corners_around(
      x, y,
      width, height,
      tile_w, tile_h,
      min(corner_w, rem_w) - grout, min(corner_h, rem_h) - grout,
      color
    );

    % bottom
    draw_tiles(
      x + rem_w - tile_h - grout, y - tile_h - grout,
      tile_w, tile_h,
      count_h,
      color
    );

    % top
    draw_tiles(
      x + rem_w - tile_h - grout, y + h - (tile_h + grout) * 2 - grout,
      tile_w, tile_h,
      count_h,
      color
    );

    % left
    draw_tiles_v(
      x - tile_h, y + rem_h - tile_h - grout,
      tile_w, tile_h,
      count_v,
      blue
    );
  endgroup;
enddef;

beginfig(1);
  x = 0;
  y = 0;

  width = 0;
  height = 0;

  wall_height = 60;
  wall_width = 58;

  path wall;
  wall = make_rect(0, 0, wall_width, wall_height);
  fill wall withcolor red;

  pickup_tile_pen;

  path main_mosaic;
  main_mosaic_tiles_h_count = calc_tiles(45, subway_width);
  main_mosaic_tiles_v_count = calc_tiles(wall_height - 20, subway_height);

  % main subway mosaic
  width := grout + main_mosaic_tiles_h_count * (grout + subway_width);
  height := grout + main_mosaic_tiles_v_count * (grout + subway_height);

  x := (wall_width - width) / 2;
  y := (wall_height - height) / 2;

  main_mosaic = make_rect(x, y, width, height);

  % fill main_mosaic withcolor grout_color;

  draw_subway_with_grout(
    x, y,
    main_mosaic_tiles_h_count, main_mosaic_tiles_v_count,
    true
  );

  % black trim
  begingroup
    save padding, count_h, count_v, w, h;
    w = width + (trim_width + grout) * 2;
    h = height + (trim_height + grout) * 2;

    padding = trim_height - trim_width;

    count_h = calc_tiles(w, trim_width);
    count_v = calc_tiles(h, trim_height);

    w := width - padding;
    h := height - padding;

    draw_frame(
      x, y,
      width, height,
      trim_height, trim_width,
      trim_height, trim_height,
      black
    );
  endgroup;

  % % white half trim
  begingroup
    save corner, expansion;

    expansion = (trim_width + grout) * 2;
    corner = subway_height + grout + trim_width + grout + subway_narrow_half_height ;
    x := x - (expansion / 2);
    y := y - (expansion / 2);

    draw_frame(
      x, y,
      width + expansion, height + expansion,
      subway_width, subway_narrow_half_height,
      corner, corner,
      white
    );
  endgroup;

  % excess
  begingroup
    save excess;
    path excess;
    pickup pencircle scaled 3pt;
    draw wall withcolor red dashed evenly scaled 4;
    % draw excess
  endgroup;

endfig;
end;
