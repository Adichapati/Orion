-- make_art.lua
-- Generates ORION's character templates, grey-box placeholder sprites,
-- the size lineup image and an isometric guide grid.
--
-- Run from a terminal (paths with forward slashes):
--   aseprite -b --script-param root=C:/Users/adith/Documents/Study/Coding/Orion/art --script C:/Users/adith/Documents/Study/Coding/Orion/art/_scripts/make_art.lua
--
-- Re-running overwrites everything in templates/ and placeholders/.
-- Templates are starting points: once someone draws in one, rename it or
-- stop re-running this script.

local root = app.params["root"]
assert(root and #root > 0, "pass --script-param root=<art folder>")

local fs = app.fs
local function path(...) return fs.joinPath(root, ...) end
for _, d in ipairs{ "templates", path("templates", "characters"), "placeholders" } do
  fs.makeAllDirectories(d:find(":") and d or path(d))
end

local pal = Palette{ fromFile = path("palette", "orion.gpl") }

-- Colours ---------------------------------------------------------------

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
  aegean0 = px("#2b5d8a"), aegean1 = px("#4f8fbf"),
  olive0 = px("#3a4a2a"), olive1 = px("#5d6b3a"), olive2 = px("#8c9a5b"),
  red0 = px("#8e1b2a"), red1 = px("#c23b3b"),
  bronze = px("#a8693a"), silver = px("#b7c1c9"), gold = px("#d9a43a"),
  skin0 = px("#5c3b2e"), skin1 = px("#9c6a4c"), skin2 = px("#d09a74"),
  leather = px("#4a3326"),
  -- markers: deliberately outside the palette so they can never ship by accident
  mk_pivot = px("#00ff00"), mk_light = px("#ffff00"), mk_hand = px("#ff00ff"),
}

-- Drawing helpers ---------------------------------------------------------

local A = app.pixelColor.rgbaA

local function put(img, x, y, c)
  x, y = math.floor(x + 0.5), math.floor(y + 0.5)
  if x >= 0 and y >= 0 and x < img.width and y < img.height then img:drawPixel(x, y, c) end
end

local function putEmpty(img, x, y, c)
  x, y = math.floor(x + 0.5), math.floor(y + 0.5)
  if x >= 0 and y >= 0 and x < img.width and y < img.height and A(img:getPixel(x, y)) == 0 then
    img:drawPixel(x, y, c)
  end
end

local function rect(img, x, y, w, h, c)
  for yy = y, y + h - 1 do for xx = x, x + w - 1 do put(img, xx, yy, c) end end
end

local function ellipse(img, cx, cy, rx, ry, c, onlyEmpty)
  for yy = math.floor(cy - ry), math.ceil(cy + ry) do
    for xx = math.floor(cx - rx), math.ceil(cx + rx) do
      local dx, dy = (xx - cx) / rx, (yy - cy) / ry
      if dx * dx + dy * dy <= 1.0 then
        if onlyEmpty then putEmpty(img, xx, yy, c) else put(img, xx, yy, c) end
      end
    end
  end
end

local function line(img, x0, y0, x1, y1, c)
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
  for y = math.floor(math.min(y0, y1, y2)), math.ceil(math.max(y0, y1, y2)) do
    for x = math.floor(math.min(x0, x1, x2)), math.ceil(math.max(x0, x1, x2)) do
      local qx, qy = x + 0.5, y + 0.5
      local w0, w1, w2 = edge(x1, y1, x2, y2, qx, qy), edge(x2, y2, x0, y0, qx, qy), edge(x0, y0, x1, y1, qx, qy)
      if (area >= 0 and w0 >= 0 and w1 >= 0 and w2 >= 0) or (area < 0 and w0 <= 0 and w1 <= 0 and w2 <= 0) then
        put(img, x, y, c)
      end
    end
  end
end

-- trapezoid: top edge from xTL..xTR at yT, bottom edge xBL..xBR at yB
local function quad(img, xTL, xTR, yT, xBL, xBR, yB, c)
  for y = yT, yB do
    local t = (yB == yT) and 0 or (y - yT) / (yB - yT)
    local xl = math.floor(xTL + (xBL - xTL) * t + 0.5)
    local xr = math.floor(xTR + (xBR - xTR) * t + 0.5)
    for x = xl, xr do put(img, x, y, c) end
  end
