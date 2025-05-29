u=1in;

grout=1/16;
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

def make_tile_path_rect(expr x, y, width, height) =
  (x*u,y*u)--((x+width)*u,y*u)--((x+width)*u,(y+height)*u)--(x*u,(y+height) * u)--cycle;
enddef;

def draw_tile(expr x, y, width, height, color) =
  begingroup
    save p;
    path p;
    p := make_tile_path_rect(x, y, width, height);
    draw p;
    fill p withcolor color;
  endgroup
enddef;

def draw_subway_with_grout(expr xa, ya, width, height) =
  begingroup
    save x, y;
    path bg;

    bg = (xA*u, yA*u) -- ((xA + width) * u, yA*u) -- ((xA + width)*u, (yA + height)*u) -- (xA*u, (yA + height)*u) -- cycle;

    fill bg withcolor red;

    % draw the evens
    for y=0 step subway_height * 2 + grout until height:
      for x=0 step subway_width until width - subway_width:
        % regular subway
        draw_tile(x+xA, y+yA, subway_width, subway_height, white);
      endfor
    endfor

    % draw the odds
    for y=subway_height step subway_height * 2 until height:
      % left square
      draw_tile(xA, y+yA, subway_width / 2, subway_height, white);

      % regular subway
      for x=(subway_width / 2) step subway_width until width - (subway_width / 2) - subway_width:
        draw_tile(x+xA, y+yA, subway_width, subway_height, white);
      endfor

      % right square
      draw_tile(xA + width - (subway_width / 2), y+yA, subway_width / 2, subway_height, white);
    endfor
  endgroup;
enddef;

def draw_subway(expr xA, yA, width, height) =
  begingroup
    save x, y;

    % draw the evens
    for y=0 step subway_height * 2 until height:
      for x=0 step subway_width until width - subway_width:
        % regular subway
        draw_tile(x+xA, y+yA, subway_width, subway_height, white);
      endfor
    endfor

    % draw the odds
    for y=subway_height step subway_height * 2 until height:
      % left square
      draw_tile(xA, y+yA, subway_width / 2, subway_height, white);

      % regular subway
      for x=(subway_width / 2) step subway_width until width - (subway_width / 2) - subway_width:
        draw_tile(x+xA, y+yA, subway_width, subway_height, white);
      endfor

      % right square
      draw_tile(xA + width - (subway_width / 2), y+yA, subway_width / 2, subway_height, white);
    endfor
  endgroup
enddef;

wall_height = 60;
wall_width = 28;

beginfig(1);
  y=0;
  x=0;

  path wall;
  wall := origin -- (wall_width*u, 0) -- (wall_width*u, wall_height*u) -- (0, wall_height*u) -- cycle;
  fill wall withcolor red;

  pickup_tile_pen;

  mosaic_width = (round((wall_width - subway_width * 2 - trim_width - subway_height - 2) / subway_width)) * subway_width;

  mosaic_x = (wall_width - mosaic_width) / 2;
  draw_subway(mosaic_x, y, mosaic_width, wall_height);

  frame_width = mosaic_x;

  % left frame
  begingroup
    save x;

    x := frame_width;

    % trim
    for y=0 step subway_width until wall_height:
      draw_tile(x - trim_width, y, trim_width, subway_width, black);
    endfor

    x := x - trim_width;

    % half subway
    for y=0 step subway_width until wall_height:
      draw_tile(x - subway_narrow_height, y, subway_narrow_height, subway_width, white);
    endfor

    x := x - subway_narrow_height;

    % full subway
    for y=0 step subway_height until wall_height:
      draw_tile(x - subway_width, y, subway_width, subway_height, white);
    endfor
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
