local mod = ROBERT_MOD

local function PostModsLoaded()
    if TheFuture then
        TheFuture.ModdedCharacterDialogue["Robert"] = {
            "Wow man, you look really drained from this work",
            "If anything could help you...",
            "...You know you dont have to work in future, right?",
        }
    end

    if EID then
        EID:addCharacterInfo(ROBERT_MOD.PlayerType.ROBERT, "#{{ArrowUp}}Additional special rooms generate on each floor and are always visible#{{ArrowDown}}Robert can only walk through a limited amount of rooms each floor#{{Warning}}Automatically teleports to the boss after exceeding the room limit#{{ArrowUp}}Beating the boss without exceeding the room limit spawns an extra item", "Robert")
        EID:addBirthright(mod.PlayerType.ROBERT, "Spawns a {{ColorSilver}}Backrooms Access Keycard{{CR}} at the start of each floor and on first pickup#{{ColorSilver}}Keycard{{CR}} opens a single-use shortcut to an unvisited special room#{{Warning}}Stops working on later floors")
        EID:addCard(mod.Card.EXIT_KEYCARD, "Creates temporary door at the nearest valid slot#Door leads to an unvisited special room#{{Warning}} Door will prioritise rooms in the direction its facing")
        EID:addCondition("5.300." .. tostring(mod.Card.EXIT_KEYCARD), EID.IsGreedMode, "{{GreedMode}} Door leads to an {{ColorGray}}I AM ERROR{{CR}} room instead")

        local eidSprite = Sprite()
        eidSprite:Load("gfx/ui/robert_eid_icons.anm2", true)

        EID:addIcon("Player"..mod.PlayerType.ROBERT, "RobertIcon", 0, 16, 16, 0, 0, eidSprite)
        EID:addIcon("Card"..mod.Card.EXIT_KEYCARD, "KeycardIcon", 0, 9, 9, 1, 1, eidSprite)

        ---@diagnostic disable-next-line: undefined-doc-name
        local player = EntityConfig.GetPlayer(ROBERT_MOD.PlayerType.ROBERT_B) ---@cast player EntityConfigPlayer
        ---@diagnostic disable-next-line: undefined-field
        local old = player:GetModdedCoopMenuSprite()

        if old then
            local new = Sprite()
            ---@diagnostic disable-next-line: undefined-field
            local anim = player:GetName()
            new:Load(old:GetFilename())
            new:Play(anim, true)
            ---@diagnostic disable-next-line: undefined-field
            new:GetLayer(0):SetSize(Vector.One * 0.7)
            EID:addIcon("Player" .. ROBERT_MOD.PlayerType.ROBERT_B, anim, 0, 16, 16, 7.5, 5, new)
        end

        EID:addCharacterInfo(ROBERT_MOD.PlayerType.ROBERT_B, "#Retains Robert's timer and floor generation changes#Timer is now in seconds and ticks down passively in active rooms", "Robert")
        EID:addCollectible(ROBERT_MOD.CollectibleType.CLOCK_IN, "#Reset timer#For the rest of the floor, enemy damage sources will hurt for 1 more#Turns into Clock Out during inactive rooms#{{Collectible" .. ROBERT_MOD.CollectibleType.CLOCK_OUT .. "}}{{ColorObjName}} Clock Out#Teleport to the boss")
        EID:addCollectible(ROBERT_MOD.CollectibleType.CLOCK_OUT, "#Teleport to the boss#Turns into Clock In during active rooms#{{Collectible" .. ROBERT_MOD.CollectibleType.CLOCK_IN .. "}}{{ColorObjName}} Clock In#Reset timer#For the rest of the floor, enemy damage sources will hurt for 1 more")
        EID:addBirthright(mod.PlayerType.ROBERT_B, "Tears, damage, and speed increase as the timer approaches 0")
    end

    if BirthcakeRebaked then
        BirthcakeRebaked.API:AddBirthcakePickupText(mod.PlayerType.ROBERT, "One day off", "Robert's")
        BirthcakeRebaked.API:AddAccurateBlurbcake(mod.PlayerType.ROBERT, "Longer deadline")
        BirthcakeRebaked.API:AddBirthcakeSprite(mod.PlayerType.ROBERT, {SpritePath = "/gfx/items/trinkets/robert_birthcake.png"})
        BirthcakeRebaked.API:AddEIDDescription(mod.PlayerType.ROBERT, "Increases amount of rooms that can be traversed each floor")

        mod:AddCallback(BirthcakeRebaked.ModCallbacks.POST_BIRTHCAKE_COLLECT,
        ---@param player EntityPlayer
        ---@param firstTime boolean
        ---@param isGolden boolean
        function (_, player, firstTime, isGolden)
            if not firstTime then
                return
            end
            local effects = PlayerManager.FirstPlayerByType(mod.PlayerType.ROBERT):GetEffects()
            if effects:GetNullEffectNum(mod.NullItemID.DEADLINE_TRACKER) == 0 then
                return
            end

            if isGolden then
                effects:AddNullEffect(mod.NullItemID.DEADLINE_TRACKER, false, 6)
            else
                effects:AddNullEffect(mod.NullItemID.DEADLINE_TRACKER, false, 3)
            end

        end, mod.PlayerType.ROBERT)
    end

    if UniqueItemsAPI then
        UniqueItemsAPI.RegisterMod("Robert Jamguy")
        UniqueItemsAPI.RegisterCharacter("Robert", false)
        UniqueItemsAPI.AssignUniqueObject({
			PlayerType = mod.PlayerType.ROBERT,
			ObjectID = CollectibleType.COLLECTIBLE_BIRTHRIGHT,
			SpritePath = { "gfx/items/collectibles/robert_birthright.png" }
        ---@diagnostic disable-next-line: param-type-mismatch
		}, UniqueItemsAPI.ObjectType.COLLECTIBLE)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_MODS_LOADED, PostModsLoaded)