
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
  make_quad(x, y, (width, 0), (0, height), (-width, 0));
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

def draw_tiles_flex(expr x, y, width, tile_width, tile_height, grout, color) =
  begingroup
    save tile_count, width_full_tile, width_remainder;
    tile_count = calc_tiles(width, tile_width);
    tile_count := tile_count - 1;
    width_full_tile := tile_count * (tile_width + grout) + grout;
    width_remainder = width - width_full_tile;

    % left cap
    draw_tiles(
      x - grout, y,
      width_remainder / 2, tile_height,
      1,
      color
    );

    % middle
    draw_tiles_grout(
      x + width_remainder / 2, y,
      tile_width, tile_height,
      grout,
      tile_count,
      color
    );

    % right cap
    draw_tiles(
      x + width_remainder / 2 + width_full_tile - grout, y,
      width_remainder / 2, tile_height,
      1,
      color
    );
  endgroup;
enddef;

def draw_tiles_flex_v(expr x, y, height, tile_width, tile_height, grout, color) =
  begingroup
    save tile_count, height_full_tile, height_remainder;
    tile_count = calc_tiles(height, tile_width);
    tile_count := tile_count - 1;
    height_full_tile := tile_count * (tile_width + grout) + grout;
    height_remainder = height - height_full_tile;

    % left cap
    draw_tiles_v(
      x + grout, y,
      height_remainder / 2, tile_height,
      1,
      color
    );

    % middle
    draw_tiles_v_grout(
      x + grout, y + height_remainder / 2,
      tile_width, tile_height,
      grout,
      tile_count,
      color
    );

    % right cap
    draw_tiles_v(
      x + grout, y + height_remainder / 2 + height_full_tile - grout,
      height_remainder / 2, tile_height,
      1,
      color
    );
  endgroup;
enddef;

def draw_tiles(expr x, y, width, height, count, color) =
  draw_tiles_grout(x, y, width, height, grout, count, color);
enddef;

def draw_tiles_grout(expr x, y, width, height, grout, count, color) =
  for i=0 step 1 until count - 1:
    begingroup
      save xA;
      xA = x + grout + (i * (width + grout));
      draw_tile(xA, y+grout, width, height, color);
    endgroup;
  endfor
enddef;

def draw_tiles_v(expr x, y, width, height, count, color) =
  draw_tiles_v_grout(x, y, width, height, grout, count, color);
enddef;

def draw_tiles_v_grout(expr x, y, width, height, grout, count, color) =
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

% TODO move corner dimension calculation out
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
      corner_w - grout, corner_h - grout,
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
  endgroup;
enddef;

