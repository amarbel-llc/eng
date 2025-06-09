
% TODO move macros to own file

u = 1cm;
defaultscale := u / 10;

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

def roundto(expr x, places) = 
  (round(x * (10**places))) / (10**places)
enddef;

def get_canvas = 
  begingroup
    save ll, ur, canvas_width, canvas_height;

    pair ll, ur;
    numeric canvas_width, canvas_height;

    picture current_picture_copy;
    current_picture_copy := currentpicture;

    ll := llcorner current_picture_copy;
    ur := urcorner current_picture_copy;

    canvas_width := xpart(ur - ll);
    canvas_height := ypart(ur - ll);

    make_rect(xpart(ll)/u, ypart(ll)/u, canvas_width/u, canvas_height/u)
  endgroup
enddef;

def fillbackground(expr c) = 
  begingroup
    save current_picture_copy, canvas;

    picture current_picture_copy;
    current_picture_copy := currentpicture;

    path canvas;
    canvas := get_canvas;

    fill canvas withcolor background;
    addto currentpicture also current_picture_copy;
  endgroup;
enddef;

def label_dim(expr dimX, dimY)(text loc) = 
  save c;
  color c;
  c = red;

  label(decimal(roundto(dimX, 2)), loc) shifted (0, 1u) withcolor c;

  label("x", loc) shifted (0, 0u) withcolor c;

  label(decimal(roundto(dimY, 2)), loc) shifted (0, -1u) withcolor c;
enddef;

def label_width(expr x, y, width, arrowLength, lineWidth) = 
  save c;
  color c;
  c = red;

  ahlength := arrowLength;
  drawdblarrow((x, y)*u .. (x+width, y)*u) withcolor red withpen pencircle scaled lineWidth;

  label(decimal(roundto(width, 2)), (width / 2 + x, y)*u) shifted (0, 1u) withcolor c;
enddef;

def label_height(expr x, y, height, arrowLength, lineWidth) = 
  save c;
  color c;
  c = red;

  ahlength := arrowLength;
  drawdblarrow((x, y)*u .. (x, y+height)*u) withcolor red withpen pencircle scaled lineWidth;

  label(decimal(roundto(height, 2)), (x, height / 2 + y)*u) shifted (1u, 0) withcolor c;
enddef;

def make_rect(expr x, y, width, height) =
  make_quad(x, y, (width, 0), (0, height), (-width, 0))
enddef;

def make_quad(expr x, y, a, b, c) =
  begingroup
    save o;
    pair o;

    o = (x, y)*u;

    o -- o+a*u -- o+a*u+b*u -- o+a*u+b*u+c*u -- cycle
  endgroup
enddef;

def clipoutside(expr p) =
  begingroup
    save boundary;
    path boundary;

    boundary := make_rect(0, 0, 100, 100);

    clip boundary -- reverse p -- cycle;
  endgroup;
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
    save x, y, isEven, stepSize;
    x = 0;
    y = 0;

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
  save x, y, wall, main_mosaic_tiles_h_count, main_mosaic_tiles_v_count;

  x = 0;
  y = 0;

  path wall;
  wall = make_rect(0, 0, wall_width, wall_height);
  unfill wall;

  pickup_tile_pen;

  path main_mosaic;

  numeric frame_depth, frame_depth_with_teeth;

  begingroup
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
  endgroup;

  main_mosaic_tiles_h_count := main_mosaic_tiles_h_count + 1;

  % main subway mosaic
  width := grout + main_mosaic_tiles_h_count * (grout + subway_width);
  height := grout + main_mosaic_tiles_v_count * (grout + subway_height);

  x := (wall_width - width) / 2;
  main_mosaic_x := x;

  y := subway_width + grout + subway_narrow_half_height + grout + trim_width + grout;
  main_mosaic_y := y;

  main_mosaic = make_rect(x, y, width, height);


  % main subway
  draw_subway_with_grout(
    x, y,
    main_mosaic_tiles_h_count, main_mosaic_tiles_v_count,
    true
  );

  % frame
  begingroup
    save hyp, adj;

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

    side := subway_width + grout + subway_narrow_half_height + grout + trim_width + grout + subway_height;

    % trim overlaps
    begingroup
      save cutoutWidth;
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
          x + width - subway_height + grout*2, y + subway_height - trim_width,
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
          x + width - subway_height + grout, y + height - subway_height - grout,
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

      % background
      fillbackground(background);

    endgroup;
  endgroup;
