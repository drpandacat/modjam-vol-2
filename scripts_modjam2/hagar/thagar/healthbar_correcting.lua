local mod = HAGAR_MOD

local HEART_TYPE_LIMIT = 2

---@param a any[]
---@param b any[]
---@return table
local function HeartTypesDiff(a, b)
    local result = {}
    for _, av in ipairs(a) do
        local isContained = false
        for _, bv in ipairs(b) do
            if av == bv then
                isContained = true
                break
            end
        end
        if not isContained then
            table.insert(result, av)
        end
    end
    return result
end

local HEALTH_TYPE_TO_REMOVE_FUNC = {
    [AddHealthType.RED] = "AddHearts",
    [AddHealthType.SOUL] = "AddSoulHearts",
    [AddHealthType.ETERNAL] = "AddEternalHearts",
    [AddHealthType.BLACK] = "AddBlackHearts",
    [AddHealthType.GOLDEN] = "AddGoldenHearts",
    [AddHealthType.BONE] = "AddBoneHearts",
    [AddHealthType.ROTTEN] = "AddRottenHearts",
}

local HEALTH_TYPE_TO_NAME = {
    [AddHealthType.RED] = "Red",
    [AddHealthType.SOUL] = "Soul",
    [AddHealthType.ETERNAL] = "Eternal",
    [AddHealthType.BLACK] = "Black",
    [AddHealthType.GOLDEN] = "Gold",
    [AddHealthType.BONE] = "Bone",
    [AddHealthType.ROTTEN] = "Rotten",
}

local ADD_HEART_TYPE_TO_STORED_HEART_KEY = {
    [AddHealthType.RED] = mod.Enums.StoredHeartKeys.RED,
    [AddHealthType.SOUL] = mod.Enums.StoredHeartKeys.SOUL,
    [AddHealthType.BLACK] = mod.Enums.StoredHeartKeys.BLACK,
    [AddHealthType.ETERNAL] = mod.Enums.StoredHeartKeys.ETERNAL,
    [AddHealthType.GOLDEN] = mod.Enums.StoredHeartKeys.GOLDEN,
    [AddHealthType.BONE] = mod.Enums.StoredHeartKeys.BONE,
    [AddHealthType.ROTTEN] = mod.Enums.StoredHeartKeys.ROTTEN,
}

local HEARTS_WITH_HALVES = {
    [AddHealthType.RED] = true,
    [AddHealthType.SOUL] = true,
    [AddHealthType.BLACK] = true,
}

---@param player EntityPlayer
local function PostPeffectUpdate(_, player)
    local data = player:GetData()
    local newHeartTypes = mod.Lib.CurrentHealthTypes(player)

    local oldHeartTypes = data.HagarLastFrameHealthTypes or newHeartTypes
    if #newHeartTypes > HEART_TYPE_LIMIT then
        local newHealthCounts = mod.Lib.HealthCounts(player)
        local diff = HeartTypesDiff(newHeartTypes, oldHeartTypes)
        local healthTypesToRemove = #newHeartTypes - HEART_TYPE_LIMIT   --Should be redundant, but am worried about some potential modded item that rerolls all health into different health types and causes an instant death.
        for _, heartType in ipairs(diff) do
            local succeeded = true
            local removeFunc = HEALTH_TYPE_TO_REMOVE_FUNC[heartType]

            if not removeFunc then
                succeeded = Isaac.RunCallbackWithParam(mod.Enums.Callbacks.REMOVE_EXCESS_HEART_TYPE, heartType, player)

                if type(succeeded) == "number" then
                    local heartKey = Isaac.RunCallbackWithParam(mod.Enums.Callbacks.HEART_TYPE_TO_HEART_KEY, heartType)
                    if heartKey then
                        for i = 1, succeeded do
                            mod.Zamzam.AddToBuffer(player, heartKey)
                        end
                    end
                end
            else
                local fieldName = HEALTH_TYPE_TO_NAME[heartType]
                player[removeFunc](player, -newHealthCounts[fieldName])

                local countToAdd = newHealthCounts[fieldName]
                if HEARTS_WITH_HALVES[heartType] then
                    countToAdd = math.ceil(countToAdd/2)
                end
                local keyToAdd = ADD_HEART_TYPE_TO_STORED_HEART_KEY[heartType]
                for i = 1, countToAdd do
                    mod.Zamzam.AddToBuffer(player, keyToAdd)
                end
            end

            if succeeded then
                healthTypesToRemove = healthTypesToRemove-1
                if healthTypesToRemove == 0 then
                    break
                end
            end
        end
    end

    data.HagarLastFrameHealthTypes = newHeartTypes
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, PostPeffectUpdate, mod.Enums.Character.T_HAGAR)