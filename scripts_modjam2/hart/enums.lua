local mod = _HART_MOD
local game = Game()
local sfx = SFXManager()

mod.Character = {
	HART = Isaac.GetPlayerTypeByName("Hart"),
	HART_B = Isaac.GetPlayerTypeByName("Hart", true),
}

mod.Achievement = {
	HART_B = Isaac.GetAchievementIdByName("Tainted Hart"),
}

--[[
mod.Achievement = {
	PLACEHOLDER = Isaac.GetAchievementIdByName("Placeholder"),
}
--]]