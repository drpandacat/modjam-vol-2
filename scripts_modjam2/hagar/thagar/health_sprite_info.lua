local mod = HAGAR_MOD

---@class ZamzamHeartSprite
---@field HeartSprite Sprite
---@field HeartFrame integer
---@field WellSprite Sprite
---@field WellFrame integer
---@field R number
---@field G number
---@field B number

---@type {[string] : ZamzamHeartSprite}
mod.THagarHeartTypes = {}
---@type integer[][]
mod.THagarHealthColors = {}

---@param key string
---@param heartSprite Sprite
---@param heartFrame integer
---@param wellSprite Sprite
---@param wellFrame integer
function mod.RegisterHeartType(key, heartSprite, heartFrame, wellSprite, wellFrame, r, g, b)
    if mod.THagarHeartTypes[key] then
        print("[HAGAR MOD] " .. key ..  " heart type was already registered!")
        return
    end

    mod.THagarHeartTypes[key] = {
        HeartSprite = heartSprite,
        HeartFrame = heartFrame,
        WellSprite = wellSprite,
        WellFrame = wellFrame,
        R = r,
        G = g,
        B = b,
    }
end

function mod.RegisterHealthTypeColor(healthKey, r, g, b)
    mod.THagarHealthColors[healthKey] = {r,g,b}
end

local baseHeartsSprite = Sprite()
baseHeartsSprite:Load("gfx/ui/ui_crafting.anm2", true)
baseHeartsSprite:Play("Idle", true)

local baseWellSprite = Sprite()
baseWellSprite:Load("gfx/ui/zamzam_vanilla_variants.anm2")
baseWellSprite:Play("Idle", true)

mod.RegisterHeartType(mod.Enums.StoredHeartKeys.RED, baseHeartsSprite, 1, baseWellSprite, 1, 1, 0.3, 0.3)
mod.RegisterHeartType(mod.Enums.StoredHeartKeys.SOUL, baseHeartsSprite, 2, baseWellSprite, 2, 0.6, 0.6, 0.9)
mod.RegisterHeartType(mod.Enums.StoredHeartKeys.BLACK, baseHeartsSprite, 3, baseWellSprite, 3, 0.2, 0.2, 0.2)
mod.RegisterHeartType(mod.Enums.StoredHeartKeys.ETERNAL, baseHeartsSprite, 4, baseWellSprite, 4, 1, 1, 1)
mod.RegisterHeartType(mod.Enums.StoredHeartKeys.GOLDEN, baseHeartsSprite, 5, baseWellSprite, 5, 0.9, 0.6, 0.2)
mod.RegisterHeartType(mod.Enums.StoredHeartKeys.BONE, baseHeartsSprite, 6, baseWellSprite, 6, 0.6, 0.6, 0.6)
mod.RegisterHeartType(mod.Enums.StoredHeartKeys.ROTTEN, baseHeartsSprite, 7, baseWellSprite, 7, 0.3, 0.5, 0.2)

mod.RegisterHealthTypeColor(AddHealthType.RED, 0.8, 0.2, 0.2)
mod.RegisterHealthTypeColor(AddHealthType.SOUL, 0.5, 0.5, 1)
mod.RegisterHealthTypeColor(AddHealthType.BLACK, 0.2, 0.2, 0.2)
mod.RegisterHealthTypeColor(AddHealthType.ETERNAL, 0.8, 0.8, 0.8)
mod.RegisterHealthTypeColor(AddHealthType.GOLDEN, 0.9, 0.7, 0.3)
mod.RegisterHealthTypeColor(AddHealthType.BONE, 0.6, 0.6, 0.6)
mod.RegisterHealthTypeColor(AddHealthType.ROTTEN, 0.3, 0.5, 0.1)

local moddedHeartsSprite = Sprite()
moddedHeartsSprite:Load("gfx/ui/zamzam_modded_hearts.anm2", true)
moddedHeartsSprite:Play("Idle", true)

local moddedWellSprite = Sprite()
moddedWellSprite:Load("gfx/ui/zamzam_modded_variants.anm2")
moddedWellSprite:Play("Idle", true)

mod.RegisterHeartType(mod.Enums.StoredHeartKeys.FF_IMMORAL, moddedHeartsSprite, 1, moddedWellSprite, 1, 0.4, 0.0, 0.4)
mod.RegisterHeartType(mod.Enums.StoredHeartKeys.FF_MORBID, moddedHeartsSprite, 2, moddedWellSprite, 2, 0.1, 0.2, 0.1)
mod.RegisterHeartType(mod.Enums.StoredHeartKeys.EP_BROKEN, moddedHeartsSprite, 3, moddedWellSprite, 3, 0.55, 0.2, 0.2)
mod.RegisterHeartType(mod.Enums.StoredHeartKeys.EP_SANCTIFIED, moddedHeartsSprite, 4, moddedWellSprite, 4, 0.7, 0.8, 1)
mod.RegisterHeartType(mod.Enums.StoredHeartKeys.RM_SUN, moddedHeartsSprite, 5, moddedWellSprite, 5, 0.9, 0.8, 0.2)
mod.RegisterHeartType(mod.Enums.StoredHeartKeys.RM_ILLUSION, moddedHeartsSprite, 6, moddedWellSprite, 6, 1, 0.35, 1)
mod.RegisterHeartType(mod.Enums.StoredHeartKeys.RM_IMMORTAL, moddedHeartsSprite, 7, moddedWellSprite, 7, 0.9, 0.9, 0.9)
mod.RegisterHeartType(mod.Enums.StoredHeartKeys.CON, moddedHeartsSprite, 8, moddedWellSprite, 8, 0.2, 0.2, 0.6)

mod.RegisterHealthTypeColor(mod.Enums.ModdedHeartTypes.FF_IMMORAL, 0.7, 0.3, 0.7)
mod.RegisterHealthTypeColor(mod.Enums.ModdedHeartTypes.FF_MORBID, 0.1, 0.3, 0.2)
mod.RegisterHealthTypeColor(mod.Enums.ModdedHeartTypes.EP_BROKEN, 0.5, 0.2, 0.2)
mod.RegisterHealthTypeColor(mod.Enums.ModdedHeartTypes.EP_SANCTIFIED, 0.7, 0.7, 1)
mod.RegisterHealthTypeColor(mod.Enums.ModdedHeartTypes.RM_SUN, 1, 0.8, 0.5)
mod.RegisterHealthTypeColor(mod.Enums.ModdedHeartTypes.RM_ILLUSION, 0.7, 0.4, 0.7)
mod.RegisterHealthTypeColor(mod.Enums.ModdedHeartTypes.RM_IMMORTAL, 0.7, 0.7, 0.7)