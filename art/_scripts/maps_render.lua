-- maps_render.lua
-- Draws each room in art/maps/rooms.json as an isometric grey-box mock-up.
-- Don't run this file directly: art/_scripts/build_maps.py prepends ROOT and DATA
-- (the rooms as a Lua table) and runs the result in Aseprite.
--
-- Output per room, in art/maps/:
--   <id>.aseprite   layers: floor, blocks (walls, props, raised floor, characters), _overlay (cones, patrols)
--   <id>.png        flattened, 1x
--   <id>_x2.png     flattened, 2x, for viewing

local fs = app.fs
local function path(...) return fs.joinPath(ROOT, ...) end
fs.makeAllDirectories(path("maps"))
local pal = Palette{ fromFile = path("palette", "orion.gpl") }

local function px(h)
  h = h:gsub("#", "")
  return app.pixelColor.rgba(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16), 255)
end
local C = {
  night0 = px("#0d0b1a"), night1 = px("#1b1834"), night2 = px("#2e3a5c"),
  moon0 = px("#7fa6d8"), moon1 = px("#cfe3ff"),
  fire0 = px("#7a2a1a"), fire1 = px("#e0782c"), fire2 = px("#ffc857"), fire3 = px("#fff1c1"),
  marble0 = px("#7d776d"), marble1 = px("#b9b2a3"), marble2 = px("#e8e2d4"),
  clay0 = px("#8a3b22"), clay1 = px("#c0603a"), clay2 = px("#d9935f"),
  aegean0 = px("#2b5d8a"), aegean1 = px("#4f8fbf"), pool = px("#5fb3b0"),
  olive0 = px("#3a4a2a"), olive1 = px("#5d6b3a"), olive2 = px("#8c9a5b"),
  red0 = px("#8e1b2a"), red1 = px("#c23b3b"),
  bronze = px("#a8693a"), silver = px("#b7c1c9"), gold = px("#d9a43a"),
  leather = px("#4a3326"),
}
local PC = app.pixelColor

-- Pixel helpers -----------------------------------------------------------------

local function put(img, x, y, c)
  x, y = math.floor(x + 0.5), math.floor(y + 0.5)
  if x >= 0 and y >= 0 and x < img.width and y < img.height then img:drawPixel(x, y, c) end
end

local function line(img, x0, y0, x1, y1, c)
  x0, y0, x1, y1 = math.floor(x0 + 0.5), math.floor(y0 + 0.5), math.floor(x1 + 0.5), math.floor(y1 + 0.5)
  local dx, dy = math.abs(x1 - x0), -math.abs(y1 - y0)
  local sx, sy = x0 < x1 and 1 or -1, y0 < y1 and 1 or -1
  local err = dx + dy
  while true do
    put(img, x0, y0, c)
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 >= dy then err = err + dy; x0 = x0 + sx end
    if e2 <= dx then err = err + dx; y0 = y0 + sy end
  end
end

local function tri(img, x0, y0, x1, y1, x2, y2, c)
  local function edge(ax, ay, bx, by, qx, qy) return (bx - ax) * (qy - ay) - (by - ay) * (qx - ax) end
  local area = edge(x0, y0, x1, y1, x2, y2)
  if area == 0 then return end
  for y = math.floor(math.min(y0, y1, y2)), math.ceil(math.max(y0, y1, y2)) do
    for x = math.floor(math.min(x0, x1, x2)), math.ceil(math.max(x0, x1, x2)) do
      local qx, qy = x + 0.5, y + 0.5
      local w0, w1, w2 = edge(x1, y1, x2, y2, qx, qy), edge(x2, y2, x0, y0, qx, qy), edge(x0, y0, x1, y1, qx, qy)
      if (area > 0 and w0 >= 0 and w1 >= 0 and w2 >= 0) or (area < 0 and w0 <= 0 and w1 <= 0 and w2 <= 0) then
        put(img, x, y, c)
      end
    end
  end
end

local function quad(img, a, b, c2, d, col)
  tri(img, a[1], a[2], b[1], b[2], c2[1], c2[2], col)
  tri(img, a[1], a[2], c2[1], c2[2], d[1], d[2], col)
end

