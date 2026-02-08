if EID then
    EID:setModIndicatorName("Deadlock")

    local icons = Sprite()
    icons:Load("gfx/ui/deadlock_eid.anm2", true)
    EID:addIcon("Player"..DeadlockMod.playerType.INFERNUS, "Infernus", 0, 32, 32, 4, 4
    , icons)

    local BoonIcon = Sprite()
    BoonIcon:Load("gfx/ui/deadlock_eid.anm2", true)
    EID:addIcon("Boon", "Boon", 0, 16, 16, -3, -3, BoonIcon)

    EID:addBirthright(DeadlockMod.playerType.INFERNUS, "Grants 31 {{Boon}}Boons.", "Infernus")


end