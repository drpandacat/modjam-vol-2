local mod = HAGAR_MOD

local function PostModsLoaded()
    if TheFuture then
        TheFuture.ModdedTaintedCharacterDialogue["Hagar"] = {
            "Man, I am so thirsty I could drink a...",
            "...",
            "Care to share a drink?",
        }
    end

    if BirthcakeRebaked then
        BirthcakeRebaked.API:AddBirthcakePickupText(mod.Enums.Character.T_HAGAR, "Deeper well", "Tainted Hagar's")
        BirthcakeRebaked.API:AddAccurateBlurbcake(mod.Enums.Character.T_HAGAR, "Extra Zamzam space")
        BirthcakeRebaked.API:AddBirthcakeSprite(mod.Enums.Character.T_HAGAR, {SpritePath = "/gfx/items/trinkets/thagar_birthcake.png"})
        BirthcakeRebaked.API:AddEIDDescription(mod.Enums.Character.T_HAGAR, "Adds an additional heart space in the Zamzam")
    end

    if UniqueItemsAPI then
        UniqueItemsAPI.RegisterMod("Hagar (B95 CharacterJam)")
        UniqueItemsAPI.RegisterCharacter("Hagar", true)
        UniqueItemsAPI.AssignUniqueObject({
			PlayerType = mod.Enums.Character.T_HAGAR,
			ObjectID = CollectibleType.COLLECTIBLE_BIRTHRIGHT,
			SpritePath = { "gfx/items/collectibles/thagar_birthright.png" }
        ---@diagnostic disable-next-line: param-type-mismatch
		}, UniqueItemsAPI.ObjectType.COLLECTIBLE)
    end

    if FiendFolio then
        ---@param player EntityPlayer
        mod:AddCallback(mod.Enums.Callbacks.CHECK_OWNED_HEALTH_TYPES, function (_, player)
            if FiendFolio.GetMorbidHeartsNum(player) > 0  then
                return mod.Enums.ModdedHeartTypes.FF_MORBID
            end
        end)

        ---@param player EntityPlayer
        mod:AddCallback(mod.Enums.Callbacks.CHECK_OWNED_HEALTH_TYPES, function (_, player)
            if FiendFolio.GetImmoralHeartsNum(player) > 0  then
                return mod.Enums.ModdedHeartTypes.FF_IMMORAL
            end
        end)

        mod:AddCallback(mod.Enums.Callbacks.REMOVE_EXCESS_HEART_TYPE, function (_, player)
            local heartCount = FiendFolio.GetMorbidHeartsNum(player)
            FiendFolio:AddMorbidHearts(player, -heartCount)
            return math.ceil(heartCount/3)
        end, mod.Enums.ModdedHeartTypes.FF_MORBID)

        mod:AddCallback(mod.Enums.Callbacks.REMOVE_EXCESS_HEART_TYPE, function (_, player)
            local heartCount = FiendFolio.GetImmoralHeartsNum(player)
            FiendFolio:AddImmoralHearts(player, -heartCount)
            return math.ceil(heartCount/2)
        end, mod.Enums.ModdedHeartTypes.FF_IMMORAL)

        local MorbidVariants = {
            [Isaac.GetEntityVariantByName("Morbid Heart")] = true,
            [Isaac.GetEntityVariantByName("Two-Thirds Morbid Heart")] = true,
            [Isaac.GetEntityVariantByName("Third Morbid Heart")] = true,
        }
        local ImmoralVariants = {
            [Isaac.GetEntityVariantByName("Immoral Heart")] = true,
            [Isaac.GetEntityVariantByName("Half Immoral Heart")] = true,
            [Isaac.GetEntityVariantByName("Half Immoral Heart")] = true,
        }
        ---@param heart EntityPickup
        mod:AddCallback(mod.Enums.Callbacks.CHECK_HEART_HEALTH_TYPE, function (_, heart)
            local variant = heart.Variant
            if MorbidVariants[variant] then
                return mod.Enums.ModdedHeartTypes.FF_MORBID
            end
            if ImmoralVariants[variant] then
                return mod.Enums.ModdedHeartTypes.FF_IMMORAL
            end
        end)

        mod:AddCallback(mod.Enums.Callbacks.GET_HEART_KEY, function (_, heart)
            local variant = heart.Variant
            if MorbidVariants[variant] then
                return mod.Enums.StoredHeartKeys.FF_MORBID
            end
            if ImmoralVariants[variant] then
                return mod.Enums.StoredHeartKeys.FF_IMMORAL
            end
        end)

        mod:AddCallback(mod.Enums.Callbacks.HEART_TYPE_TO_HEART_KEY, function ()
            return mod.Enums.StoredHeartKeys.FF_IMMORAL
        end, mod.Enums.ModdedHeartTypes.FF_IMMORAL)

        mod:AddCallback(mod.Enums.Callbacks.HEART_TYPE_TO_HEART_KEY, function ()
            return mod.Enums.StoredHeartKeys.FF_MORBID
        end, mod.Enums.ModdedHeartTypes.FF_MORBID)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_MODS_LOADED, PostModsLoaded)