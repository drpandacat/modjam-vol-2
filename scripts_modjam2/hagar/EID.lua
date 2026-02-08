if not EID then return end
local mod = HAGAR_MOD

EID:setModIndicatorName("Hagar")

local EIDIcons = Sprite("gfx/ui/hagar_eid_icons.anm2", true)
EID:addIcon("IconHagar", "Hagar", 0, 18, 12, 0, -4, EIDIcons)
EID.InlineIcons["Player" .. mod.Enums.Character.HAGAR] = EID.InlineIcons["IconHagar"]

EID:addCharacterInfo(mod.Enums.Character.HAGAR, "Can't have Red Hearts #{{SoulHeart}} Health ups grant Soul Hearts #Monsters deal double damage #Monsters' max HP scale up each floor #{{Heart}} Can store up to 3 red hearts to use {{Collectible"..mod.Enums.Collectibles.EL_ROI.."}} El Roi #{{Collectible"..CollectibleType.COLLECTIBLE_THERES_OPTIONS.."}} Defeating a boss without using El Roi grants a choice between two boss items", "Hagar")
EID:addBirthright(mod.Enums.Character.HAGAR, "{{Heart}} Increases the maximum amount of red hearts that can be stored to 12 #{{Collectible"..mod.Enums.Collectibles.EL_ROI.."}} El Roi can now spend 6 hearts in exchange for a stat up for the current room: #{{Indent}}{{ArrowUp}} +1.5 {{Tears}} fire rate #{{Indent}}{{ArrowUp}} +1 {{Damage}} damage", "Hagar")

EID:addCharacterInfo(mod.Enums.Character.T_HAGAR, "Can't have more than 4 hearts at a time # Can't have more than 2 types of hearts at a time # Killed enemies have a chance to drop a random heart", "Hagar")
EID:addBirthright(mod.Enums.Character.T_HAGAR, "{{Collectible"..mod.Enums.Collectibles.ZAMZAM.."}} When Zamzam's protection expires, deals another instance of contact damage to all nearby enemies #Damage increased based on amount of hearts spent on current bubble", "Hagar")

-- Slight hud adjustment to account for heart counter
mod:AddCallback(ModCallbacks.MC_POST_RENDER, function ()
    if not EID.player then return end
    if EID.player:GetPlayerType() == mod.Enums.Character.HAGAR then
        EID:addTextPosModifier("Hagar HUD", Vector(0, 10))
    else
        EID:removeTextPosModifier("Hagar HUD")
    end
end)

local elRoiDesc = "{{Heart}} Requires 1 Red Heart to use #{{Collectible%d}} Grants the Wafer effect for the room, reducing all damage to 0.5 hearts #Decreases the max HP of every enemy in the room, once per room"
elRoiDesc = elRoiDesc:format(CollectibleType.COLLECTIBLE_WAFER)
-- variable unused, just use as a description reference
local elRoiDescHagar = "{{Heart}} Requires 1 stored Red Heart to use, or 2 stored hearts in {{BossRoom}} Boss Rooms #{{Collectible%d}} Grants the Wafer effect for the room, reducing all damage to 0.5 hearts #Decreases the max HP of every enemy in the room, once per room #Enemy HP is decreased enough to reverse Hagar's passive monster health scaling"
elRoiDescHagar = elRoiDescHagar:format(CollectibleType.COLLECTIBLE_WAFER)

EID:addCollectible(mod.Enums.Collectibles.EL_ROI, elRoiDesc)
EID:addPlayerCondition(mod.Enums.Collectibles.EL_ROI, mod.Enums.Character.HAGAR, "{{Heart}} Requires 1 Red Heart to use", "{{Heart}} Requires 1 stored Red Heart to use, or 2 stored hearts in {{BossRoom}} Boss Rooms", EID.DefaultLanguageCode, {}, false)
EID:addPlayerCondition(mod.Enums.Collectibles.EL_ROI, mod.Enums.Character.HAGAR, "Enemy HP is decreased enough to reverse Hagar's passive monster health scaling", nil, EID.DefaultLanguageCode, {}, false)

EID:addCollectible(mod.Enums.Collectibles.ZAMZAM, "{{Heart}} Hearts that cannot be picked up are instead stored in the well #On use, consumes a stored heart to grant temporary vulnerability and contact damage #Has additional effects depending on hearts used #Dealing contact damage grants a fading tears up")