local function ellipse(img, cx, cy, rx, ry, c)
  for yy = math.floor(cy - ry), math.ceil(cy + ry) do
    for xx = math.floor(cx - rx), math.ceil(cx + rx) do
      local dx, dy = (xx - cx) / rx, (yy - cy) / ry
      if dx * dx + dy * dy <= 1.0 then put(img, xx, yy, c) end
    end
  end
end

-- Isometric geometry ---------------------------------------------------------------
-- tile (x, y) has its centre at (OX + (x - y) * 16, OY + (x + y) * 8); z lifts things up the screen.

local OX, OY = 0, 0
local function centre(x, y) return OX + (x - y) * 16, OY + (x + y) * 8 end

local function diamond(img, x, y, z, inset, col, edgeCol)
  local cx, cy = centre(x, y)
  local hw = 16 - inset
  local hh = hw / 2
  local T, R, B, L = { cx, cy - hh - z }, { cx + hw, cy - z }, { cx, cy + hh - z }, { cx - hw, cy - z }
  quad(img, T, R, B, L, col)
  if edgeCol then
    line(img, T[1], T[2], R[1] - 1, R[2], edgeCol); line(img, T[1] - 1, T[2], L[1], L[2], edgeCol)
  end
end

-- a box standing on tile (x, y) from height z0 to z1, shrunk by inset px
local function block(img, x, y, z0, z1, inset, top, left, right, edgeCol)
  local cx, cy = centre(x, y)
  local hw = 16 - inset
  local hh = hw / 2
  local function P(dx, dy, z) return { cx + dx, cy + dy - z } end
  quad(img, P(-hw, 0, z1), P(0, hh, z1), P(0, hh, z0), P(-hw, 0, z0), left)
  quad(img, P(0, hh, z1), P(hw, 0, z1), P(hw, 0, z0), P(0, hh, z0), right)
  quad(img, P(0, -hh, z1), P(hw, 0, z1), P(0, hh, z1), P(-hw, 0, z1), top)
  if edgeCol then
    local a, b, c, d = P(0, -hh, z1), P(hw, 0, z1), P(0, hh, z1), P(-hw, 0, z1)
    line(img, a[1], a[2], b[1], b[2], edgeCol); line(img, b[1], b[2], c[1], c[2], edgeCol)
    line(img, c[1], c[2], d[1], d[2], edgeCol); line(img, d[1], d[2], a[1], a[2], edgeCol)
    local e = P(0, hh, z0)
    line(img, c[1], c[2], e[1], e[2], edgeCol)
  end
end

-- Room helpers ------------------------------------------------------------------------

local SOLID = { ["#"] = true, L = true, v = true }
local BLOCKS_SIGHT = { ["#"] = true, L = true, v = true, o = true, S = true, J = true, T = true, r = true }
local RAISED = { h = true, P = true, A = true }

local function cellAt(room, x, y)
  local row = room.grid[y + 1]
  if not row or x < 0 or x >= #row then return " " end
  return row:sub(x + 1, x + 1)
end

local function elevation(ch) return RAISED[ch] and 16 or 0 end

-- a wall is cut away to a low wall when walkable space lies behind it (up to 2 tiles north or west),
-- because at full height it would hide that space from the camera
local function isFrontWall(room, x, y)
  local function open(ch) return ch ~= " " and not SOLID[ch] end
  for dy = 0, 2 do
    for dx = 0, 2 do
      if (dx > 0 or dy > 0) and open(cellAt(room, x - dx, y - dy)) then return true end
    end
  end
  return false
end

local function loadSprite(name)
  local ok, img = pcall(function() return Image{ fromFile = path("placeholders", name .. ".png") } end)
  if ok then return img end
  return nil
end

local function flipped(img)
  local out = Image(img.width, img.height, ColorMode.RGB)
  for y = 0, img.height - 1 do
    for x = 0, img.width - 1 do out:drawPixel(img.width - 1 - x, y, img:getPixel(x, y)) end
  end
  return out
end

