_HART_MOD = RegisterMod("Hart", 1)

local mod = _HART_MOD
local version = "0.5.0"
local scriptsToLoad = {
	"enums",
	"utils",
	
	"characters.hart",
	"characters.hart2",
	"characters.hart2_closetunlcok",
	
	"compat.eid",
	"compat.future",
	"compat.birthcake",
}

for _, path in pairs(scriptsToLoad) do
	include("scripts_modjam2.hart." .. path)
end

-----------------
-- << DEBUG >> --
-----------------
local debugMessage = mod.Name .. " V" .. version .. " loaded successfully\n"

Isaac.ConsoleOutput(debugMessage)
Isaac.DebugString(debugMessage)

return mod