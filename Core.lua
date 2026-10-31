local addonName, ns = ...
local L = ns.L
ns.Style = LibStub("DonCore-1.0"):Get("Style", 4):ForAddon() -- own kit from DonCore (Libs\DonCore\Style.lua): Theme.lua changes its colours, PAL and DEFAULT_ALPHA without touching the other addons' kit

---------------------------------------------------------------------------
-- Guildon Crafts: the guild's crafts (DONCORE_PLAN.md "Craftdon aus Guildon lösen", 31.10.2026): professions, recipe book, wish list
-- with orders, trade and mail help, shared prices. Taken out of Guildon 0.8; Guildon keeps the guild map and the members.
-- Own frames only: no hooksecurefunc, no HookScript, no Blizzard frame scripts.
-- Classic.lua (only in Guildon_Crafts_Vanilla.toc, loaded before this file) sets ns.ERA.
-- Error guard, events, saved table and helpers are in Shared/Base.lua (GuildShared/), loaded right after this file.
---------------------------------------------------------------------------
ns.defaults = {
  panel = {},          -- window position and collapsed state (Style.Panel get/set)
  tab = "overview",    -- last open tab
  sets = {},           -- shared data sets, key "<kind>:<owner>" (Comm.lua)
  peers = {},          -- Guildon Crafts users seen: full name -> { v = version, t = time() }
  panelLocked = false,
  panelScale = 1,
  panelAlpha = 0.93,
  combatFade = false,
}
ns.SCHEMA = 1
ns.WORDMARK = "|cff3fa9f5Guil|rdon Crafts"
-- own prefix per game version, so Forever and Era data never mix
ns.PREFIX = ns.ERA and "GuildonCraftsEra" or "GuildonCrafts"

ns.DBNAME = "GuildonCraftsDB"
ns.ERROR_HINT = "an error occurred, /gnc diag for details"
ns.ADDON_TITLE = "Guildon Crafts"
-- (31.10.2026) one of the Guildon parts: its entry at the shared minimap button (Shared/Launcher.lua), with the open wishes
ns.MODULE = { id = "crafts", title = "Guildon: Crafts & Recipes", icon = "Interface\\Icons\\Trade_BlackSmithing", order = 2 }
function ns.LauncherTip()
  local n = ns.OpenWishesForMe and ns.OpenWishesForMe() or 0
  return n > 0 and { L["Open wishes you can craft: %d"]:format(n) } or nil
end

-- Guildon Crafts's line in /gnc diag after the exchange numbers (GuildShared/Comm.lua ns.PrintDiag)
function ns.DiagExtra()
  if ns.RecipeReport then print(("  recipes the data lacks or knows without reagents: %d (/gnc recipes)"):format(select(2, ns.RecipeReport()))) end
end

function GuildonCrafts_OnAddonCompartmentClick()
  if ns.ToggleWindow then ns.ToggleWindow() end
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
SLASH_GUILDONCRAFTS1 = "/gnc"
SLASH_GUILDONCRAFTS2 = "/guildoncrafts"
ns.COMMANDS = {
  { "/gnc", "show or hide the window" },
  { "/gnc wishes", "the wish list" },
  { "/gnc sync", "ask the guild for new data now" },
  { "/gnc diag", "state of the exchange and errors" },
  { "/gnc demo", "example guild to try the windows (again: off)" },
  { "/gnc export", "your professions as text for the guild website" },
  { "/gnc recipes", "recipes the game showed that Guildon Crafts does not know yet, to send to the authors" },
  { "/gnc help", "this list" },
}

function ns.PrintHelp()
  ns.Print(L["Commands:"])
  for _, c in ipairs(ns.COMMANDS) do print("  |cffebebeb" .. c[1] .. "|r  |cff9ea3ad" .. L[c[2]] .. "|r") end
end

function ns.Slash(msg)
  msg = tostring(msg or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
  if msg == "" or msg == "show" or msg == "toggle" then
    if ns.ToggleWindow then ns.ToggleWindow() end
  elseif msg == "wishes" or msg == "wish" or msg == "wünsche" then
    if ns.OpenTab then ns.OpenTab("wishes") end
  elseif msg == "sync" then
    if ns.Hello then ns.Hello(true) end
    ns.Print(L["Asked the guild for new data."])
  elseif msg == "demo" or msg == "demo on" or msg == "demo off" or msg == "beispiel" then
    if ns.SetDemo then ns.SetDemo(msg == "demo off" and false or (msg == "demo on" and true or not ns.demo)) end
  elseif msg == "export" then
    if ns.ShowExport then ns.ShowExport() end
  elseif msg == "recipes" or msg == "rezepte" then
    if ns.ShowRecipeReport then ns.ShowRecipeReport() end
  elseif msg == "diag" then
    if ns.PrintDiag then ns.PrintDiag() end
  elseif msg == "help" or msg == "?" or msg == "hilfe" then
    ns.PrintHelp()
  else
    ns.Print(L["Unknown command: %s"]:format(msg))
    ns.PrintHelp()
  end
end

SlashCmdList["GUILDONCRAFTS"] = function(msg) ns.SafeCall("slash", ns.Slash, msg) end
