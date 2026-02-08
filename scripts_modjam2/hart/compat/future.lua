local mod = _HART_MOD
local game = Game()
local sfx = SFXManager()

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continue) -- Needs to be in this callback to account for mod load order
	if TheFuture then
		TheFuture.ModdedCharacterDialogue[EntityConfig.GetPlayer(mod.Character.HART):GetName()] = {
			"oh deer",
			"...",
			"i walked right into that one",
			"so will you",
			"get in",
		}
	end
end)