-- ╔══════════════════════════════════════════╗
-- ║          SERVER / STORAGE.LUA            ║
-- ║    Lager-System – ox_inventory Stash     ║
-- ╚══════════════════════════════════════════╝

local ADMIN_ACE = 'qbx_firedepartmentjob.admin'
local function GetPlayer(src) return exports.qbx_core:GetPlayer(src) end

local function GetStashId(storageId)
    return 'fd_storage_' .. storageId
end

local function RegisterStash(storageId, storage)
    exports.ox_inventory:RegisterStash(
        GetStashId(storageId),  -- id
        storage.label,           -- label
        50,                      -- slots
        100000,                  -- weight (gramm)
        nil,                     -- owner (nil = geteilt)
        { firefighter = 0 },     -- groups (nur Feuerwehr)
        vector3(storage.coords.x, storage.coords.y, storage.coords.z)  -- coords (vector3, nicht vector4)
    )
    DebugLog('storage', 'Stash %s registriert', GetStashId(storageId))
end

CreateThread(function()
    Wait(1000)
    for storageId, storage in pairs(Config.Storage.Locations) do
        RegisterStash(storageId, storage)
    end
end)

RegisterNetEvent('qbx_firedepartmentjob:server:OpenStorage', function(storageId)
    local src    = source
    local Player = GetPlayer(src)
    if not Player then return end
    if not IsFirefighter(Player.PlayerData.job) then return end

    local storage = Config.Storage.Locations[storageId]
    if not storage then return end

    exports.ox_inventory:forceOpenInventory(src, 'stash', GetStashId(storageId))
    DebugLog('storage', 'Spieler %d öffnet Lager %d', src, storageId)
end)

RegisterNetEvent('qbx_firedepartmentjob:server:AdminAddStorage', function(data)
    local src = source
    if not IsPlayerAceAllowed(src, ADMIN_ACE) then return end

    local newId = 1
    for id in pairs(Config.Storage.Locations) do
        if id >= newId then newId = id + 1 end
    end

    Config.Storage.Locations[newId] = {
        label     = data.label or ('Lager ' .. newId),
        coords    = vector4(data.x, data.y, data.z, data.w or 0.0),
        stationId = data.stationId or nil,
        items     = {},
    }

    RegisterStash(newId, Config.Storage.Locations[newId])
    SaveStorageConfig(newId)

    TriggerClientEvent('qbx_firedepartmentjob:client:AddStorageLocation', -1, newId, {
        label     = Config.Storage.Locations[newId].label,
        coords    = { x = data.x, y = data.y, z = data.z, w = data.w or 0.0 },
        stationId = data.stationId,
    })

    TriggerClientEvent('ox_lib:notify', src, {
        title = '📦 Lager', description = 'Lager ' .. newId .. ' angelegt.', type = 'success',
    })
end)

RegisterNetEvent('qbx_firedepartmentjob:server:AdminDeleteStorage', function(storageId)
    local src = source
    if not IsPlayerAceAllowed(src, ADMIN_ACE) then return end

    storageId = tonumber(storageId)
    if not storageId or not Config.Storage.Locations[storageId] then return end

    Config.Storage.Locations[storageId] = nil
    MySQL.update('DELETE FROM fd_config WHERE `key` = ?', { 'storage_' .. storageId })
    TriggerClientEvent('qbx_firedepartmentjob:client:RemoveStorageLocation', -1, storageId)

    TriggerClientEvent('ox_lib:notify', src, {
        title = '📦 Lager', description = 'Lager ' .. storageId .. ' gelöscht.', type = 'success',
    })
end)

RegisterNetEvent('qbx_firedepartmentjob:server:AdminAddStation', function(data)
    local src = source
    if not IsPlayerAceAllowed(src, ADMIN_ACE) then return end

    local newId = 1
    for id in pairs(Config.Stations) do
        if id >= newId then newId = id + 1 end
    end

    Config.Stations[newId] = {
        label  = data.label or ('Wache ' .. newId),
        coords = vector4(data.x, data.y, data.z, data.w or 0.0),
        blip   = { sprite = 436, color = 1, scale = 0.8 },
    }
    Config.VehicleSpawns[newId] = {}

    local j = json.encode({ label = Config.Stations[newId].label, x = data.x, y = data.y, z = data.z, w = data.w or 0.0 })
    MySQL.update('INSERT INTO fd_config (`key`, `value`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `value` = ?', { 'station_' .. newId, j, j })

    TriggerClientEvent('qbx_firedepartmentjob:client:AddStationLocation', -1, newId, Config.Stations[newId])
    TriggerClientEvent('ox_lib:notify', src, { title = '🚒 Wache', description = 'Wache ' .. newId .. ' angelegt.', type = 'success' })
end)

