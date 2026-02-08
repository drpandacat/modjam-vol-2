local mod = _HART_MOD
local game = Game()
local sfx = SFXManager()

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continue) -- Needs to be in this callback to account for mod load order
	if BirthcakeRebaked then
		BirthcakeRebaked.API:AddBirthcakePickupText(mod.Character.HART, "Carcass")
		BirthcakeRebaked.API:AddBirthcakeSprite(mod.Character.HART, {SpritePath = "gfx/compat/birthcake.png"})
		BirthcakeRebaked.API:AddEIDDescription(mod.Character.HART, "Farts when taking damage#{{Poison}} The fart leaves a poisonous cloud and deflects projectiles")
	end
end)

mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flag, source, countdown)
	if BirthcakeRebaked then
		local player = entity and entity:ToPlayer()
		
		if player and player:GetPlayerType() == mod.Character.HART then
			if player:HasTrinket(BirthcakeRebaked.Birthcake.ID) then
				player:AddCollectibleEffect(CollectibleType.COLLECTIBLE_BLACK_BEAN, false, 6) -- Hehe
			end
		end
	end
end, EntityType.ENTITY_PLAYER)