local function stamp(img, spr, x, y, z)
  local cx, cy = centre(x, y)
  local ox, oy = math.floor(cx - spr.width / 2 + 0.5), math.floor(cy - (spr.height - 3) - z + 0.5)
  for yy = 0, spr.height - 1 do
    for xx = 0, spr.width - 1 do
      local p = spr:getPixel(xx, yy)
      if PC.rgbaA(p) > 0 then put(img, ox + xx, oy + yy, p) end
    end
  end
end

-- pick a sprite and mirror from a facing vector given in plan coordinates
local function facingSprite(name, f)
  local sdx, sdy = (f[1] - f[2]) * 16, (f[1] + f[2]) * 8
  local front = sdy >= 0
  local base = loadSprite(name .. (front and "_se" or "_ne")) or loadSprite(name .. "_se")
  if not base then return nil end
  if sdx < 0 then return flipped(base) end
  return base
end

-- tiles a guard can see: inside range and half-angle, with a clear line
local function visibleTiles(room, g, gt)
  local out = {}
  local fx, fy = g.face[1], g.face[2]
  local fl = math.sqrt(fx * fx + fy * fy)
  local gx, gy = g.at[1], g.at[2]
  local function clear(tx, ty)
    local steps = math.max(math.abs(tx - gx), math.abs(ty - gy)) * 3
    for i = 1, steps - 1 do
      local t = i / steps
      local sx, sy = math.floor(gx + (tx - gx) * t + 0.5), math.floor(gy + (ty - gy) * t + 0.5)
      if not (sx == gx and sy == gy) and not (sx == tx and sy == ty) and BLOCKS_SIGHT[cellAt(room, sx, sy)] then return false end
    end
    return true
  end
  for ty = gy - gt.range, gy + gt.range do
    for tx = gx - gt.range, gx + gt.range do
      local dx, dy = tx - gx, ty - gy
      local d = math.sqrt(dx * dx + dy * dy)
      local ch = cellAt(room, tx, ty)
      if d > 0 and d <= gt.range + 0.25 and ch ~= " " and not SOLID[ch] then
        local cosA = (dx * fx + dy * fy) / (d * fl)
        if cosA >= math.cos(math.rad(gt.half)) and clear(tx, ty) then table.insert(out, { tx, ty }) end
      end
    end
  end
  return out
end

local function walkTiles(a, b)
  local out = {}
  local x0, y0, x1, y1 = a[1], a[2], b[1], b[2]
  local dx, dy = math.abs(x1 - x0), -math.abs(y1 - y0)
  local sx, sy = x0 < x1 and 1 or -1, y0 < y1 and 1 or -1
  local err = dx + dy
  while true do
    table.insert(out, { x0, y0 })
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 >= dy then err = err + dy; x0 = x0 + sx end
    if e2 <= dx then err = err + dx; y0 = y0 + sy end
  end
  return out
end

-- Drawing one tile's contents ---------------------------------------------------------

local function drawFloor(img, room, x, y)
  local ch = cellAt(room, x, y)
  if ch == " " or SOLID[ch] then return end
  local z = 0
  if ch == "_" then
    diamond(img, x, y, 0, 0, C.night0)
  elseif ch == "W" or ch == "p" then
    diamond(img, x, y, -2, 0, C.aegean0, C.night2)
  elseif ch == "~" then
    diamond(img, x, y, -1, 0, C.aegean1, C.aegean0)
  elseif ch == "E" or ch == "D" then
    diamond(img, x, y, 0, 0, C.clay2, C.clay0)
  elseif ch == "m" then
    diamond(img, x, y, 0, 0, C.marble2, C.moon0)
  elseif ch == "F" then
    diamond(img, x, y, 0, 0, C.marble1, C.marble0)
  else
    diamond(img, x, y, z, 0, C.marble1, C.marble0)
  end
  if ch == "x" then
    local cx, cy = centre(x, y)
    line(img, cx - 9, cy - 1, cx - 3, cy + 2, C.night1); line(img, cx - 3, cy + 2, cx + 4, cy - 2, C.night1)
    line(img, cx + 4, cy - 2, cx + 9, cy + 1, C.night1); line(img, cx - 2, cy - 4, cx - 3, cy + 2, C.night1)
  elseif ch == "*" then
    local cx, cy = centre(x, y)
    for i = 0, 6 do put(img, cx - 6 + i * 2, cy, C.silver) end
  end
