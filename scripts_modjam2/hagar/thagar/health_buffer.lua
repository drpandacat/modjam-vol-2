HAGAR_MOD.Zamzam = {}

---@param player EntityPlayer
---@return string[]
function HAGAR_MOD.Zamzam.Buffer(player)
    local data = HAGAR_MOD.SaveManager.GetRunSave(player)
    data.ZamzamHealthBuffer = data.ZamzamHealthBuffer or {}
    return data.ZamzamHealthBuffer
end

---@param player EntityPlayer
---@param buffer string[]?
---@return boolean
function HAGAR_MOD.Zamzam.CanAddToBuffer(player, buffer)
    buffer = buffer or HAGAR_MOD.PlayerZamzamBuffer(player)
    local size = 6
    if BirthcakeRebaked and player:GetPlayerType() == HAGAR_MOD.Enums.Character.T_HAGAR then
        size = size + BirthcakeRebaked:GetTrinketMult(player)
    end
    return #buffer < size
end

---@param player EntityPlayer
---@param key string
---@return boolean
function HAGAR_MOD.Zamzam.AddToBuffer(player, key)
    local buffer = HAGAR_MOD.Zamzam.Buffer(player)
    local canAdd = HAGAR_MOD.Zamzam.CanAddToBuffer(player, buffer)
    if canAdd then
        table.insert(buffer, key)
        HAGAR_MOD.RenderCache.ZamzamBuffer[GetPtrHash(player)] = nil
    end
    return canAdd
end

---@param player EntityPlayer
---@return string?
function HAGAR_MOD.Zamzam.PopFromBuffer(player)
    local buffer = HAGAR_MOD.Zamzam.Buffer(player)
    if #buffer == 0 then
        return nil
    end
    local key = table.remove(buffer, 1)
    HAGAR_MOD.RenderCache.ZamzamBuffer[GetPtrHash(player)] = nil
    return key
end