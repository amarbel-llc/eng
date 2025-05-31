
u = 1cm;

background := 0.7white;
grout = 1/16;

subway_width = 6;
subway_height = 3;

subway_narrow_width = 6;
subway_narrow_height = 1.5;

subway_narrow_half_width = 3;
subway_narrow_half_height = 1.5;

trim_width = 3/8;
trim_height = 7+7/8;

wall_height = 60;
wall_width = 28;

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
      x - grout*2, y,
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
      x + grout, y - grout,
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

def draw_wall(expr wall_width, wall_height) = 
  x = 0;
  y = 0;

  show wall_width, wall_height;

  path wall;
  wall = make_rect(0, 0, wall_width, wall_height);
  unfill wall;

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
  width = grout + main_mosaic_tiles_h_count * (grout + subway_width);
  height = grout + main_mosaic_tiles_v_count * (grout + subway_height);

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

  % trim overlaps
  begingroup
    save side, cutoutWidth;
    side = subway_width + grout + subway_narrow_half_height + grout + trim_width + grout + subway_height;
    cutoutWidth = trim_width + grout*2;

    % trim overlap bottom left
    begingroup
      save c, northEast;

      pair northEast;

      northEast = (
        x + subway_height - cutoutWidth + grout,
        y + subway_height - cutoutWidth + grout*2
      );

      path c;

      c = northEast*u 
        -- northEast*u - (side, 0)*u
        -- northEast*u - (side, -cutoutWidth)*u
        -- northEast*u - (-cutoutWidth, -cutoutWidth)*u
        -- northEast*u - (-cutoutWidth, side)*u
        -- northEast*u - (0, side)*u
        -- cycle;

      unfill c;

      draw_tiles_flex(
        x + subway_height - side, y + subway_height - trim_width,
        side,
        trim_height, trim_width,
        grout,
        black
      );

      draw_tiles_flex_v(
        x + subway_height - trim_width - grout, y - side + subway_height - trim_width,
        side,
        trim_height, trim_width,
        grout,
        black
      );
    endgroup;

    % trim overlap bottom right
    begingroup
      save c, northWest;

      pair northWest;

      northWest = (
        x + width - subway_height + cutoutWidth,
        y + subway_height - cutoutWidth + grout*2
      );

      path c;

      c = northWest*u 
        -- northWest*u + (side, 0)*u
        -- northWest*u + (side, cutoutWidth)*u
        -- northWest*u + (-cutoutWidth, cutoutWidth)*u
        -- northWest*u + (-cutoutWidth, -side)*u
        -- northWest*u + (0, -side)*u
        -- cycle;

      unfill c;

      draw_tiles_flex(
        x + width - subway_height + grout, y + subway_height - trim_width,
        side,
        trim_height, trim_width,
        grout,
        black
      );

      draw_tiles_flex_v(
        x + width - subway_height, y - side + subway_height - trim_width,
        side,
        trim_height, trim_width,
        grout,
        black
      );
    endgroup;

    % trim overlap top right
    begingroup
      save c, southWest;

      pair southWest;

      southWest = (
        x + width - subway_height + cutoutWidth - grout,
        y + height - subway_height - grout + cutoutWidth
      );

      path c;

      c = southWest*u 
        -- southWest*u + (side, 0)*u
        -- southWest*u + (side, -cutoutWidth)*u
        -- southWest*u + (-cutoutWidth, -cutoutWidth)*u
        -- southWest*u + (-cutoutWidth, side)*u
        -- southWest*u + (0, side)*u
        -- cycle;

      unfill c;

      draw_tiles_flex(
        x + width - subway_height, y + height - subway_height - grout,
        side,
        trim_height, trim_width,
        grout,
        black
      );

      draw_tiles_flex_v(
        x + width - subway_height - grout, y + height - subway_height - grout,
        side,
        trim_height, trim_width,
        grout,
        black
      );
    endgroup;

    % trim overlap top left
    begingroup
      save c, southEast;

      pair southEast;

      southEast = (
        x + subway_height - cutoutWidth + grout,
        y + height - subway_height + cutoutWidth - grout
      );

      path c;

      c = southEast*u 
        -- southEast*u + (-side, 0)*u
        -- southEast*u + (-side, -cutoutWidth)*u
        -- southEast*u + (cutoutWidth, -cutoutWidth)*u
        -- southEast*u + (cutoutWidth, side)*u
        -- southEast*u + (0, side)*u
        -- cycle;

      unfill c;

      draw_tiles_flex(
        x + subway_height - side, y + height - subway_height - grout,
        side,
        trim_height, trim_width,
        grout,
        black
      );

      draw_tiles_flex_v(
        x + subway_height - trim_width - grout, y + height - subway_height,
        side,
        trim_height, trim_width,
        grout,
        black
      );
    endgroup;
  endgroup;

  % excess
  begingroup
    save excess;
    path excess;
    clip currentpicture to wall;
    % pickup pencircle scaled 3pt;
    % draw wall withcolor red dashed evenly scaled 4;
  endgroup;
enddef;

end;
