-- make_tiles.lua
-- Generates ORION's tile-kit templates: empty, named slots with guides for every
-- floor tile, wall/raised block and prop that the v1 rooms use.
--
--   aseprite -b --script-param root=C:/Users/adith/Documents/Study/Coding/Orion/art --script C:/Users/adith/Documents/Study/Coding/Orion/art/_scripts/make_tiles.lua
--
-- Output in art/templates/tiles/: floor_tiles, blocks, props (.aseprite, plus a _preview.png
-- of each). Re-running overwrites them: copy a sheet into a new folder before drawing in it.

local root = app.params["root"]
assert(root and #root > 0, "pass --script-param root=<art folder>")
local fs = app.fs
local function path(...) return fs.joinPath(root, ...) end
fs.makeAllDirectories(path("templates", "tiles"))
local pal = Palette{ fromFile = path("palette", "orion.gpl") }

local function px(h)
  h = h:gsub("#", "")
  return app.pixelColor.rgba(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16), 255)
end
local GUIDE, FOOT, PIVOT = px("#2e3a5c"), px("#8c9a5b"), px("#ffc857")

local function put(img, x, y, c)
  if x >= 0 and y >= 0 and x < img.width and y < img.height then img:drawPixel(x, y, c) end
end

-- the classic 32x16 pixel-isometric tile outline, top-left corner at (ox, oy)
local function tileOutline(img, ox, oy, c)
  for i = 0, 15 do
    put(img, ox + i, oy + 7 - i // 2, c)
    put(img, ox + 16 + i, oy + i // 2, c)
    put(img, ox + 31 - i, oy + 8 + i // 2, c)
    put(img, ox + i, oy + 8 + i // 2, c)
  end
end

-- a block of height h standing on a 32x16 footprint whose top-left corner is (ox, oy)
local function blockOutline(img, ox, oy, h, c)
  tileOutline(img, ox, oy, c)
  tileOutline(img, ox, oy - h, c)
  for y = oy + 7 - h, oy + 8 do put(img, ox, y, c); put(img, ox + 31, y, c) end
  for y = oy + 15 - h, oy + 15 do put(img, ox + 16, y, c) end
end

local function sheet(name, cols, rows, cw, ch, slots, drawGuide)
  local spr = Sprite(cols * cw, rows * ch, ColorMode.RGB)
  spr:setPalette(pal)
  local guide = spr.layers[1]
  guide.name = "_guide"
  local img = Image(cols * cw, rows * ch, ColorMode.RGB)
  for i, slot in ipairs(slots) do
    local cx, cy = (i - 1) % cols, (i - 1) // cols
    local ox, oy = cx * cw, cy * ch
    drawGuide(img, ox, oy, slot)
    local s = spr:newSlice(Rectangle(ox, oy, cw, ch))
    s.name = slot.name
    s.color = Color{ r = 127, g = 166, b = 216 }
  end
  spr:newCel(guide, 1, img, Point(0, 0))
  guide.opacity = 160
  guide.isEditable = false
  local art = spr:newLayer(); art.name = "art"
  spr:saveAs(path("templates", "tiles", name .. ".aseprite"))
  spr:saveCopyAs(path("templates", "tiles", name .. "_preview.png"))
  spr:close()
  print(name .. ": " .. #slots .. " slots of " .. cw .. "x" .. ch)
end

-- 1. Floor tiles: 32x16, drawn flat ---------------------------------------------------------
local floor = {}
for _, n in ipairs{
  "marble_1", "marble_2", "marble_3", "marble_moon_stripe",
  "mosaic_1", "mosaic_2", "meander_edge_ns", "meander_edge_we",
  "cracked_1", "cracked_2", "cracked_3", "pit",
  "earth_1", "earth_2", "rubble_scatter", "chalk_mark_seven_dots",
  "water_shallow_f1", "water_shallow_f2", "water_shallow_f3", "fountain_basin",
  "water_deep_f1", "water_deep_f2", "water_deep_f3", "stepping_stone",
} do table.insert(floor, { name = n }) end
sheet("floor_tiles", 4, 6, 32, 16, floor, function(img, ox, oy) tileOutline(img, ox, oy, GUIDE) end)

-- 2. Blocks: 32x48 slots, footprint at the bottom; h = height in px ----------------------------
local blocks = {
  { name = "wall_back_west_face", h = 32 }, { name = "wall_back_north_face", h = 32 },
  { name = "wall_back_corner", h = 32 }, { name = "wall_doorway", h = 32 },
  { name = "wall_lamp_niche", h = 32 }, { name = "wall_ivy", h = 32 },
  { name = "cyclopean_wall_1", h = 32 }, { name = "cyclopean_wall_2", h = 32 },
  { name = "wall_low_cutaway_1", h = 12 }, { name = "wall_low_cutaway_2", h = 12 },
  { name = "wall_low_corner", h = 12 }, { name = "lion_gate_half", h = 32 },
  { name = "raised_floor", h = 16 }, { name = "raised_floor_edge_crack", h = 16 },
  { name = "steps_rise_east", h = 8 }, { name = "steps_rise_south", h = 8 },
}
sheet("blocks", 4, 4, 32, 48, blocks, function(img, ox, oy, slot) blockOutline(img, ox, oy + 32, slot.h, GUIDE) end)

-- 3. Props: 48x64 slots, a one-tile footprint centred at the bottom with the pivot marked -------
local props = {}
for _, n in ipairs{
  "column_doric", "column_ionic", "column_drum_fallen", "statue_on_plinth",
  "storage_jar", "amphora", "cedar_chest", "rubble_heap",
  "olive_tree", "cypress", "well", "brazier",
  "weapon_rack", "fountain_centre", "altar_belt_star", "phineus_stall",
} do table.insert(props, { name = n }) end
sheet("props", 4, 4, 48, 64, props, function(img, ox, oy)
  tileOutline(img, ox + 8, oy + 46, FOOT)
  put(img, ox + 24, oy + 54, PIVOT); put(img, ox + 23, oy + 54, PIVOT); put(img, ox + 25, oy + 54, PIVOT)
  put(img, ox + 24, oy + 53, PIVOT)
end)
