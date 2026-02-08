local OPTIONS_ITEMS = {
    CollectibleType.COLLECTIBLE_THERES_OPTIONS,
    CollectibleType.COLLECTIBLE_MORE_OPTIONS,
    CollectibleType.COLLECTIBLE_OPTIONS,
}

---@param pl EntityPlayer
---@param id CollectibleType
local function hasInnateItem(pl, id)
    return (pl:HasCollectible(id, false, false) and not pl:HasCollectible(id, false, true))
end

local function grantOptions(_)
    local conf = Isaac.GetItemConfig()
    local level = Game():GetLevel()
    local rng = RNG(level:GetDungeonPlacementSeed())

    for i=0, Game():GetNumPlayers()-1 do
        local pl = Isaac.GetPlayer(i)
        if(pl:GetPlayerType()==RandomMod.PLAYER_RANDOM) then
            for _, id in ipairs(OPTIONS_ITEMS) do
                if(hasInnateItem(pl, id)) then
                    pl:AddInnateCollectible(id, -1)
                end

                if(not pl:HasCollectible(id)) then
                    pl:RemoveCostume(conf:GetCollectible(id))
                end
            end

            pl:RemoveCostume(conf:GetNullItem(RandomMod.COSTUME_OPTION_TRINITY))

            if(pl:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)) then
                for _, id in ipairs(OPTIONS_ITEMS) do
                    pl:AddInnateCollectible(id, 1)
                end
                pl:AddCostume(conf:GetNullItem(RandomMod.COSTUME_OPTION_TRINITY))
            else
                local rnd = OPTIONS_ITEMS[rng:RandomInt(1, #OPTIONS_ITEMS)]
                pl:AddInnateCollectible(rnd, 1)
                if(rnd==CollectibleType.COLLECTIBLE_OPTIONS) then
                    pl:AddCostume(conf:GetNullItem(RandomMod.COSTUME_OPTIONS))
                end
            end
        end
    end
end
RandomMod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, grantOptions)

---@param pl EntityPlayer
local function giveRandomHealthOnStart(_, pl)
    local rnd = pl:GetDropRNG():RandomInt(0,8)
    if(rnd==0) then
        pl:AddMaxHearts(2)
        pl:AddHearts(2)
    elseif(rnd==1) then
        pl:AddSoulHearts(2)
    elseif(rnd==2) then
        pl:AddBlackHearts(2)
    elseif(rnd==3) then
        pl:AddRottenHearts(1)
    elseif(rnd==4) then
        pl:AddBoneHearts(1)
        pl:AddHearts(2)
    elseif(rnd==5) then
        pl:AddGoldenHearts(1)
    elseif(rnd==6) then
        pl:AddEternalHearts(1)
    elseif(rnd==7) then
        pl:AddMaxHearts(2)
    elseif(rnd==8) then
        pl:AddBoneHearts(1)
    end

    local rnd2 = pl:GetDropRNG():RandomInt(0,2)
    if(rnd2==0) then
        pl:AddCoins(3)
    elseif(rnd2==1) then
        pl:AddBombs(1)
    elseif(rnd2==2) then
        pl:AddKeys(1)
    end
end
RandomMod:AddCallback(ModCallbacks.MC_PLAYER_INIT_POST_LEVEL_INIT_STATS, giveRandomHealthOnStart, RandomMod.PLAYER_RANDOM)