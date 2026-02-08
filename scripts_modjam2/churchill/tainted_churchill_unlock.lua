local game = Game()
local achievement = Isaac.GetAchievementIdByName("TaintedChurchill")
local gfxSlot = "gfx/characters/costumes/character_tainted_churchill.png"

local taintedAchievement = {
  [ChurchillMod.PLAYER_CHURCHILL] = {unlock = achievement, gfx = gfxSlot}
}

function ChurchillMod:SlotUpdate(slot)
  if not slot:GetSprite():IsFinished("PayPrize") then return end
  local d = slot:GetData().Tainted
  if d then
    Isaac.GetPersistentGameData():TryUnlock(d.unlock)
  end
end
ChurchillMod:AddCallback(ModCallbacks.MC_POST_SLOT_UPDATE, ChurchillMod.SlotUpdate, 14)

function ChurchillMod:HiddenCloset()
  if game:GetLevel():GetStage() ~= LevelStage.STAGE8 then return end
  if game:GetLevel():GetCurrentRoomDesc().SafeGridIndex ~= 94 then return end
  if game:AchievementUnlocksDisallowed() then return end
  local p = Isaac.GetPlayer():GetPlayerType()
  local d = taintedAchievement[p]
  if not d then return end
  local g = Isaac.GetPersistentGameData()
  if g:Unlocked(d.unlock) then return end
  if game:GetRoom():IsFirstVisit() then
    for _, k in ipairs(Isaac.FindByType(17)) do
      k:Remove()
    end
    for _, i in ipairs(Isaac.FindByType(5)) do
      i:Remove()
    end
    local s = Isaac.Spawn(6, 14, 0, game:GetRoom():GetCenterPos(), Vector.Zero, nil)
    s:GetSprite():ReplaceSpritesheet(0, d.gfx, true)
    s:GetData().Tainted = d
  else
    for _, s in ipairs(Isaac.FindByType(6, 14)) do
      s:GetSprite():ReplaceSpritesheet(0, d.gfx, true)
      s:GetData().Tainted = d
    end
  end
end
ChurchillMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, ChurchillMod.HiddenCloset)