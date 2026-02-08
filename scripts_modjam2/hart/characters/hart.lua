local mod = _HART_MOD
local game = Game()
local sfx = SFXManager()

local DAMAGE_MULTIPLIER = 1.3
local CONFUSION_DURATION = 75 -- 2.5 seconds
local ROTTEN_HEART_CHANCE = 0.3 -- 30%

local function getPoisonChance(luck)
	return 0.15 + 0.03 * luck
end

local function getConfusionChance(luck)
	return 0.125 + 0.025 * luck
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continue)
	if PlayerManager.AnyoneIsPlayerType(mod.Character.HART) then
		local itemPool = game:GetItemPool()
		
		if itemPool:HasCollectible(CollectibleType.COLLECTIBLE_EVIL_CHARM) then
			itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_EVIL_CHARM) -- Removing Evil Charm because it removes the challenge (ignore Spindown Dice)
		end
	end
end)

mod:AddCallback(ModCallbacks.MC_EVALUATE_TEAR_HIT_PARAMS, function(_, player, params, weaponType, damageMult, displacement, source) -- Works with Ludo :3
	local playerRNG = RNG(math.max(Random(), 1)) -- Random() can return 0 which crashes lol
	
	if playerRNG:RandomFloat() <= getPoisonChance(player.Luck) then
		params.TearColor = Color.ProjectileCorpseGreen
		params.TearFlags = params.TearFlags | TearFlags.TEAR_POISON
	end
	if playerRNG:RandomFloat() <= getConfusionChance(player.Luck) then -- Doing so before the blood change will make this also a blood tear
		params.TearVariant = TearVariant.GLAUCOMA
		params.TearFlags = params.TearFlags | TearFlags.TEAR_CONFUSION
	end
	local variant = mod.GetBloodTearVariant(params.TearVariant)
	
	if variant then params.TearVariant = variant end
end, mod.Character.HART)

mod:AddPriorityCallback(ModCallbacks.MC_EVALUATE_STAT, CallbackPriority.LATE, function(_, player, stat, num) -- Works with Ipecac :3
	if player:GetPlayerType() == mod.Character.HART then return num * DAMAGE_MULTIPLIER end
end, EvaluateStatStage.FLAT_DAMAGE)

mod:AddCallback(ModCallbacks.MC_POST_ENTITY_TAKE_DMG, function(_, entity, amount, flag, source, countdown)
	local player = entity and entity:ToPlayer()
	
	if player and player:GetPlayerType() == mod.Character.HART then
		if flag & (DamageFlag.DAMAGE_RED_HEARTS | DamageFlag.DAMAGE_NO_PENALTIES) == 0 then -- Should be the same as Tainted Eden
			player:AddConfusion(EntityRef(nil), -CONFUSION_DURATION) -- Acts as a setter with negative values
		end
	end
end, EntityType.ENTITY_PLAYER)

mod:AddCallback(ModCallbacks.MC_POST_STATUS_EFFECT_APPLY, function(_, status, entity, source, duration)
	local player = entity and entity:ToPlayer()
	
	if player and player:GetPlayerType() == mod.Character.HART then
		if not player:HasCollectible(CollectibleType.COLLECTIBLE_EVIL_CHARM) then -- Wish this callback didn't trigger with Evil Charm equipped
			if not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
				player:SetShootingCooldown(math.abs(duration) * 2) -- Works at 60 fps instead of 30 fps (need math.abs due to negative confusion)
				
				for weaponSlot = 0, 4 do -- Resets all weapon charges to prevent some unintended behaviour
					local weapon = player:GetWeapon(weaponSlot)
					
					if weapon then
						weapon:SetFireDelay(0)
						weapon:SetCharge(0)
					end
				end
			end
		end
	end
end, StatusEffect.CONFUSION)

mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function(_, entity, input, action) -- Reverses controls for moving and shooting
	local player = entity and entity:ToPlayer()
	
	if player and player:GetPlayerType() == mod.Character.HART and player:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then -- Fingers crossed that other mods don't modify confusion too
		for button = ButtonAction.ACTION_LEFT, ButtonAction.ACTION_SHOOTDOWN do
			if action == button then return -Input.GetActionValue(button, player.ControllerIndex) end -- Doesn't invert mouse controls
		end
	end
end, InputHook.GET_ACTION_VALUE)

mod:AddCallback(ModCallbacks.MC_POST_PICKUP_SELECTION, function(_, pickup, variant, subtype, initVariant, initSubtype, rng)
	if PlayerManager.AnyoneIsPlayerType(mod.Character.HART) then
		if variant == PickupVariant.PICKUP_HEART and subtype == HeartSubType.HEART_FULL and initSubtype == 0 then -- A random heart that turns out to be a full red heart can become a rotten heart
			if rng:RandomFloat() <= ROTTEN_HEART_CHANCE then return {variant, HeartSubType.HEART_ROTTEN} end
		end
	end
end)

--------------------------
-- << UNLOCK MANAGER >> --
--------------------------
--[[
local completionUnlocks = {
	[CompletionType.MOMS_HEART] = mod.Achievement.PLACEHOLDER, -- By default mostly coop babies (thanks Apollyon and The Forgotten)
	[CompletionType.BOSS_RUSH] = mod.Achievement.PLACEHOLDER,
	[CompletionType.HUSH] = mod.Achievement.PLACEHOLDER,
	[CompletionType.ISAAC] = mod.Achievement.PLACEHOLDER,
	[CompletionType.SATAN] = mod.Achievement.PLACEHOLDER,
	[CompletionType.BLUE_BABY] = mod.Achievement.PLACEHOLDER,
	[CompletionType.LAMB] = mod.Achievement.PLACEHOLDER,
	[CompletionType.MEGA_SATAN] = mod.Achievement.PLACEHOLDER, -- By default all coop babies
	[CompletionType.ULTRA_GREED] = mod.Achievement.PLACEHOLDER,
	[CompletionType.ULTRA_GREEDIER] = mod.Achievement.PLACEHOLDER,
	[CompletionType.DELIRIUM] = mod.Achievement.PLACEHOLDER,
	[CompletionType.MOTHER] = mod.Achievement.PLACEHOLDER,
	[CompletionType.BEAST] = mod.Achievement.PLACEHOLDER,
}

mod:AddCallback(ModCallbacks.MC_POST_COMPLETION_MARK_GET, function(_, completion, playerType)
	local achievement = completionUnlocks[completion]
	
	if achievement then Isaac.GetPersistentGameData():TryUnlock(achievement) end
end, mod.Character.HART)
--]]

--[[ ADDITIONAL INFO
	- Wasn't able to make him receive Rotten Hearts from hp ups (pills, items, trinkets, eternal hearts, etc...)
--]]