end

local function outline(img, c)
  local W, H = img.width, img.height
  local copy = img:clone()
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      if A(copy:getPixel(x, y)) == 0 then
        for _, d in ipairs{ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
          local xx, yy = x + d[1], y + d[2]
          if xx >= 0 and yy >= 0 and xx < W and yy < H and A(copy:getPixel(xx, yy)) > 0 then
            img:drawPixel(x, y, c)
            break
          end
        end
      end
    end
  end
end

-- 2:1 isometric diamond outline centred on (cx, cy), half-width hw (half-height = hw / 2)
local function isoDiamond(img, cx, cy, hw, c, fill)
  for i = 0, hw do
    local dy = math.floor(i / 2)
    local top, bottom = cy - dy, cy + dy
    if fill then
      for y = top, bottom do put(img, cx - hw + i, y, fill); put(img, cx + hw - i, y, fill) end
    end
    if c then
      put(img, cx - hw + i, top, c); put(img, cx + hw - i, top, c)
      put(img, cx - hw + i, bottom, c); put(img, cx + hw - i, bottom, c)
    end
  end
end

-- Characters ------------------------------------------------------------
-- body = size from the design doc; canvas leaves room for weapons and swings;
-- pivot = feet centre, 3 px above the canvas bottom for the contact shadow.

local chars = {
  { id = "cedalion", body = { 16, 24 }, canvas = { 32, 32 }, head = 9, facings = { "se", "ne" }, armour = true,
    light = { 24, 12 }, hand = { 9, 21 },
    anims = { { "idle", 4 }, { "walk", 6 }, { "run", 6 }, { "sneak", 6 }, { "jump", 5 }, { "ledge_hang", 2 }, { "climb_up", 6 },
              { "vine_climb", 4 }, { "attack_1", 4 }, { "attack_2", 4 }, { "attack_3", 4 }, { "parry", 3 }, { "dodge", 5 },
              { "torch_thrust", 4 }, { "shove", 4 }, { "interact", 3 }, { "hurt", 2 }, { "knocked_down", 6 } } },
  { id = "alcyone", body = { 18, 30 }, canvas = { 32, 40 }, head = 8, facings = { "se" },
    anims = { { "captive_idle", 4 }, { "freed", 4 } } },
  { id = "phineus", body = { 20, 24 }, canvas = { 32, 32 }, head = 8, facings = { "se" },
    anims = { { "idle", 4 }, { "talk", 4 }, { "hand_over", 4 }, { "prophecy", 4 } } },
  { id = "watchman", body = { 20, 32 }, canvas = { 40, 40 }, head = 8, facings = { "se", "ne" },
    light = { 28, 27 }, hand = { 11, 26 },
    anims = { { "idle", 4 }, { "yawn", 6 }, { "walk", 6 }, { "turn", 3 }, { "alert", 2 }, { "chop_windup", 3 },
              { "chop_strike", 2 }, { "chop_recover", 2 }, { "search", 4 }, { "hurt", 2 }, { "knocked_down", 6 } } },
  { id = "spearman", body = { 20, 34 }, canvas = { 56, 44 }, head = 8, facings = { "se", "ne" },
    light = { 36, 3 }, hand = { 25, 28 },
    anims = { { "idle", 4 }, { "walk", 6 }, { "turn", 3 }, { "alert", 2 }, { "thrust_windup", 4 }, { "thrust_lunge", 2 },
              { "thrust_recover", 3 }, { "sweep_windup", 3 }, { "sweep_swing", 3 }, { "sweep_recover", 2 }, { "hurt", 2 },
              { "knocked_down", 6 } } },
  { id = "hoplite", body = { 28, 36 }, canvas = { 48, 48 }, head = 9, facings = { "se", "ne" },
    light = { 39, 19 }, hand = { 13, 24 },
    anims = { { "idle", 4 }, { "walk", 6 }, { "turn", 3 }, { "alert", 2 }, { "bash_windup", 4 }, { "bash_strike", 2 },
              { "bash_recover", 3 }, { "chop_windup", 4 }, { "chop_strike", 2 }, { "chop_recover", 3 }, { "block", 2 },
              { "stunned", 4 }, { "hurt", 2 }, { "knocked_down", 6 } } },
  { id = "antares", body = { 40, 48 }, canvas = { 72, 64 }, head = 10, facings = { "se", "ne" },
    light = { 44, 47 }, hand = { 22, 35 },
    anims = { { "idle", 4 }, { "walk", 6 }, { "strike_windup", 4 }, { "strike_hit", 2 }, { "strike_recover", 4 },
              { "sweep_windup", 3 }, { "sweep_swing", 3 }, { "sweep_recover", 2 }, { "snuff_lamps", 6 }, { "hurt", 2 },
              { "defeat", 8 } } },
  { id = "shade", body = { 18, 30 }, canvas = { 32, 40 }, head = 7, facings = { "se", "ne" },
    hand = { 21, 27 },
    anims = { { "idle", 4 }, { "walk", 6 }, { "snuff", 4 }, { "strike", 6 }, { "revealed", 3 }, { "knocked_down", 6 } } },
}

local function durationFor(name)
  if name:find("idle") or name == "prophecy" then return 0.15 end
  if name == "run" then return 0.08 end
  if name:find("sneak") or name:find("talk") or name == "interact" then return 0.12 end
  if name:find("windup") then return 0.09 end
  if name:find("strike") or name:find("hit") or name:find("lunge") or name:find("swing") or name:find("attack") then return 0.06 end
  if name:find("knocked") or name == "defeat" then return 0.11 end
  return 0.1
end

-- Placeholder silhouettes (grey-box, NOT final art) -----------------------

local draw = {}

draw.cedalion = function(img, f)
  if f == "se" then
    quad(img, 9, 22, 15, 7, 24, 28, C.aegean0)                        -- cloak behind
    line(img, 7, 28, 9, 15, C.aegean1)
    rect(img, 13, 25, 2, 4, C.skin1); rect(img, 17, 25, 2, 4, C.skin1) -- legs
    rect(img, 13, 29, 2, 1, C.leather); rect(img, 17, 29, 2, 1, C.leather)
    rect(img, 11, 17, 10, 9, C.marble1)                                -- tunic
    rect(img, 12, 17, 2, 8, C.marble2)
    rect(img, 11, 21, 10, 1, C.leather)                                -- belt
    rect(img, 9, 18, 2, 4, C.skin1)                                    -- sword arm
    rect(img, 21, 18, 2, 5, C.skin1)                                   -- torch arm
    ellipse(img, 16, 11, 4.5, 4.5, C.skin2)                            -- head
    ellipse(img, 15.5, 8.5, 5, 3, C.night1)                            -- hair
    put(img, 13, 8, C.leather); put(img, 16, 7, C.leather)
    put(img, 17, 12, C.night0); put(img, 19, 12, C.night0)             -- eyes
    line(img, 23, 23, 24, 15, C.leather)                               -- torch
    ellipse(img, 24.5, 12.5, 1.6, 2.6, C.fire1)
    put(img, 24, 13, C.fire2); put(img, 24, 14, C.fire3); put(img, 25, 10, C.fire2)
  else
    quad(img, 9, 22, 14, 7, 24, 28, C.aegean0)                        -- cloak covers the back
    line(img, 12, 16, 11, 27, C.aegean1); line(img, 19, 16, 20, 27, C.aegean1)
    rect(img, 13, 28, 2, 1, C.skin1); rect(img, 17, 28, 2, 1, C.skin1)
    rect(img, 13, 29, 2, 1, C.leather); rect(img, 17, 29, 2, 1, C.leather)
    rect(img, 8, 18, 2, 5, C.skin1)                                    -- torch arm (now screen-left)
    ellipse(img, 16, 11, 4.5, 4.5, C.night1)                           -- back of the head
    put(img, 13, 9, C.leather); put(img, 18, 8, C.leather)
    line(img, 8, 23, 7, 15, C.leather)
    ellipse(img, 6.5, 12.5, 1.6, 2.6, C.fire1)
    put(img, 7, 13, C.fire2); put(img, 7, 14, C.fire3); put(img, 6, 10, C.fire2)
  end
end

draw.alcyone = function(img, f)
  quad(img, 12, 19, 19, 10, 21, 36, C.marble2)                         -- long chiton
  line(img, 13, 22, 12, 35, C.marble1); line(img, 17, 22, 18, 35, C.marble1)
  rect(img, 13, 37, 2, 1, C.leather); rect(img, 17, 37, 2, 1, C.leather)
  line(img, 12, 19, 20, 28, C.aegean0); line(img, 12, 20, 20, 29, C.aegean1) -- sash
  rect(img, 11, 19, 2, 6, C.skin1); rect(img, 19, 19, 2, 6, C.skin1)   -- arms
  rect(img, 14, 24, 4, 2, C.skin1); line(img, 13, 25, 18, 25, C.leather) -- bound hands
  ellipse(img, 16, 13, 4, 4.5, C.skin2)
  ellipse(img, 15.5, 10.5, 4.5, 3, C.night1)
  rect(img, 12, 9, 9, 1, C.leather)                                    -- braided crown
  put(img, 13, 9, C.silver); put(img, 16, 9, C.silver); put(img, 19, 9, C.silver)
  put(img, 17, 14, C.night0); put(img, 19, 14, C.night0)
end

draw.phineus = function(img, f)
  rect(img, 10, 24, 12, 2, C.leather)                                  -- stool
  line(img, 11, 26, 11, 29, C.leather); line(img, 20, 26, 20, 29, C.leather)
  quad(img, 10, 21, 14, 7, 24, 25, C.olive1)                           -- himation
  line(img, 7, 25, 10, 14, C.olive0); line(img, 21, 14, 24, 25, C.olive2)
  rect(img, 13, 27, 2, 2, C.skin1); rect(img, 18, 27, 2, 2, C.skin1)   -- feet
  rect(img, 13, 29, 2, 1, C.leather); rect(img, 18, 29, 2, 1, C.leather)
  rect(img, 15, 21, 5, 2, C.bronze); put(img, 19, 20, C.clay2)         -- the lamp he never lights
  ellipse(img, 16, 10, 4, 4.5, C.skin2)
  put(img, 15, 6, C.marble2); put(img, 16, 6, C.marble2)               -- bald shine
  tri(img, 12, 12, 21, 12, 16, 20, C.marble2)                          -- beard
  line(img, 12, 12, 16, 20, C.marble1)
  put(img, 17, 10, C.moon1); put(img, 19, 10, C.moon1)                 -- clouded eyes
  ellipse(img, 4.5, 25, 2.5, 3.5, C.clay1)                             -- oil jar
  rect(img, 4, 20, 2, 2, C.clay1); put(img, 3, 26, C.clay0)
end

draw.watchman = function(img, f)
  rect(img, 15, 31, 2, 6, C.skin1); rect(img, 22, 31, 2, 6, C.skin1)   -- legs
  rect(img, 15, 37, 2, 1, C.leather); rect(img, 22, 37, 2, 1, C.leather)
  rect(img, 13, 17, 14, 15, C.marble1)                                 -- undyed wool tunic
  if f == "se" then
    rect(img, 13, 17, 2, 15, C.marble0); rect(img, 13, 31, 14, 1, C.marble0)
    line(img, 13, 18, 26, 27, C.red0); line(img, 13, 19, 26, 28, C.red1) -- scorpion sash
    rect(img, 11, 18, 2, 8, C.skin1)                                   -- sword arm
    line(img, 11, 26, 11, 33, C.bronze); put(img, 11, 34, C.clay2); rect(img, 10, 26, 3, 1, C.leather)
    rect(img, 27, 18, 2, 7, C.skin1)                                   -- lantern arm
    rect(img, 27, 25, 4, 5, C.clay1); rect(img, 28, 26, 2, 3, C.fire2); rect(img, 28, 24, 2, 1, C.leather)
    ellipse(img, 20, 12, 4, 4.5, C.skin2)
    put(img, 21, 12, C.night0); put(img, 23, 12, C.night0)
    rect(img, 18, 15, 4, 1, C.skin0)
    tri(img, 15, 10, 25, 10, 20, 3, C.leather); line(img, 20, 4, 24, 10, C.marble0) -- felt cap
  else
    rect(img, 25, 17, 2, 15, C.marble0)
    line(img, 13, 27, 26, 18, C.red0); line(img, 13, 28, 26, 19, C.red1)
    rect(img, 11, 18, 2, 7, C.skin1)                                   -- lantern arm (screen-left)
    rect(img, 9, 25, 4, 5, C.clay1); rect(img, 10, 26, 2, 3, C.fire2); rect(img, 10, 24, 2, 1, C.leather)
    rect(img, 27, 18, 2, 8, C.skin1)
    line(img, 28, 26, 28, 33, C.bronze); put(img, 28, 34, C.clay2)
    ellipse(img, 20, 12, 4, 4.5, C.skin1)
    tri(img, 15, 10, 25, 10, 20, 3, C.leather)
  end
end

draw.spearman = function(img, f)
  if f == "se" then
    quad(img, 20, 35, 18, 18, 37, 36, C.red0)                         -- cloak
    line(img, 18, 36, 20, 18, C.red1)
    line(img, 35, 26, 36, 5, C.leather)                                -- torch pole on his back
    ellipse(img, 36.5, 3, 2, 2.5, C.fire1); put(img, 36, 3, C.fire2); put(img, 36, 4, C.fire3)
    rect(img, 23, 35, 2, 6, C.skin1); rect(img, 31, 35, 2, 6, C.skin1)
    rect(img, 23, 41, 2, 1, C.leather); rect(img, 31, 41, 2, 1, C.leather)
    rect(img, 22, 18, 12, 13, C.marble1)                               -- linen corslet
    rect(img, 22, 18, 2, 13, C.marble0); rect(img, 29, 19, 1, 10, C.marble2)
    for i = 0, 5 do rect(img, 22 + i * 2, 31, 2, 4, (i % 2 == 0) and C.marble1 or C.marble0) end
    rect(img, 24, 22, 2, 6, C.skin1); rect(img, 31, 21, 2, 5, C.skin1)
    line(img, 16, 31, 49, 22, C.leather)                               -- spear
    line(img, 49, 22, 53, 21, C.bronze); put(img, 54, 21, C.clay2)
    ellipse(img, 28, 13, 4, 4.5, C.skin2)
    ellipse(img, 28, 10.5, 4.5, 2.5, C.leather)                        -- leather helmet
    rect(img, 24, 12, 9, 1, C.bronze)
    put(img, 29, 14, C.night0); put(img, 31, 14, C.night0)
    rect(img, 24, 5, 10, 3, C.red1); rect(img, 24, 4, 10, 1, C.red0)   -- red crest
  else
    quad(img, 20, 35, 16, 18, 37, 38, C.red0)
    line(img, 25, 18, 24, 37, C.red1); line(img, 31, 18, 32, 37, C.red1)
    line(img, 28, 24, 28, 4, C.leather)
    ellipse(img, 28.5, 2.5, 2, 2.5, C.fire1); put(img, 28, 3, C.fire2)
    rect(img, 23, 39, 2, 2, C.skin1); rect(img, 31, 39, 2, 2, C.skin1)
    rect(img, 23, 41, 2, 1, C.leather); rect(img, 31, 41, 2, 1, C.leather)
    line(img, 22, 36, 49, 9, C.leather)
    line(img, 49, 9, 52, 6, C.bronze); put(img, 53, 5, C.clay2)
    ellipse(img, 28, 12, 4.5, 4.5, C.leather)
    rect(img, 24, 13, 9, 1, C.bronze)
    rect(img, 24, 5, 10, 3, C.red1); rect(img, 24, 4, 10, 1, C.red0)
  end
end

draw.hoplite = function(img, f)
  rect(img, 16, 38, 3, 7, C.bronze); rect(img, 27, 38, 3, 7, C.bronze) -- greaves
  rect(img, 16, 45, 3, 1, C.leather); rect(img, 27, 45, 3, 1, C.leather)
  for i = 0, 8 do rect(img, 15 + i * 2, 33, 2, 5, (i % 2 == 0) and C.red0 or C.leather) end
  rect(img, 15, 20, 18, 13, C.bronze)                                  -- muscle cuirass
  local shieldX, spearX = 31, 12
  if f == "se" then
    rect(img, 15, 20, 3, 13, C.clay0)
    rect(img, 22, 23, 1, 5, C.clay2); rect(img, 26, 23, 1, 5, C.clay2)
  else
    rect(img, 30, 20, 3, 13, C.clay0)
    shieldX, spearX = 15, 36
  end
  line(img, spearX, 41, spearX, 8, C.leather)                          -- spear
  rect(img, spearX - 1, 5, 3, 3, C.bronze); put(img, spearX, 4, C.clay2)
  rect(img, spearX + (f == "se" and 1 or -2), 21, 2, 8, C.skin1)
  ellipse(img, 24, 15, 5, 5.5, C.bronze)                               -- Corinthian helmet
  if f == "se" then
    rect(img, 20, 15, 9, 1, C.night0); rect(img, 24, 16, 1, 3, C.bronze); rect(img, 21, 12, 2, 1, C.clay2)
  end
  rect(img, 19, 8, 12, 3, C.night1); rect(img, 19, 8, 12, 1, C.night2) -- dark crest
  ellipse(img, shieldX, 29, 10, 10, C.clay2)                           -- aspis
  ellipse(img, shieldX, 29, 9, 9, C.bronze)
  if f == "se" then
    ellipse(img, shieldX, 29, 7.5, 7.5, C.night1)
    ellipse(img, shieldX, 31, 2.5, 1.5, C.red1)                        -- scorpion blazon
    line(img, shieldX + 2, 30, shieldX + 4, 26, C.red1); line(img, shieldX + 4, 26, shieldX + 2, 24, C.red1)
    line(img, shieldX - 2, 31, shieldX - 4, 29, C.red1); line(img, shieldX - 2, 32, shieldX - 4, 33, C.red1)
    rect(img, 38, 17, 3, 4, C.clay1); rect(img, 39, 18, 1, 2, C.fire2) -- lantern on the rim
  else
    ellipse(img, shieldX, 29, 7.5, 7.5, C.clay0)                       -- shield's inside
    rect(img, shieldX - 1, 22, 2, 14, C.leather)
    rect(img, 6, 17, 3, 4, C.clay1); rect(img, 7, 18, 1, 2, C.fire2)
  end
end

draw.antares = function(img, f)
  local glaiveX = (f == "se") and 18 or 54
  if f == "se" then
    quad(img, 22, 49, 24, 18, 53, 58, C.night1)                       -- cape
  else
    quad(img, 22, 49, 22, 16, 55, 60, C.night1)
  end
  rect(img, 28, 50, 4, 11, C.red0); rect(img, 40, 50, 4, 11, C.red0)   -- greaves
  rect(img, 28, 50, 1, 11, C.bronze); rect(img, 43, 50, 1, 11, C.bronze)
  rect(img, 28, 61, 4, 1, C.leather); rect(img, 40, 61, 4, 1, C.leather)
  if f == "se" then
    rect(img, 26, 44, 20, 6, C.red0)
    for x = 26, 45, 3 do line(img, x, 44, x, 49, C.red1) end
    rect(img, 26, 26, 20, 18, C.red1)                                  -- lacquered torso plates
    for y = 29, 41, 4 do rect(img, 26, y, 20, 1, C.red0) end
    rect(img, 26, 26, 20, 1, C.bronze); rect(img, 26, 43, 20, 1, C.bronze)
    rect(img, 43, 45, 3, 4, C.fire0); put(img, 44, 46, C.red1); put(img, 44, 47, C.fire1) -- red lantern
  end
  rect(img, 21, 30, 4, 10, C.red0); rect(img, 47, 30, 4, 10, C.red0)   -- arms
  ellipse(img, 24, 28, 4.5, 4, C.red0); ellipse(img, 47, 28, 4.5, 4, C.red0) -- pauldrons
  line(img, glaiveX, 60, glaiveX, 9, C.leather)                        -- glaive
  local d = (f == "se") and 1 or -1
  line(img, glaiveX, 8, glaiveX + 5 * d, 4, C.bronze); line(img, glaiveX + 5 * d, 4, glaiveX + 8 * d, 8, C.bronze)
  line(img, glaiveX + 8 * d, 8, glaiveX + 6 * d, 12, C.clay2); line(img, glaiveX, 9, glaiveX + 4 * d, 10, C.red1)
  ellipse(img, 36, 20, 6, 6.5, C.red0)                                 -- helmet
  if f == "se" then rect(img, 31, 20, 10, 1, C.night0); rect(img, 33, 16, 2, 2, C.red1) end
  for _, s in ipairs{ { 30, 13 }, { 33, 9 }, { 37, 7 }, { 41, 8 }, { 44, 11 } } do -- scorpion-tail crest
    ellipse(img, s[1], s[2], 2, 2, C.red1)
  end
  line(img, 45, 13, 44, 16, C.clay2); put(img, 44, 17, C.fire3)        -- stinger
end

draw.shade = function(img, f)
  quad(img, 13, 18, 16, 11, 21, 37, C.night1)                          -- robe to the ground
  ellipse(img, 16, 12, 4, 5, C.night1)                                 -- hood
  if f == "se" then
    ellipse(img, 16.5, 13, 2.5, 3, C.night0)                           -- face in shadow
    line(img, 21, 37, 18, 16, C.moon0); line(img, 19, 8, 20, 15, C.moon0) -- cold rim light
    rect(img, 20, 22, 2, 6, C.night2); line(img, 21, 28, 24, 31, C.night2)
  else
    line(img, 11, 37, 13, 16, C.moon0); line(img, 13, 8, 12, 15, C.moon0)
    rect(img, 10, 22, 2, 6, C.night2)
  end
end

local function placeholder(ch, facing)
  local img = Image(ch.canvas[1], ch.canvas[2], ColorMode.RGB)
  draw[ch.id](img, facing)
  outline(img, C.night0)
  local cx, cy = ch.canvas[1] // 2, ch.canvas[2] - 3
  ellipse(img, cx, cy + 1, ch.body[1] * 0.42, 1.5, C.night1, true)     -- contact shadow, behind everything
  return img
end

-- Template guide layer ------------------------------------------------------

local function guideImage(ch)
  local W, H = ch.canvas[1], ch.canvas[2]
  local img = Image(W, H, ColorMode.RGB)
  local cx, cy = W // 2, H - 3
  isoDiamond(img, cx, cy, 16, C.night2)                                -- one floor tile's footprint
  local bw, bh = ch.body[1], ch.body[2]
  local x0, y0 = cx - bw // 2, cy - bh + 1
  for x = x0, x0 + bw - 1 do put(img, x, y0, C.olive2); put(img, x, cy, C.olive2) end -- body box from the doc
  for y = y0, cy do put(img, x0, y, C.olive2); put(img, x0 + bw - 1, y, C.olive2) end
  for x = x0, x0 + bw - 1, 2 do put(img, x, y0 + ch.head, C.moon0) end -- chin line (head height)
  put(img, cx, cy, C.fire2); put(img, cx - 1, cy, C.fire2); put(img, cx + 1, cy, C.fire2)
  put(img, cx, cy - 1, C.fire2)
  return img
end

local function markerImage(ch, facing)
  local W, H = ch.canvas[1], ch.canvas[2]
  local img = Image(W, H, ColorMode.RGB)
  put(img, W // 2, H - 3, C.mk_pivot)
  local function mirror(p) if facing == "se" then return p[1] else return W - 1 - p[1] end end
  if ch.light then put(img, mirror(ch.light), ch.light[2], C.mk_light) end
  if ch.hand then put(img, mirror(ch.hand), ch.hand[2], C.mk_hand) end
  return img
end

local function makeTemplate(ch)
  local W, H = ch.canvas[1], ch.canvas[2]
  local spr = Sprite(W, H, ColorMode.RGB)
  spr:setPalette(pal)

  local guide = spr.layers[1]
  guide.name = "_guide"
  local function add(name)
    local l = spr:newLayer(); l.name = name; return l
  end
  local ref = add("_placeholder")
  add("shadow"); add("body"); add("clothes")
  if ch.armour then add("armour_swap_keys") end
  add("props")
  local weaponRef = add("_weapon_ref")
  local markers = add("_markers")

  local frames = {}
  for _, facing in ipairs(ch.facings) do
    for _, a in ipairs(ch.anims) do
      table.insert(frames, { name = a[1] .. "_" .. facing, count = a[2], facing = facing, anim = a[1] })
    end
  end
  local total = 0
  for _, fr in ipairs(frames) do total = total + fr.count end
  for _ = 2, total do spr:newEmptyFrame() end

  local gimg = guideImage(ch)
  local refs, marks = {}, {}
  for _, facing in ipairs(ch.facings) do
    refs[facing] = placeholder(ch, facing)
    marks[facing] = markerImage(ch, facing)
  end

  local f = 1
  for _, fr in ipairs(frames) do
    local tag = spr:newTag(f, f + fr.count - 1)
    tag.name = fr.name
    tag.color = (fr.facing == "se") and Color{ r = 79, g = 143, b = 191 } or Color{ r = 194, g = 59, b = 59 }
    for i = f, f + fr.count - 1 do
      spr.frames[i].duration = durationFor(fr.anim)
      spr:newCel(guide, i, gimg, Point(0, 0))
      spr:newCel(ref, i, refs[fr.facing], Point(0, 0))
      spr:newCel(markers, i, marks[fr.facing], Point(0, 0))
    end
    f = f + fr.count
  end

  guide.opacity = 140; guide.isEditable = false
  ref.opacity = 90; ref.isVisible = false; ref.isEditable = false
  weaponRef.isVisible = false
  markers.isVisible = false

  spr:saveAs(path("templates", "characters", ch.id .. ".aseprite"))
  spr:close()
  return total
end

-- Build everything ------------------------------------------------------------

local report = {}
for _, ch in ipairs(chars) do
  local n = makeTemplate(ch)
  -- placeholders: one .aseprite with a frame per facing, plus a PNG per facing
  local spr = Sprite(ch.canvas[1], ch.canvas[2], ColorMode.RGB)
  spr:setPalette(pal)
  spr.layers[1].name = ch.id
  for i, facing in ipairs(ch.facings) do
    if i > 1 then spr:newEmptyFrame() end
    local img = placeholder(ch, facing)
    spr:newCel(spr.layers[1], i, img, Point(0, 0))
    local tag = spr:newTag(i, i); tag.name = facing
    img:saveAs(path("placeholders", ch.id .. "_" .. facing .. ".png"))
  end
  spr:saveAs(path("placeholders", ch.id .. ".aseprite"))
  spr:close()
  table.insert(report, ch.id .. ": template " .. n .. " frames")
end

-- Size lineup: SE placeholders side by side on one baseline, scaled x5 --------

local gap, scale = 8, 5
local lw, maxPivot = gap, 0
for _, ch in ipairs(chars) do
  lw = lw + ch.canvas[1] + gap
  maxPivot = math.max(maxPivot, ch.canvas[2] - 3)
end
local lh = maxPivot + 14
local base = maxPivot + 6
local strip = Image(lw, lh, ColorMode.RGB)
rect(strip, 0, 0, lw, lh, C.night1)
local x = gap
for _, ch in ipairs(chars) do
  local cw, chh = ch.canvas[1], ch.canvas[2]
  isoDiamond(strip, x + cw // 2, base, 16, nil, C.night2)
  local img = placeholder(ch, "se")
  local oy = base - (chh - 3)
  for yy = 0, chh - 1 do
    for xx = 0, cw - 1 do
      local p = img:getPixel(xx, yy)
      if A(p) > 0 then put(strip, x + xx, oy + yy, p) end
    end
  end
  x = x + cw + gap
end
local big = Image(lw * scale, lh * scale, ColorMode.RGB)
for yy = 0, lh - 1 do
  for xx = 0, lw - 1 do
    local p = strip:getPixel(xx, yy)
    for sy = 0, scale - 1 do for sx = 0, scale - 1 do big:drawPixel(xx * scale + sx, yy * scale + sy, p) end end
  end
end
strip:saveAs(path("placeholders", "lineup.png"))
big:saveAs(path("placeholders", "lineup_x5.png"))

-- Isometric guide grid: 480x270 (the game's native resolution), 32x16 tiles ------

local G = Sprite(480, 270, ColorMode.RGB)
G:setPalette(pal)
local grid = G.layers[1]; grid.name = "_grid"
local gimg = Image(480, 270, ColorMode.RGB)
for yy = 0, 269 do
  for xx = 0, 479 do
    local hx = math.floor(xx / 2)
    if (hx + yy) % 16 == 0 or (hx - yy) % 16 == 0 then gimg:drawPixel(xx, yy, C.night2) end
  end
end
G:newCel(grid, 1, gimg, Point(0, 0))
grid.opacity = 120; grid.isEditable = false
for _, name in ipairs{ "floor", "walls", "props", "characters" } do local l = G:newLayer(); l.name = name end
G:saveAs(path("templates", "iso-grid-480x270.aseprite"))
G:close()

print(table.concat(report, "\n"))
print("lineup: " .. lw .. "x" .. lh .. " (x5 = " .. lw * scale .. "x" .. lh * scale .. ")")
