local _, ns = ...
local L = ns.L
local Style = ns.Style
local C = Style.COLORS

---------------------------------------------------------------------------
-- Guildon's tabs and pages (31.10.2026, out of Window.lua; the frame itself is Shared/Window.lua from GuildShared):
-- Overview as tiles, Members, Options. The other tabs are built in their own files (ns.PAGE_BUILDERS).
---------------------------------------------------------------------------
local PAGE_W, CONTENT_H, ROW_H = ns.PAGE_W, ns.CONTENT_H, ns.ROW_H
local Text, Color, FlatButton, AgeText = ns.UI.Text, ns.UI.Color, ns.UI.FlatButton, ns.UI.AgeText

ns.TABS = {
  { key = "overview", title = "Overview", icon = "Interface\\Icons\\INV_Misc_Book_09" },
  { key = "professions", title = "Professions", icon = "Interface\\Icons\\Trade_BlackSmithing" },
  { key = "recipes", title = "Recipes", icon = "Interface\\Icons\\INV_Scroll_03" },
  { key = "wishes", title = "Wish list", icon = "Interface\\Icons\\INV_Letter_15" },
  -- (Discord 30.10.: "warum muss das in einem Gildenaddon sein?") off by default, switched on in the options
  { key = "profit", title = "Profitable", icon = "Interface\\Icons\\INV_Misc_Coin_02", optional = "showProfit" },
  { key = "options", title = "Options", icon = "Interface\\Icons\\Trade_Engineering" },
}

ns.PANEL_NAME = "GuildonCraftsPanel"
ns.SHOW_AGAIN = "/gnc shows it again."
function ns.TitleText()
  local g = ns.GuildInfo()
  local t = Style.Wordmark("Guil", "don") .. " Crafts"
  if g then t = t .. "  |c" .. Style.Hex("gold") .. g .. "|r" end
  return t
end

local PAL = Style.PAL
local UI = ns.UI
local TILE_GAP, TILE_H = 12, 70
local TILE_W = math.floor((PAGE_W - TILE_GAP) / 2)
local TILE_TOP = 62

local function Tile(p, col, row, label)
  local t = UI.Box(p, PAL.edge, PAL.well)
  t:SetSize(TILE_W, TILE_H)
  t:SetPoint("TOPLEFT", p, "TOPLEFT", col * (TILE_W + TILE_GAP), -(TILE_TOP + row * (TILE_H + 8)))
  t.col, t.row = col, row
  t.label = Text(t, "GameFontHighlightSmall", 10, -8, TILE_W - 20, "textSecondary")
  t.label:SetText(label)
  t.value = Text(t, "GameFontNormalLarge", 10, -24, TILE_W - 20, "textPrimary")
  t.sub = Text(t, "GameFontHighlightSmall", 10, -48, TILE_W - 20, "textHint")
  return t
end

