local constants = include "scripts_modjam2.anima.constants"

local mod = AnimaCharacter
local eid = EID

local playerIconSprite = Sprite("gfx/anima/modCompat/general/player icon.anm2", true)

if eid then
    --eid:addCharacterInfo(constants.Players.Anima, "to-do", "Anima")

    eid:addCollectible(constants.Items.Persona, "Allows you to choose 3 random personas that have their own unique effects#The pool of personas changes with each new floor#Selection is made by clicking the drop button ({{ButtonRT}})")
    eid:addCollectible(constants.Items.DualRole, "Automatically uses itself when fully charged#Switches between allowing you to choose one of 3 random personas to gain the effect of, and forcing a negative 'tragedy' effect onto the player")

    eid:addPlayerCondition(constants.Items.Persona, constants.Players.Anima, "Taking non-self damage has a chance to remove the currently active persona from the pool, breaking the item# When the item is broken, the player can choose from the remaining personas in the pool, but only once#The item is restored on the next floor")

    eid:addBirthright(constants.Players.Anima, "Increases pool of personas to 5#The chance to lose persona is decreased")
    eid:addBirthright(constants.Players.TaintedAnima, ("50%% chance to not gain a tragedy effect from {{Collectible%d}} Dual Role"):format(constants.Items.DualRole))

    eid:addIcon("Player" .. constants.Players.Anima, "Anima", 0, 16, 16, 5, 6, playerIconSprite)
    eid:addIcon("Player" .. constants.Players.TaintedAnima, "AnimaB", 0, 16, 16, 5, 6, playerIconSprite)
end
