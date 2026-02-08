local mod = _HART_MOD
local game = Game()
local sfx = SFXManager()

if EID then
	EID:addIcon("Player" .. mod.Character.HART, "Idle", 0, 16, 16, 0, 0, Sprite("gfx/compat/eid.anm2", true))
	EID:addIcon("Player" .. mod.Character.HART_B, "Idle", 1, 16, 16, 0, 0, Sprite("gfx/compat/eid.anm2", true))

	EID:addCharacterInfo(mod.Character.HART, "{{Luck}} Chance to {{Confusion}} confuse or {{Poison}} poison enemies on hit#{{Confusion}} Taking non-self damage causes confusion, which briefly inverts movement and prevents shooting#{{RottenHeart}} Rotten Hearts are more common", "Hart")
	EID:addBirthright(mod.Character.HART, "{{Confusion}} Allows shooting while confused")

	EID:addCharacterInfo(mod.Character.HART_B, "{{Luck}} Chance to {{Petrify}} petrify enemies on hit#{{Freezing}} Petrified enemies are frozen on death#{{Freezing}} Taking non-self damage freezes you temporarily, which prevents all actions#Mash movement buttons to unfreeze faster#\1 50% longer invincibility frames after taking damage", "Tainted Hart")
	EID:addBirthright(mod.Character.HART_B, "{{Freezing}} When frozen, you slide around the room and deal contact damage#Completely invincible while frozen#{{Luck}} Higher chance to petrify enemies on hit")
end