local function BuildOverview(p)
  p.guild = Text(p, "GameFontNormalLarge", 0, 0, PAGE_W, "gold")
  p.emblem = p:CreateTexture(nil, "ARTWORK")
  p.emblem:SetSize(56, 56)
  p.emblem:SetPoint("TOPRIGHT", p, "TOPRIGHT", -8, 0)
  p.emblem:Hide()
  p.rank = Text(p, "GameFontHighlight", 0, -28, PAGE_W, "textSecondary")
  -- guild tiles
  p.tiles = {
    members = Tile(p, 0, 0, L["Members"]),
    guildon = Tile(p, 0, 1, L["With Guildon Crafts"]),
    sets = Tile(p, 1, 0, L["Data sets"]),
    last = Tile(p, 1, 1, L["Last data from the guild"]),
    game = Tile(p, 1, 2, L["Game version"]),
  }
  -- the wishes the player can craft: a tile that opens the wish list
  p.open = UI.FlatButton(p, TILE_W, TILE_H, "")
  p.open:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -(TILE_TOP + 2 * (TILE_H + 8)))
  p.open.label:ClearAllPoints()
  p.open.label:SetPoint("LEFT", p.open, "LEFT", 10, 0)
  p.open.label:SetJustifyH("LEFT")
  p.open.label:SetFontObject(GameFontNormal)
  p.open.keepColor = true
  p.open.caret = p.open:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  p.open.caret:SetPoint("RIGHT", p.open, "RIGHT", -10, 0)
  p.open.caret:SetText(">")
  p.open:SetScript("OnClick", ns.Guard("overview wishes", function() ns.OpenTab("wishes") end))
  p.open:SetTip(L["Wish list"], nil, L["Click: open the wish list"])
  -- without a guild: the player's own characters as lines
  p.lines = {}
  for i = 1, 6 do p.lines[i] = Text(p, "GameFontHighlight", 0, -60 - (i - 1) * 22, PAGE_W) end
  -- bottom: a note, and the buttons right
  p.hint = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  p.hint:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 0, 34)
  p.hint:SetWidth(PAGE_W)
  p.hint:SetJustifyH("LEFT")
  Color(p.hint, "textHint")
  p.hint:SetText(L["Every member who has Guildon Crafts shows up here."])
  -- the example guild from a button (layout review 25.10.: without a guild the page was empty)
  p.demo = FlatButton(p, 190, 24, "")
  p.demo:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 0, 4)
  p.demo:SetScript("OnClick", ns.Guard("overview demo", function()
    if ns.SetDemo then ns.SetDemo(not ns.demo) end
    if p:IsShown() then p:Refresh() end
  end))
  p.export = FlatButton(p, 190, 24, L["Export for the guild website"])
  p.export:SetScript("OnClick", ns.Guard("overview export", function() if ns.ShowExport then ns.ShowExport() end end))
  p.export:SetTip(L["Export for the guild website"], { L["Your characters' professions and recipes as one text to copy."] }, L["Also: /gnc export"])
  -- wider window: the two tile columns share the width
  p.OnWidth = function(self, w)
    local tw = math.floor((w - TILE_GAP) / 2)
    for _, t in pairs(self.tiles) do
      t:SetSize(tw, TILE_H)
      t:ClearAllPoints()
      t:SetPoint("TOPLEFT", self, "TOPLEFT", t.col * (tw + TILE_GAP), -(TILE_TOP + t.row * (TILE_H + 8)))
      t.label:SetWidth(tw - 20)
      t.value:SetWidth(tw - 20)
      t.sub:SetWidth(tw - 20)
    end
    self.open:SetWidth(tw)
    self.guild:SetWidth(w)
    self.rank:SetWidth(w)
    self.hint:SetWidth(w)
    for _, l in ipairs(self.lines) do l:SetWidth(w) end
  end
  p.Refresh = function(self)
    local g, rank = ns.GuildInfo()
    self.demo.label:SetText(ns.demo and L["Hide the example guild"] or L["Show an example guild"])
    self.demo:SetShown(ns.demo or not ns.InGuild())
    self.export:ClearAllPoints()
    if self.demo:IsShown() then self.export:SetPoint("RIGHT", self.demo, "LEFT", -8, 0)
    else self.export:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 4) end
    for _, t in pairs(self.tiles) do t:SetShown(g ~= nil) end
    self.open:SetShown(g ~= nil)
    for _, l in ipairs(self.lines) do l:SetShown(g == nil) end
    if not g then
      self.emblem:Hide()
      self.guild:SetText(L["You are not in a guild."])
      self.rank:SetText(L["Guildon Crafts shows your guild once you join one."])
      for _, l in ipairs(self.lines) do l:SetText("") end
      -- own characters of this account with their professions
      self.lines[1]:SetText("|c" .. Style.Hex("gold") .. L["Your characters"] .. "|r")
      local n = 1
      local names = {}
      for owner in pairs(ns.db.prof or {}) do names[#names + 1] = owner end
      table.sort(names)
      for _, owner in ipairs(names) do
        if n >= #self.lines then break end
        local parts = {}
        for _, pr in ipairs(ns.PROFS) do
          local e = ns.db.prof[owner][pr.id]
          if e then parts[#parts + 1] = ("%s %d/%d"):format(ns.ProfName(pr.id), e.rank or 0, e.max or 0) end
        end
        if #parts > 0 then
          n = n + 1
          self.lines[n]:SetText(ns.ShortName(owner) .. ":  |c" .. Style.Hex("textSecondary") .. table.concat(parts, ", ") .. "|r")
        end
      end
      if n == 1 then self.lines[2]:SetText("|c" .. Style.Hex("textHint") .. L["Open your profession window once so that Guildon Crafts can read your recipes."] .. "|r") end
      self.hint:SetText(L["How it works: 1. Join a guild. 2. Members with Guildon Crafts show up by themselves. 3. Open your profession window once, then the guild sees your recipes."])
      return
    end
    self.guild:SetText(g)
    local own = ns.OwnEmblemFile and ns.OwnEmblemFile()
    if own then self.emblem:SetTexture(own) self.emblem:Show() else self.emblem:Hide() end
    self.rank:SetText(L["Your rank: %s"]:format(rank or "?"))
    local total, online, guildon, guildonOnline = ns.MemberCounts()
    local sets, newest, mine = 0, nil, nil
    for _, s in pairs(ns.db.sets) do
      sets = sets + 1
      if s.o ~= ns.MyName() then
        if not newest or s.t > newest then newest = s.t end
      elseif not mine or s.t > mine then
        mine = s.t
      end
    end
    local t = self.tiles
    t.members.value:SetText(Style.Number and Style.Number(total) or tostring(total))
    t.members.sub:SetText(L["online: %d"]:format(online))
    t.guildon.value:SetText(Style.Number and Style.Number(guildon) or tostring(guildon))
    t.guildon.sub:SetText(L["online: %d"]:format(guildonOnline))
    t.sets.value:SetText(Style.Number and Style.Number(sets) or tostring(sets))
    t.last.value:SetText(newest and AgeText(newest) or L["No data from the guild yet."])
    -- (Daniel 26.10.: "sollte nicht stehen, dass welche von mir da sind?") the player's own data, so that it does not look as if nothing happened
    t.last.sub:SetText(mine and L["Yours: %s"]:format(AgeText(mine)) or L["Yours: nothing yet"])
    t.game.value:SetText(ns.ERA and L["Classic Era"] or L["WoW Forever"])
    local open = ns.OpenWishesForMe and ns.OpenWishesForMe() or 0
    self.open.label:SetText(L["Open wishes you can craft: %d"]:format(open))
    Color(self.open.label, open > 0 and "gold" or "textSecondary")
    self.open.strong = open > 0
    self.open:SetLook("normal")
    if ns.demo then
      self.hint:SetText(L["Example guild is on: the members ending in -Demo are made up and only on your screen. /gnc demo off removes them."])
    else
      self.hint:SetText(L["Every member who has Guildon Crafts shows up here."])
    end
  end
end

---------------------------------------------------------------------------
-- Options (Daniel 26.10., Gemini draft): sections with a title, every switch with a line of explanation under it,
-- two columns so that it fits the window
---------------------------------------------------------------------------
local COL_W = math.floor((PAGE_W - 24) / 2)
local TOGGLE_H = 40

local function BuildOptions(p)
  local colY = { [0] = 0, [1] = 0 }
  -- the two columns share the page width (wider window): every part that depends on it is placed by a function that is run again
  local colW = COL_W
  local reflow = {}
  local function Place(fn) fn() reflow[#reflow + 1] = fn end
  local function X(col) return col * (colW + 24) end
  local function Section(col, title)
    if colY[col] ~= 0 then colY[col] = colY[col] - 10 end
    local y = colY[col]
    local fs, line = UI.SectionTitle(p, title, X(col), y, colW)
    Place(function()
      fs:ClearAllPoints()
      fs:SetPoint("TOPLEFT", p, "TOPLEFT", X(col), y)
      line:ClearAllPoints()
      line:SetPoint("TOPLEFT", p, "TOPLEFT", X(col), y - 16)
      line:SetPoint("TOPRIGHT", p, "TOPLEFT", X(col) + colW, y - 16)
    end)
    colY[col] = colY[col] - 24
  end
  local function Toggle(col, label, desc, get, set)
    local y = colY[col]
    local b = UI.CheckBox(p, label, get, set, { w = colW })
    local d = Text(p, "GameFontDisableSmall", X(col) + 20, y - 17, colW - 24, "textHint")
    d:SetText(desc)
    Place(function()
      b:SetWidth(colW)
      b:ClearAllPoints()
      b:SetPoint("TOPLEFT", p, "TOPLEFT", X(col), y)
      d:SetWidth(colW - 24)
      d:ClearAllPoints()
      d:SetPoint("TOPLEFT", p, "TOPLEFT", X(col) + 20, y - 17)
    end)
    -- a description that wraps (other languages, narrowest window) pushes the next row down
    local extra = math.max(0, math.ceil(tonumber(d:GetStringHeight()) or 0) - 12)
    colY[col] = colY[col] - TOGGLE_H - extra
    return b
  end
  Section(0, L["Window"])
  p.lock = Toggle(0, L["Lock window"], L["Stops the window from being moved."], function() return ns.db.panelLocked end,
    function(v) ns.db.panelLocked = v local panel = ns.GetPanel() if panel then panel:ApplySettings() end end)
  p.fade = Toggle(0, L["Dim in combat"], L["Makes the window see-through during combat."], function() return ns.db.combatFade end,
    function(v) ns.db.combatFade = v local panel = ns.GetPanel() if panel then panel:ApplySettings() end end)
  p.reset = FlatButton(p, 180, 22, L["Reset window position"])
  p.reset:SetPoint("TOPLEFT", p, "TOPLEFT", X(0), colY[0])
  p.reset:SetScript("OnClick", ns.Guard("options", function()
    ns.db.panel.pos = nil
    local panel = ns.GetPanel() if panel then panel:ResetPosition() end
  end))
  colY[0] = colY[0] - 30
  Section(0, L["Notifications"])
  p.notify = Toggle(0, L["Tell me about new wishes and my crafters"], L["A chat message when someone wishes for something you can make, or a crafter for your wish comes online."],
    function() return ns.db.notifyWishes ~= false end, function(v) ns.db.notifyWishes = v end)
  -- how long open wishes stay
  local daysLabel = Text(p, "GameFontHighlightSmall", X(0), colY[0] - 4, 170, "textPrimary")
  daysLabel:SetText(L["Open wishes run out after"])
  p.days = UI.Dropdown and UI.Dropdown(p, 110, {
    title = L["Open wishes run out after"],
    get = function() return ns.db.wishDays or 14 end,
    options = function() return { { 7, L["%d days"]:format(7) }, { 14, L["%d days"]:format(14) }, { 30, L["%d days"]:format(30) } } end,
    onPick = function(v) ns.db.wishDays = v if ns.InvalidateWishes then ns.InvalidateWishes() end end,
  })
  if p.days then p.days:SetPoint("TOPLEFT", p, "TOPLEFT", X(0) + 180, colY[0]) end
  local dd = Text(p, "GameFontDisableSmall", X(0), colY[0] - 26, colW, "textHint")
  dd:SetText(L["Old wishes disappear from the list after this time."])
  Place(function() dd:SetWidth(colW) end)
  colY[0] = colY[0] - 44
  Section(1, L["Tooltips and trade"])
  p.tips = Toggle(1, L["Guild lines in item tooltips (who crafts it, who wants a recipe)"], L["Adds the guild to the game's item tooltips."],
    function() return ns.db.tooltips ~= false end, function(v) ns.db.tooltips = v end)
  p.cod = Toggle(1, L["Cash on delivery when the wisher pays for the reagents"], L["The mail to the wisher asks for the price of the reagents on delivery."],
    function() return ns.db.mailCOD ~= false end, function(v) ns.db.mailCOD = v end)
  Section(1, L["Minimap"])
  p.mmb = Toggle(1, L["Minimap button"], L["Shows the Guildon button at the minimap. All Guildon parts share it."],
    function() return ns.db.minimapButton ~= false end,
    function(v) ns.db.minimapButton = v if ns.RefreshMinimapButton then ns.RefreshMinimapButton() end end)
  Section(1, L["Tabs"])
  p.profit = Toggle(1, L["Tab Profitable"], L["Recipes by profit per craft from auction prices. Off by default."],
    function() return ns.db.showProfit == true end, function(v) ns.db.showProfit = v and true or false ns.RefreshTabs() end)
  -- officer ranks (GUILDON_PLAN.md decision 3): the guild master chooses, everyone else sees the choice
  Section(1, L["Ranks that may delete other members' wishes"])
  local noteY = colY[1] + 2
  p.rankNote = Text(p, "GameFontDisableSmall", X(1), noteY, colW, "textHint")
  Place(function()
    p.rankNote:SetWidth(colW)
    p.rankNote:ClearAllPoints()
    p.rankNote:SetPoint("TOPLEFT", p, "TOPLEFT", X(1), noteY)
  end)
  local rankTop = colY[1] - 14
  p.ranks = {}
  local officerNow = {}
  for i = 0, 9 do
    local b = UI.CheckBox(p, "", function() return officerNow[i] end, function()
      if not ns.IsGuildMaster(ns.MyName()) then return end
      local cur = {}
      for r in pairs(ns.OfficerRanks()) do cur[r] = true end
      cur[i] = not cur[i] or nil
      if i == 0 then cur[0] = true end -- the guild master always may
      ns.SetOfficerRanks(cur)
      p:Refresh()
    end, { w = math.floor(COL_W / 2) - 4 })
    Place(function()
      b:SetWidth(math.floor(colW / 2) - 4)
      b:ClearAllPoints()
      b:SetPoint("TOPLEFT", p, "TOPLEFT", X(1) + (i % 2) * (math.floor(colW / 2)), rankTop - math.floor(i / 2) * 22)
    end)
    b:Hide()
    p.ranks[i] = b
  end
  p.OnWidth = function(_, w)
    colW = math.floor((w - 24) / 2)
    for _, fn in ipairs(reflow) do fn() end
  end
  p.Refresh = function(self)
    self.lock:Sync() self.fade:Sync() self.notify:Sync() self.tips:Sync() self.cod:Sync() self.mmb:Sync() self.profit:Sync()
    if self.days then self.days:Sync() end
    local names, n = ns.RankNames()
    local officer, set = ns.OfficerRanks()
    local gm = ns.IsGuildMaster(ns.MyName())
    for k in pairs(officerNow) do officerNow[k] = nil end
    for r in pairs(officer) do officerNow[r] = true end
    self.rankNote:SetText(n == 0 and "" or (gm and L["You are the guild master: click a rank to switch it."]
      or (set and L["Set by the guild master."] or L["The guild master has not chosen yet: ranks 1 and 2 of the list."])))
    for i = 0, 9 do
      local b = self.ranks[i]
      if i < n then
        b.label:SetText(names[i] or "?")
        b:Show()
        b:Sync()
      else
        b:Hide()
      end
    end
  end
end

ns.PAGE_BUILDERS.overview = BuildOverview
ns.PAGE_BUILDERS.options = BuildOptions

-- open the recipe book (optionally on one profession)
function ns.OpenRecipes(prof, spell)
  if ns.RecipeBookShow then ns.RecipeBookShow(prof, spell) end
  ns.OpenTab("recipes")
end