end

local function drawBlock(img, room, x, y)
  local ch = cellAt(room, x, y)
  local edge = C.night1
  if SOLID[ch] then
    local h = isFrontWall(room, x, y) and 12 or 40
    block(img, x, y, 0, h, 0, C.marble1, C.marble0, C.night2, edge)
    if ch == "L" or ch == "v" then
      local cx, cy = centre(x, y)
      local onLeftFace = (y == 0) or cellAt(room, x, y + 1) ~= "#"
      local fx = onLeftFace and (cx - 8) or (cx + 8)
      if ch == "L" then
        ellipse(img, fx, cy - 22, 1.5, 2.5, C.fire1); put(img, fx, cy - 22, C.fire3)
      else
        for i = 0, 5 do put(img, fx - 3 + (i % 3) * 3, cy - 30 + i * 4, C.olive2); put(img, fx - 2 + (i % 2) * 3, cy - 28 + i * 4, C.olive1) end
      end
    end
    return
  end
  if ch == "h" or ch == "P" or ch == "A" then
    block(img, x, y, 0, 16, 0, C.marble2, C.marble1, C.marble0, edge)
  elseif ch == "^" then
    block(img, x, y, 0, 8, 0, C.marble2, C.marble1, C.marble0, edge)
    local cx, cy = centre(x, y)
    line(img, cx - 10, cy - 8, cx + 2, cy - 2, C.marble0)
  elseif ch == "o" then
    block(img, x, y, 0, 54, 10, C.marble2, C.marble1, C.marble0, edge)
    block(img, x, y, 52, 58, 7, C.marble2, C.marble1, C.marble0, edge)
  elseif ch == "S" then
    block(img, x, y, 0, 8, 5, C.marble1, C.marble0, C.night2, edge)
    block(img, x, y, 8, 34, 10, C.marble2, C.marble1, C.marble0, edge)
    local cx, cy = centre(x, y)
    ellipse(img, cx, cy - 38, 3.5, 3.5, C.marble2)
  elseif ch == "J" then
    block(img, x, y, 0, 18, 8, C.clay2, C.clay1, C.clay0, edge)
  elseif ch == "a" then
    block(img, x, y, 0, 10, 11, C.clay2, C.clay1, C.clay0, edge)
  elseif ch == "C" then
    block(img, x, y, 0, 8, 8, C.bronze, C.leather, C.night1, edge)
  elseif ch == "r" then
    block(img, x, y, 0, 10, 8, C.marble1, C.marble0, C.night2, edge)
    block(img, x + 0.3, y - 0.2, 0, 6, 11, C.marble1, C.marble0, C.night2, edge)
  elseif ch == "T" then
    block(img, x, y, 0, 14, 13, C.leather, C.leather, C.night1)
    local cx, cy = centre(x, y)
    ellipse(img, cx, cy - 24, 13, 9, C.olive0); ellipse(img, cx - 1, cy - 26, 11, 7, C.olive1)
    ellipse(img, cx - 4, cy - 29, 5, 3, C.olive2)
  elseif ch == "w" then
    block(img, x, y, 0, 8, 3, C.marble1, C.marble0, C.night2, edge)
    diamond(img, x, y, 8, 7, C.night0)
  elseif ch == "B" then
    block(img, x, y, 0, 10, 11, C.bronze, C.clay0, C.leather, edge)
    local cx, cy = centre(x, y)
    ellipse(img, cx, cy - 14, 3, 4, C.fire1); put(img, cx, cy - 13, C.fire2); put(img, cx, cy - 12, C.fire3)
  elseif ch == "K" then
    block(img, x, y, 0, 14, 10, C.leather, C.leather, C.night1, edge)
    local cx, cy = centre(x, y)
    line(img, cx - 2, cy - 22, cx - 2, cy - 6, C.bronze); line(img, cx + 2, cy - 20, cx + 2, cy - 6, C.silver)
  elseif ch == "F" then
    block(img, x, y, 0, 6, 0, C.marble1, C.marble0, C.night2)
    diamond(img, x, y, 6, 3, C.pool)
    local function f(dx, dy) return cellAt(room, x + dx, y + dy) == "F" end
    if f(-1, 0) and f(1, 0) and f(0, -1) and f(0, 1) then
      block(img, x, y, 6, 22, 10, C.marble2, C.marble1, C.marble0, edge)
      local cx, cy = centre(x, y)
      for i = 0, 4 do put(img, cx - 4 + i * 2, cy - 26 - (i % 2) * 2, C.moon1) end
    end
  elseif ch == "p" then
    block(img, x, y, -2, 4, 4, C.marble1, C.marble0, C.night2, edge)
  end
  if ch == "A" then
    block(img, x, y, 16, 28, 8, C.marble2, C.marble1, C.marble0, edge)
    local cx, cy = centre(x, y)
    ellipse(img, cx, cy - 33, 3, 3, C.gold); put(img, cx, cy - 33, C.fire3)
  end
