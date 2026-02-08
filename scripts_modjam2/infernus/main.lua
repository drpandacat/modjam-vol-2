---@class DeadlockMod : ModReference
DeadlockMod = RegisterMod("Dead", 1)

DeadlockMod.game = Game()
DeadlockMod.hud = DeadlockMod.game:GetHUD()
DeadlockMod.sfx = SFXManager()
DeadlockMod.music = MusicManager()

include("scripts_modjam2.infernus.scriptLoader")