enddef;

def draw_dimensions = 
  % dimensions 1
  begingroup
    save w, h, leftmost;
    w = wall_width;
    h = wall_height / 2;
    leftmost = main_mosaic_x - frame_depth_with_teeth;

    % total wall
    label_width(0, h-1subway_height, w, u/2, 3pt);
    label_height(wall_width / 2 + 1subway_width, 0, wall_height, u/2, 3pt);

    % subway wall
    label_width(main_mosaic_x, h+subway_height, width, u/2, 3pt);
    label_height(wall_width / 2 + 2subway_width, main_mosaic_y, height, u/2, 3pt);

    % subway tile and frame cutoff
    label_width(0, h+subway_height*2, subway_width+leftmost, u/2, 3pt);
  endgroup;

  % dimensions 2
  begingroup
    label_dim(
      subway_height, subway_height, 
      (x + subway_height / 2, y + subway_height * 1.5)*u
    );

    label_dim(
      subway_height - trim_width, subway_height - trim_width,
      (x + (subway_height - trim_width) / 2, y + (subway_height - trim_width) / 2)*u
    );
  endgroup;

  % alignment guides
  begingroup
    save p;
    path p;

    pickup pencircle scaled 3pt;

    % guides
    p := (x + grout, 0)*u -- (x + grout, y + height)*u;
    draw p withcolor red dashed evenly scaled 4;

    p := (x + width, 0)*u -- (x + width, y + height)*u;
    draw p withcolor red dashed evenly scaled 4;
  endgroup;
enddef;

tile_surface_height = 97;

beginfig(0)
  draw_wall(58, tile_surface_height);
endfig;

beginfig(1)
  draw_wall(28, tile_surface_height);
endfig;

beginfig(2)
  draw_wall(50, tile_surface_height);
endfig;

beginfig(3)
  numeric wall_width, vanity_depth;
  wall_width := 58;
  vanity_depth = 24.75;

  numeric door_height, door_width;
  door_height = tile_surface_height - (14+5/8); 
  door_width = wall_width - vanity_depth;

  draw_wall(wall_width, tile_surface_height);

  % picture vanity_picture;
  % vanity_picture = currentpicture;
  % currentpicture := nullpicture;

  % draw_wall(door_width, tile_surface_height);

  % picture door_picture;
  % door_picture = currentpicture;
  % currentpicture := nullpicture;

  % addto currentpicture also vanity_picture;
  % addto currentpicture also door_picture shifted (vanity_depth*u, 0);

  path vanity_wall;
  vanity_wall = make_rect(0, 0, vanity_depth, tile_surface_height);

  % clip currentpicture to vanity_wall;

  path wall;
  wall = make_rect(0, 0, wall_width, tile_surface_height);

  % % background
  % fill wall withcolor background;

  % % draw_wall(59.25, tile_surface_height);
  main_mosaic_tiles_h_count := calc_tiles(wall_width, subway_width);
  main_mosaic_tiles_v_count := calc_tiles(tile_surface_height, subway_height);

  % % main subway
  % draw_subway_with_grout(
  %   0, 0,
  %   main_mosaic_tiles_h_count, main_mosaic_tiles_v_count,
  %   true
  % );

  path door;
  door = make_rect(24.75, 0, door_width, door_height);

  path wall_with_hole;
  wall_with_hole = wall -- reverse door -- cycle;

  clip currentpicture to wall_with_hole;
  % draw_dimensions;
  fill door withcolor blue;
  draw_dimensions;

  % draw (0, frame_depth_with_teeth)*u -- (wall_width, frame_depth_with_teeth)*u withcolor red dashed evenly scaled 4;
endfig;

end;