end

-- tint a tile's top face in place (used for cones on raised floor, which the overlay layer can't reach)
local function tintDiamond(img, x, y, z, inset, col, alpha)
  local mask = Image(img.width, img.height, ColorMode.RGB)
  diamond(mask, x, y, z, inset, col)
  local cx, cy = centre(x, y)
  for yy = math.max(0, math.floor(cy - z - 9)), math.min(img.height - 1, math.ceil(cy - z + 9)) do
    for xx = math.max(0, math.floor(cx - 17)), math.min(img.width - 1, math.ceil(cx + 17)) do
      local m = mask:getPixel(xx, yy)
      if PC.rgbaA(m) > 0 then
        local d = img:getPixel(xx, yy)
        if PC.rgbaA(d) > 0 then
          local function mix(a, b) return math.floor(a * (1 - alpha) + b * alpha + 0.5) end
          img:drawPixel(xx, yy, PC.rgba(mix(PC.rgbaR(d), PC.rgbaR(m)), mix(PC.rgbaG(d), PC.rgbaG(m)), mix(PC.rgbaB(d), PC.rgbaB(m)), 255))
        end
      end
    end
  end
end

-- Building a room --------------------------------------------------------------------------

local function blend(dst, src, alpha)
  for y = 0, src.height - 1 do
    for x = 0, src.width - 1 do
      local s = src:getPixel(x, y)
      if PC.rgbaA(s) > 0 then
        local d = dst:getPixel(x, y)
        local function mix(a, b) return math.floor(a * (1 - alpha) + b * alpha + 0.5) end
        dst:drawPixel(x, y, PC.rgba(mix(PC.rgbaR(d), PC.rgbaR(s)), mix(PC.rgbaG(d), PC.rgbaG(s)), mix(PC.rgbaB(d), PC.rgbaB(s)), 255))
      end
    end
  end
end

local function over(dst, src)
  for y = 0, src.height - 1 do
    for x = 0, src.width - 1 do
      local s = src:getPixel(x, y)
      if PC.rgbaA(s) > 0 then dst:drawPixel(x, y, s) end
    end
  end
end

