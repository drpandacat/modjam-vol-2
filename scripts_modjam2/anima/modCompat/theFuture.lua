local constants = include "scripts_modjam2.anima.constants"


function AnimaCharacter:AddTheFutureCompat()
    if TheFuture then
        TheFuture.ModdedCharacterDialogue["Anima"] = {
            "is it just me or did I see you?",
            "oh you just wearing the mask",
            "nevermind...",
            "now look into my eyes",
            "and disturb the peace",
        }

        TheFuture.ModdedTaintedCharacterDialogue["Anima"] = {
            "woah, no way!",
            "a phantom fan? out here?", -- (Phantom of the Opera)
            "oh, that's not what the mask is for?",
            "how insensitive of me...",
            "well, at the very least,",
            "put on a good show for my audience in there",
        }
    end
end
