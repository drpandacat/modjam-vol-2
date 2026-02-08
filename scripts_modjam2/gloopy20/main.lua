local Gloopy20Mod = RegisterMod("gloopy20", 1)

local CHARACTER_GLOOPY20 = Isaac.GetPlayerTypeByName("Gloopy20")
local CHARACTER_GLOOPY666 = Isaac.GetPlayerTypeByName("Gloopy20", true)

local BIRTHRIGHT_ISAACS_TEARS_COOLDOWN = 5 -- 5 frames, aka 1/6th of a second

local DMG_MULTIPLIER = 0.5
local TEARS_CAP = 900

local GLOOPY666_CHARGE_MAX = 90
local GLOOPY666_CHARGE_DRAIN_PER_FRAME = 1
local GLOOPY666_TEAR_REGEN_PER_FRAME = 2
local GLOOPY666_MAX_SPEED_DIVISOR = 4

local GLOOPY_RNG = RNG(Random())

local function clamp(x, a, b)
	if x < a then
		return a
	end

	if x > b then
		return b
	end

	return x
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

---@param owner Entity
local function triggerWeaponFired(_, _, _, owner)
	if not (owner and owner:ToPlayer()) then
		return
	end
	local pl = owner:ToPlayer() ---@type EntityPlayer?
	if
		not (
			pl
			and pl:GetPlayerType() == CHARACTER_GLOOPY20
			and pl:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
		)
	then
		return
	end

	local data = pl:GetData()
	data.LAST_ISAACS_TEARS_USE = (data.LAST_ISAACS_TEARS_USE or -10)
	if data.LAST_ISAACS_TEARS_USE + BIRTHRIGHT_ISAACS_TEARS_COOLDOWN > pl.FrameCount then
		return
	end

	pl:UseActiveItem(CollectibleType.COLLECTIBLE_ISAACS_TEARS, UseFlag.USE_NOANIM)
	data.LAST_ISAACS_TEARS_USE = pl.FrameCount
end
Gloopy20Mod:AddCallback(ModCallbacks.MC_POST_TRIGGER_WEAPON_FIRED, triggerWeaponFired)

---@param pl EntityPlayer
local function evalDamage(_, pl)
	if not (pl and pl:GetPlayerType() == CHARACTER_GLOOPY20) then
		return
	end

	pl.Damage = pl.Damage * DMG_MULTIPLIER
end
Gloopy20Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evalDamage, CacheFlag.CACHE_DAMAGE)

---@param pl EntityPlayer
local function evalTearsCap(_, pl, _, val)
	if not (pl and pl:GetPlayerType() == CHARACTER_GLOOPY20) then
		return
	end
	return TEARS_CAP
end
Gloopy20Mod:AddCallback(ModCallbacks.MC_EVALUATE_CUSTOM_CACHE, evalTearsCap, CustomCacheTag.TEARS_CAP)

local iconf = Isaac.GetItemConfig()
local itemsWithTearsUp = {}
for i = 1, iconf:GetCollectibles().Size - 1 do
	local conf = iconf:GetCollectible(i)
	if conf and conf.Tags & ItemConfig.TAG_TEARS_UP == ItemConfig.TAG_TEARS_UP then
		table.insert(itemsWithTearsUp, i)
	end
end

local function isTearsUp(id, reverse)
	local conf = iconf:GetCollectible(id)

	local istears = (conf and conf.Tags & ItemConfig.TAG_TEARS_UP == ItemConfig.TAG_TEARS_UP)

	if reverse then
		return not istears
	else
		return istears
	end
end

local CANCEL_CHECK_EFFECT = false

---@param sel CollectibleType
---@param seed integer
local function tryReplacePool(_, sel, pool, dec, seed)
	if CANCEL_CHECK_EFFECT then
		return
	end
	if not PlayerManager.AnyoneIsPlayerType(CHARACTER_GLOOPY20) then
		return
	end

	local totalTearsUps = 0
	for _, id in ipairs(itemsWithTearsUp) do
		totalTearsUps = totalTearsUps + PlayerManager.GetNumCollectibles(id)
	end
	local chance = 1 / (totalTearsUps + 1)
	local rng = RNG(seed)

	local isTears = (rng:RandomFloat() < chance)

	local itempool = Game():GetItemPool()
	pool = itempool:GetLastPool()

	local item = sel
	local failsafe = 2000
	while isTearsUp(item, isTears) and failsafe > 0 do
		CANCEL_CHECK_EFFECT = true
		item = itempool:GetCollectible(
			pool,
			false,
			rng:RandomInt(2 ^ 32 - 1),
			(isTears and CollectibleType.COLLECTIBLE_SAD_ONION or CollectibleType.COLLECTIBLE_BREAKFAST)
		)
		CANCEL_CHECK_EFFECT = false

		failsafe = failsafe - 1
	end
	if failsafe == 0 then
		item = (isTears and CollectibleType.COLLECTIBLE_SAD_ONION or CollectibleType.COLLECTIBLE_BREAKFAST)
	end

	if sel ~= item then
		if dec then
			itempool:RemoveCollectible(item)
		end

		return item
	end
end
Gloopy20Mod:AddCallback(ModCallbacks.MC_POST_GET_COLLECTIBLE, tryReplacePool)

---@param player EntityPlayer
Gloopy20Mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
	local weapon = player:GetWeapon(1)

	local data = player:GetData()
	data.gloopy666_charge = data.gloopy666_charge or GLOOPY666_CHARGE_MAX
	data.gloopy666_extra_tear_cd = data.gloopy666_extra_tear_cd or 0

	local moving = player:GetMovementInput():Length() >= 0.1
    local mult = 1

    if player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
        mult = 2
    end

	if moving then
		data.gloopy666_charge =
			clamp(data.gloopy666_charge - GLOOPY666_CHARGE_DRAIN_PER_FRAME / mult, 0, GLOOPY666_CHARGE_MAX)
	else
		data.gloopy666_charge =
			clamp(data.gloopy666_charge + GLOOPY666_TEAR_REGEN_PER_FRAME * mult, 0, GLOOPY666_CHARGE_MAX)
	end

	if not weapon or not moving or data.gloopy666_charge <= 0 then
		return
	end

    weapon:SetCharge(weapon:GetMaxCharge())
    player.FireDelay = player.MaxFireDelay

	data.gloopy666_extra_tear_cd = data.gloopy666_extra_tear_cd - 1

	if data.gloopy666_extra_tear_cd > 0 then
		return
	end

	local creep =
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_RED, 0, player.Position, Vector.Zero, player)
			:ToEffect()

	if creep then
		creep.SpriteScale = player.SizeMulti
		creep:SetTimeout(60)
		creep:Update()
	end

	local frac = clamp(data.gloopy666_charge / GLOOPY666_CHARGE_MAX, 0, 1)

	local min_interval = math.max(1, math.floor(player.MaxFireDelay / GLOOPY666_MAX_SPEED_DIVISOR))

	local interval = math.floor(lerp(player.MaxFireDelay, min_interval, frac) + 0.5)
	data.GLOOPY666_EXTRA_TEAR_CD = interval

	local velocity = RandomVector() * player.ShotSpeed * 12
	local tear = player:FireTear(player.Position, velocity, false, false, false, player, 1)
	tear:ChangeVariant(TearVariant.BLOOD)
	tear.FallingSpeed = GLOOPY_RNG:RandomInt(-10, 2)
	tear.FallingAcceleration = GLOOPY_RNG:RandomFloat() * 2
end, CHARACTER_GLOOPY666)

return Gloopy20Mod