local function renderRoom(room)
  local W, H = #room.grid[1], #room.grid
  local minSX, maxSX, minSY, maxSY = math.huge, -math.huge, math.huge, -math.huge
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      if cellAt(room, x, y) ~= " " then
        local sx, sy = (x - y) * 16, (x + y) * 8
        minSX = math.min(minSX, sx - 16); maxSX = math.max(maxSX, sx + 16)
        minSY = math.min(minSY, sy - 8 - 64); maxSY = math.max(maxSY, sy + 10)
      end
    end
  end
  local CW = math.max(480, maxSX - minSX + 32)
  local CH = math.max(270, maxSY - minSY + 24)
  OX = math.floor((CW - (maxSX - minSX)) / 2 - minSX)
  OY = math.floor((CH - (maxSY - minSY)) / 2 - minSY)

  local floor = Image(CW, CH, ColorMode.RGB)
  local blocks = Image(CW, CH, ColorMode.RGB)
  local overlay = Image(CW, CH, ColorMode.RGB)

  for y = 0, H - 1 do for x = 0, W - 1 do drawFloor(floor, room, x, y) end end

  -- characters standing on tiles, keyed "x,y"
  local actors = {}
  for _, g in ipairs(room.guards) do
    actors[g.at[1] .. "," .. g.at[2]] = { name = g.type, face = g.face }
  end
  if room.player then
    local f = { 1, 0 }
    for _, pts in pairs(room.routes) do
      if pts[2] then f = { pts[2][1] - pts[1][1], pts[2][2] - pts[1][2] } end
      break
    end
    actors[room.player[1] .. "," .. room.player[2]] = { name = "cedalion", face = f }
  end
  for y = 0, H - 1 do for x = 0, W - 1 do
    if cellAt(room, x, y) == "P" then actors[x .. "," .. y] = { name = "phineus", face = { 1, 0 } } end
  end end

  -- painter's order: back to front
  local order = {}
  for y = 0, H - 1 do for x = 0, W - 1 do table.insert(order, { x, y }) end end
  table.sort(order, function(a, b)
    if a[1] + a[2] ~= b[1] + b[2] then return a[1] + a[2] < b[1] + b[2] end
    return a[1] < b[1]
  end)
  local raisedCone = {}
  for _, g in ipairs(room.guards) do
    for _, v in ipairs(visibleTiles(room, g, DATA.guardTypes[g.type])) do
      local ch = cellAt(room, v[1], v[2])
      if RAISED[ch] or ch == "^" then raisedCone[v[1] .. "," .. v[2]] = true end
    end
  end
  for _, t in ipairs(order) do
    local x, y = t[1], t[2]
    drawBlock(blocks, room, x, y)
    if raisedCone[x .. "," .. y] then
      local ch = cellAt(room, x, y)
      tintDiamond(blocks, x, y, ch == "^" and 8 or 16, 1, C.fire2, 0.45)
    end
    local a = actors[x .. "," .. y]
    if a then
      local spr = facingSprite(a.name, a.face)
      if spr then stamp(blocks, spr, x, y, elevation(cellAt(room, x, y))) end
    end
  end

  -- overlay: lantern cones in yellow, patrol paths in red
  for _, g in ipairs(room.guards) do
    local gt = DATA.guardTypes[g.type]
    for _, v in ipairs(visibleTiles(room, g, gt)) do
      diamond(overlay, v[1], v[2], elevation(cellAt(room, v[1], v[2])), 1, C.fire2)
    end
  end
  for _, g in ipairs(room.guards) do
    local pts = g.path
    for i = 1, #pts - 1 do
      for _, v in ipairs(walkTiles(pts[i], pts[i + 1])) do
        diamond(overlay, v[1], v[2], elevation(cellAt(room, v[1], v[2])), 10, C.red1)
      end
    end
  end

  -- layered file for artists
  local spr = Sprite(CW, CH, ColorMode.RGB)
  spr:setPalette(pal)
  local lf = spr.layers[1]; lf.name = "floor"
  spr:newCel(lf, 1, floor, Point(0, 0))
  local lb = spr:newLayer(); lb.name = "blocks"
  spr:newCel(lb, 1, blocks, Point(0, 0))
  local lo = spr:newLayer(); lo.name = "_overlay"
  spr:newCel(lo, 1, overlay, Point(0, 0))
  lo.opacity = 110
  spr:saveAs(path("maps", room.id .. ".aseprite"))
  spr:close()

  -- flattened previews
  local flat = Image(CW, CH, ColorMode.RGB)
  for y = 0, CH - 1 do for x = 0, CW - 1 do flat:drawPixel(x, y, C.night1) end end
  over(flat, floor)
  blend(flat, overlay, 0.45)
  over(flat, blocks)
  flat:saveAs(path("maps", room.id .. ".png"))
  local big = Image(CW * 2, CH * 2, ColorMode.RGB)
  for y = 0, CH - 1 do for x = 0, CW - 1 do
    local p = flat:getPixel(x, y)
    big:drawPixel(2 * x, 2 * y, p); big:drawPixel(2 * x + 1, 2 * y, p)
    big:drawPixel(2 * x, 2 * y + 1, p); big:drawPixel(2 * x + 1, 2 * y + 1, p)
  end end
  big:saveAs(path("maps", room.id .. "_x2.png"))
  print(room.id .. ": " .. CW .. "x" .. CH)
end

for _, room in ipairs(DATA.rooms) do renderRoom(room) end
