---@class AnimaPlayerLevelData
---@field HasLostPersona boolean

---@class AnimaStorage
---@field CurrentPersona eAnimaPersonas @current active perosna
---@field CurrentCostumeID NullItemID | integer @costume for the currently active persona
---@field AnimaPersonas eAnimaPersonas[] @pool of personas, 5 with birthright and 3 without. Refreshes on new stage
---@field PersonaActiveStatus PersonaActiveStatus @used for persona active item
---@field PersonaInnateItem CollectibleType @innate item for the currently active persona
---@field HadPersonaBefore boolean @sets to ``true`` after new stage if persona is currently active. Used for increased chance to lose persona
---@field LostDecoyPlayer boolean @for J&E persona.  Prevents Decoy spawn on current stage after switching/losing persona or if Decoy died
---@field EdenPersonaStats number[]
---@field LazarusUsedRevive boolean@for Lazarus persona. Prevents revive gain if it was already used on the current stage
---@field SeenDescriptions boolean[]

---@class TAnimaDualRoleData
---@field CharacterState DualRoleState @Whether Tainted Anima will get a positive Persona effect or negative Tragedy effect when Dual Role gets used next
---@field CurrentTragedy AnimaTragedies
---@field EdenStats number[]

---@class AnimaPlayerData
---@field AnimaCurrentStorage AnimaStorage
---@field DualRoleData TAnimaDualRoleData

---@class AnimaFamiliarData
---@field IsPersonaWisp boolean

---@class GetDataTempData
---@field EveKillBirds integer

---@class AnimaGetData
---@field IsHoldingPersona boolean
---@field AnimaSelectedPersonaIndex integer
---@field AnimaExtraTempData GetDataTempData