beginfig(1);
  x = 0;
  y = 0;

  width = 0;
  height = 0;

  wall_height = 60;
  wall_width = 50;

  path wall;
  wall = make_rect(0, 0, wall_width, wall_height);
  fill wall withcolor red;

  pickup_tile_pen;

  path main_mosaic;

  frame_depth = trim_width + grout + subway_narrow_half_height;
  frame_depth_with_teeth = frame_depth + grout + subway_width;

  main_mosaic_tiles_h_count = calc_tiles(
    wall_width - frame_depth_with_teeth * 2,
    subway_width
  );

  main_mosaic_tiles_v_count = calc_tiles(
    wall_height - frame_depth_with_teeth * 2,
    subway_height
  );

  main_mosaic_tiles_h_count := main_mosaic_tiles_h_count + 1;

  % main subway mosaic
  width := grout + main_mosaic_tiles_h_count * (grout + subway_width);
  height := grout + main_mosaic_tiles_v_count * (grout + subway_height);

  x := (wall_width - width) / 2;
  main_mosaic_x = x;

  y := subway_width + grout + subway_narrow_half_height + grout + trim_width + grout;
  main_mosaic_y = y;

  main_mosaic = make_rect(x, y, width, height);

  % fill main_mosaic withcolor grout_color;

  % main subway
  draw_subway_with_grout(
    x, y,
    main_mosaic_tiles_h_count, main_mosaic_tiles_v_count,
    true
  );

  hyp = grout;
  sind(45) = adj / hyp;

  % bottom
  begingroup
    save c, o, d, old_p, offset;
    picture old_p;
    old_p = currentpicture;
    currentpicture := image();

    pair o;
    o = (x,y - adj)*u;
    d = trim_width + grout + subway_narrow_half_height + grout + subway_width;

    path c;
    c = o
      -- o + (width, 0)*u
      -- o + (width, 0)*u + (d, -d)*u
      -- o + (width, 0)*u + (d, -d)*u + (-width - d*2, 0)*u
      -- cycle;

    % black trim
    begingroup
      save width_total;
      offset := grout + trim_width;
      width_total = width + offset * 2;

      draw_tiles_flex(
        x - offset, y - offset,
        width_total,
        trim_height, trim_width,
        grout,
        black
      );
    endgroup;

    % white wide half height
    begingroup
      save width_total;
      offset := offset + grout + subway_narrow_half_height;
      width_total = width + offset * 2;

      draw_tiles_flex(
        x - offset, y - offset,
        width_total,
        subway_width, subway_narrow_half_height,
        grout,
        white
      );
    endgroup;

    % white narrow full height
    begingroup
      save width_total;
      offset := offset + grout + subway_width;
      width_total = width + offset * 2;

      draw_tiles_flex(
        x - offset, y - offset,
        width_total,
        subway_height, subway_width,
        grout / 2,
        white
      );
    endgroup;

    clip currentpicture to c;
    addto old_p also currentpicture;
    currentpicture := old_p;
  endgroup;

  % top
  begingroup
    save c, o, d, old_p, offset;
    picture old_p;
    old_p = currentpicture;
    currentpicture := image();

    pair o;
    o = (x,y + height + adj)*u;
    d = trim_width + grout + subway_narrow_half_height + grout + subway_width;

    path c;
    c = o
      -- o + (width, 0)*u
      -- o + (width, 0)*u + (d, d)*u
      -- o + (width, 0)*u + (d, d)*u + (-width - d*2, 0)*u
      -- cycle;

    % black trim
    begingroup
      save width_total, old_offset;
      offset := grout + trim_width;
      width_total = width + offset * 2;

      draw_tiles_flex(
        x - offset, y + height - grout,
        width_total,
        trim_height, trim_width,
        grout,
        black
      );
    endgroup;

    % white wide half height
    begingroup
      save width_total;
      offset := offset + grout + subway_narrow_half_height;
      width_total = width + offset * 2;

      draw_tiles_flex(
        x - offset, y + height + trim_width,
        width_total,
        subway_width, subway_narrow_half_height,
        grout,
        white
      );
    endgroup;

    % white narrow full height
    begingroup
      save width_total;
      offset := offset + grout + subway_width;
      width_total = width + offset * 2;

      draw_tiles_flex(
        x - offset, y + height + grout + trim_width + grout + subway_narrow_half_height,
        width_total,
        subway_height, subway_width,
        grout / 2,
        white
      );
    endgroup;

    clip currentpicture to c;
    addto old_p also currentpicture;
    currentpicture := old_p;
  endgroup;

  % left
  begingroup
    save c, o, d, old_p, offset;
    picture old_p;
    old_p = currentpicture;
    currentpicture := image();

    pair o;
    o = (x - adj,y + height)*u;
    d = trim_width + grout + subway_narrow_half_height + grout + subway_width;

    path c;
    c = o
      -- o + (-d, d)*u
      -- o + (-d, d)*u + (0, - height - d * 2)*u
      -- o + (-d, d)*u + (0, - height - d * 2)*u + (d, d)*u
      -- cycle;

    % black trim
    begingroup
      save width_total, old_offset;
      offset := grout + trim_width;
      width_total = height + offset * 2;

      draw_tiles_flex_v(
        x - offset, y - offset,
        width_total,
        trim_height, trim_width,
        grout,
        black
      );
    endgroup;

    % white wide half height
    begingroup
      save width_total;
      offset := offset + grout + subway_narrow_half_height;
      width_total = height + offset * 2;

      draw_tiles_flex_v(
        x - offset - grout, y - offset - grout,
        width_total,
        subway_width, subway_narrow_half_height,
        grout * 2,
        white
      );
    endgroup;

    % white narrow full height
    begingroup
      save width_total;
      offset := offset + grout + subway_width;
      width_total = height + offset * 2;

      draw_tiles_flex_v(
        x - offset, y - offset,
        width_total,
        subway_height, subway_width,
        grout,
        white
      );
    endgroup;

    clip currentpicture to c;
    addto old_p also currentpicture;
    currentpicture := old_p;
  endgroup;

  % right
  begingroup
    save c, o, d, old_p, offset;
    picture old_p;
    old_p = currentpicture;
    currentpicture := image();

    pair o;
    o = (x + width + adj, y)*u;
    d = trim_width + grout + subway_narrow_half_height + grout + subway_width;

    path c;
    c = o
      -- o + (d, -d)*u
      -- o + (d, -d)*u + (0, height + d * 2)*u
      -- o + (d, -d)*u + (0, height + d * 2)*u + (-d, -d)*u
      -- cycle;

    % black trim
    begingroup
      save width_total, old_offset;
      offset := grout + trim_width;
      width_total = height + offset * 2;

      draw_tiles_flex_v(
        x + width + adj - grout, y - offset,
        width_total,
        trim_height, trim_width,
        grout,
        black
      );
    endgroup;

    % white wide half height
    begingroup
      save width_total;
      offset := offset + grout + subway_narrow_half_height;
      width_total = height + offset * 2;

      draw_tiles_flex_v(
        x + width + trim_width + adj - grout, y - offset - grout,
        width_total,
        subway_width, subway_narrow_half_height,
        grout * 2,
        white
      );
    endgroup;

    % white narrow full height
    begingroup
      save width_total;
      offset := offset + grout + subway_width;
      width_total = height + offset * 2;

      draw_tiles_flex_v(
        x + width + trim_width + grout + subway_narrow_half_height + adj, y - offset,
        width_total,
        subway_height, subway_width,
        grout,
        white
      );
    endgroup;

    clip currentpicture to c;
    addto old_p also currentpicture;
    currentpicture := old_p;
  endgroup;

  % % black trim
  % begingroup
  %   save padding, count_h, count_v, w, h;
  %   w = width + (trim_width + grout) * 2;
  %   h = height + (trim_width + grout) * 2;

  %   padding = trim_height - trim_width;

  %   count_h = calc_tiles(w, trim_width);
  %   count_v = calc_tiles(h - trim_height * 2, trim_height);
  %   rem_v = (h - (count_v * (grout + trim_height) + grout)) / 2;

  %   % h = grout + count_full_v * (trim_height + grout) + 2 * (tile_partial_w + grout);

  %   w := width - padding;
  %   h := height - padding;

  %   draw_frame(
  %     x, y,
  %     width, height,
  %     trim_height, trim_width,
  %     % TODO adjust black trim corner accordingly
  %     rem_v, rem_v,
  %     black
  %   );

  %   % left
  %   draw_tiles_v(
  %     x - trim_width, y + trim_height + grout,
  %     trim_height, trim_width,
  %     count_v,
  %     black
  %   );

  %   % right
  %   draw_tiles_v(
  %     x + width, y + trim_height + grout,
  %     trim_height, trim_width,
  %     count_v,
  %     black
  %   );
  % endgroup;

  % % white half trim
  % begingroup
  %   save corner, expansion;

  %   expansion = (trim_width + grout) * 2;
  %   corner = subway_height + grout + trim_width + grout + subway_narrow_half_height ;
  %   x := x - (expansion / 2);
  %   y := y - (expansion / 2);

  %   draw_frame(
  %     x, y,
  %     width + expansion, height + expansion,
  %     subway_width, subway_narrow_half_height,
  %     corner, corner,
  %     white
  %   );

  %   % TODO don't hardcode addition of half tile

  %   % left
  %   draw_tiles_v_grout(
  %     x - subway_narrow_half_height, y - grout * 2 + trim_width + subway_height,
  %     subway_width, subway_narrow_half_height,
  %     grout * 2,
  %     main_mosaic_tiles_v_count / 2 - 1,
  %     white
  %   );

  %   % right
  %   draw_tiles_v_grout(
  %     x + width + trim_width * 2 + grout * 2, y - grout * 2 + trim_width + subway_height,
  %     subway_width, subway_narrow_half_height,
  %     grout * 2,
  %     main_mosaic_tiles_v_count / 2 - 1,
  %     white
  %   );
  % endgroup;

  % % white full trim
  % begingroup
  %   frame_h = (wall_width - width) / 2;
  %   frame_v = (wall_height - height) / 2;

  %   begingroup
  %     save xA, tile_path, clip_path;

  %     xA = x + trim_width + grout;
  %     path tile_path, clip_path;

  %     picture p;
  %     begingroup
  %       save x, y, o, d;
  %       pair o;

  %       x = main_mosaic_x;
  %       y = main_mosaic_y - grout;
  %       o = (x, y)*u;
  %       d = frame_depth + grout + subway_width;

  %       clip_path = o --
  %         o+(0, -d)*u --
  %         o+(0, -d)*u+(-d, 0)*u --
  %         cycle;

  %     endgroup;

  %     p = image();

  %     for i=0 step 1 until 4:
  %       % clip with function y = x + frame_v - frame_h;
  %       tile_path := make_rect(
  %         xA, 
  %         y - subway_width - grout - subway_narrow_half_height - grout,
  %         subway_height, 
  %         subway_width
  %       );

  %       addto p contour tile_path withcolor white;
  %       % clip currentpicture to clip_path;
  %       % draw_tile(
  %       %   xA,
  %       %   subway_height,
  %       %   subway_width,
  %       %   white
  %       % );

  %       xA := xA - grout / 2 - subway_height;
  %     endfor

  %     clip p to clip_path;
  %     addto currentpicture also p;
  %   endgroup;

  %   % bottom
  %   draw_tiles_grout(
  %     x + trim_width + grout, y - subway_width - grout - subway_narrow_half_height - grout,
  %     subway_height, subway_width,
  %     grout / 2,
  %     main_mosaic_tiles_h_count * 2,
  %     white
  %   );

  %   % top
  %   draw_tiles_grout(
  %     x + trim_width + grout, y + height + trim_width + frame_depth + grout * 2,
  %     subway_height, subway_width,
  %     grout / 2,
  %     main_mosaic_tiles_h_count * 2,
  %     white
  %   );

  %   % left
  %   draw_tiles_v_grout(
  %     x - subway_width - subway_narrow_half_height - grout, y + trim_width,
  %     subway_height, subway_width,
  %     grout,
  %     main_mosaic_tiles_v_count,
  %     white
  %   );

  %   % right
  %   draw_tiles_v_grout(
  %     x + width + grout + trim_width + frame_depth + grout,
  %     y + trim_width,
  %     subway_height, subway_width,
  %     grout,
  %     main_mosaic_tiles_v_count,
  %     white
  %   );
  % endgroup;

  % excess
  begingroup
    save excess;
    path excess;
    clip currentpicture to wall;
    % pickup pencircle scaled 3pt;
    % draw wall withcolor red dashed evenly scaled 4;
  endgroup;

endfig;
end;