RegisterNetEvent('qbx_firedepartmentjob:server:AdminDeleteStation', function(stationId)
    local src = source
    if not IsPlayerAceAllowed(src, ADMIN_ACE) then return end

    stationId = tonumber(stationId)
    if not stationId or not Config.Stations[stationId] then return end

    Config.Stations[stationId]      = nil
    Config.VehicleSpawns[stationId] = nil
    MySQL.update('DELETE FROM fd_config WHERE `key` LIKE ?', { 'station_' .. stationId })
    MySQL.update('DELETE FROM fd_config WHERE `key` LIKE ?', { 'vehiclespawn__' .. stationId .. '_%' })

    TriggerClientEvent('qbx_firedepartmentjob:client:RemoveStationLocation', -1, stationId)
    TriggerClientEvent('ox_lib:notify', src, { title = '🚒 Wache', description = 'Wache ' .. stationId .. ' gelöscht.', type = 'success' })
end)

RegisterNetEvent('qbx_firedepartmentjob:server:AdminAddVehicleSpawn', function(stationId, data)
    local src = source
    if not IsPlayerAceAllowed(src, ADMIN_ACE) then return end

    stationId = tonumber(stationId)
    if not Config.VehicleSpawns[stationId] then Config.VehicleSpawns[stationId] = {} end

    local spawns = Config.VehicleSpawns[stationId]
    local newIdx = #spawns + 1
    spawns[newIdx] = {
        model  = data.model or 'firetruk',
        label  = data.label or 'Fahrzeug',
        coords = vector4(data.x, data.y, data.z, data.w or 0.0),
    }

    local j = json.encode({ model = spawns[newIdx].model, label = spawns[newIdx].label, coords = { x = data.x, y = data.y, z = data.z, w = data.w or 0.0 } })
    MySQL.update('INSERT INTO fd_config (`key`, `value`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `value` = ?', { 'vehiclespawn__' .. stationId .. '_' .. newIdx, j, j })

    TriggerClientEvent('qbx_firedepartmentjob:client:AddVehicleSpawn', -1, stationId, newIdx, spawns[newIdx])
    TriggerClientEvent('ox_lib:notify', src, { title = '🚒 Spawn', description = string.format('Spawn %d/%d hinzugefügt.', stationId, newIdx), type = 'success' })
end)

RegisterNetEvent('qbx_firedepartmentjob:server:AdminDeleteVehicleSpawn', function(stationId, spawnIdx)
    local src = source
    if not IsPlayerAceAllowed(src, ADMIN_ACE) then return end

    stationId = tonumber(stationId)
    spawnIdx  = tonumber(spawnIdx)
    if not Config.VehicleSpawns[stationId] or not Config.VehicleSpawns[stationId][spawnIdx] then return end

    table.remove(Config.VehicleSpawns[stationId], spawnIdx)
    MySQL.update('DELETE FROM fd_config WHERE `key` = ?', { 'vehiclespawn__' .. stationId .. '_' .. spawnIdx })

    TriggerClientEvent('qbx_firedepartmentjob:client:RemoveVehicleSpawn', -1, stationId, spawnIdx)
    TriggerClientEvent('ox_lib:notify', src, { title = '🚒 Spawn', description = 'Spawn gelöscht.', type = 'success' })
end)

function SaveStorageConfig(storageId)
    local storage = Config.Storage.Locations[storageId]
    if not storage then return end
    local val = {
        label = storage.label,
        x = storage.coords.x, y = storage.coords.y,
        z = storage.coords.z, w = storage.coords.w,
        stationId = storage.stationId,
    }
    local j = json.encode(val)
    MySQL.update('INSERT INTO fd_config (`key`, `value`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `value` = ?', { 'storage_' .. storageId, j, j })
end

AddEventHandler('qbx_firedepartmentjob:server:LoadStorageConfigs', function(rows)
    for _, row in ipairs(rows) do
        if row.key:sub(1, 8) == 'storage_' then
            local storageId = tonumber(row.key:sub(9))
            local ok, val = pcall(json.decode, row.value)
            if ok and storageId then
                Config.Storage.Locations[storageId] = {
                    label     = val.label or ('Lager ' .. storageId),
                    coords    = vector4(val.x or 0, val.y or 0, val.z or 0, val.w or 0),
                    stationId = val.stationId,
                    items     = {},
                }
            end
        end
    end
    for storageId, storage in pairs(Config.Storage.Locations) do
        RegisterStash(storageId, storage)
    end
    print('^2[FD] Storage-Stashes aus DB geladen und registriert^7')
end)

AddEventHandler('qbx_firedepartmentjob:server:SendStorageToClient', function(src)
    TriggerClientEvent('qbx_firedepartmentjob:client:LoadStorageConfig', src, Config.Storage.Locations)
end)