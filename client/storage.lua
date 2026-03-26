-- ╔══════════════════════════════════════════╗
-- ║          CLIENT / STORAGE.LUA            ║
-- ║    Lager-System – ox_inventory Stash     ║
-- ╚══════════════════════════════════════════╝

local storageTargets = {}
local stationTargets = {}
local stationBlipsList = {}

-- ──────────────────────────────────────────
-- LAGER OX_TARGET ZONE
-- ──────────────────────────────────────────

local function RegisterStorageTarget(storageId, storage)
    if storageTargets[storageId] then
        exports.ox_target:removeZone(storageTargets[storageId])
    end

    local zoneId = exports.ox_target:addBoxZone({
        coords   = vector3(storage.coords.x, storage.coords.y, storage.coords.z),
        size     = vector3(2.0, 2.0, 2.2),
        rotation = storage.coords.w,
        debug    = false,
        options  = {
            {
                name     = 'fd_storage_' .. storageId,
                label    = '📦 ' .. storage.label .. ' öffnen',
                icon     = 'fas fa-box-open',
                distance = 2.5,
                canInteract = function()
                    return IsFirefighter(exports.qbx_core:GetPlayerData().job)
                end,
                onSelect = function()
                    TriggerServerEvent('qbx_firedepartmentjob:server:OpenStorage', storageId)
                end,
            },
        },
    })
    storageTargets[storageId] = zoneId
end

-- ──────────────────────────────────────────
-- INITIALISIERUNG
-- ──────────────────────────────────────────

local function InitStorageTargets()
    for storageId, storage in pairs(Config.Storage.Locations) do
        RegisterStorageTarget(storageId, storage)
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(1500)
        InitStorageTargets()
    end)
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    CreateThread(function()
        Wait(800)
        InitStorageTargets()
    end)
end)

-- ──────────────────────────────────────────
-- DYNAMISCHE UPDATES (Admin)
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:AddStorageLocation', function(storageId, storage)
    Config.Storage.Locations[storageId] = {
        label     = storage.label,
        coords    = vector4(storage.coords.x, storage.coords.y, storage.coords.z, storage.coords.w or 0),
        stationId = storage.stationId,
        items     = {},
    }
    RegisterStorageTarget(storageId, Config.Storage.Locations[storageId])
    lib.notify({ title = '📦 Lager', description = 'Neues Lager verfügbar: ' .. storage.label, type = 'inform' })
end)

RegisterNetEvent('qbx_firedepartmentjob:client:RemoveStorageLocation', function(storageId)
    if storageTargets[storageId] then
        exports.ox_target:removeZone(storageTargets[storageId])
        storageTargets[storageId] = nil
    end
    Config.Storage.Locations[storageId] = nil
end)

-- Config vom Server (nach RequestClientConfig)
RegisterNetEvent('qbx_firedepartmentjob:client:LoadStorageConfig', function(locations)
    for id, zoneId in pairs(storageTargets) do
        exports.ox_target:removeZone(zoneId)
    end
    storageTargets = {}

    for storageId, storage in pairs(locations) do
        Config.Storage.Locations[storageId] = {
            label     = storage.label,
            coords    = vector4(storage.coords.x or 0, storage.coords.y or 0, storage.coords.z or 0, storage.coords.w or 0),
            stationId = storage.stationId,
            items     = {},
        }
        RegisterStorageTarget(storageId, Config.Storage.Locations[storageId])
    end
end)

-- ──────────────────────────────────────────
-- DYNAMISCHE WACHEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:AddStationLocation', function(stationId, station)
    Config.Stations[stationId] = {
        label  = station.label,
        coords = vector4(station.coords.x, station.coords.y, station.coords.z, station.coords.w),
        blip   = station.blip or { sprite = 436, color = 1, scale = 0.8 },
    }
    Config.VehicleSpawns[stationId] = {}

    -- Blip
    local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
    SetBlipSprite(blip, 436)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(station.label)
    EndTextCommandSetBlipName(blip)
    stationBlipsList[stationId] = blip

    -- ox_target Zone
    local zoneId = exports.ox_target:addBoxZone({
        coords   = vector3(station.coords.x, station.coords.y, station.coords.z),
        size     = vector3(1.5, 1.5, 2.0),
        rotation = station.coords.w,
        debug    = false,
        options  = {
            {
                name        = 'fd_mainmenu_' .. stationId,
                label       = 'Feuerwehr Menü',
                icon        = 'fas fa-fire',
                distance    = 2.0,
                canInteract = function() return IsFirefighter(exports.qbx_core:GetPlayerData().job) end,
                onSelect    = function() TriggerEvent('qbx_firedepartmentjob:client:OpenMainMenu') end,
            },
            {
                name        = 'fd_cloakroom_' .. stationId,
                label       = 'Umkleide',
                icon        = 'fas fa-tshirt',
                distance    = 2.0,
                canInteract = function() return IsFirefighter(exports.qbx_core:GetPlayerData().job) end,
                onSelect    = function() TriggerEvent('qbx_firedepartmentjob:client:OpenCloakroom') end,
            },
        },
    })
    stationTargets[stationId] = zoneId

    CreateStationBlips()
    lib.notify({ title = '🚒 Wache', description = 'Neue Wache: ' .. station.label, type = 'inform' })
end)

RegisterNetEvent('qbx_firedepartmentjob:client:RemoveStationLocation', function(stationId)
    Config.Stations[stationId]      = nil
    Config.VehicleSpawns[stationId] = nil
    if stationBlipsList[stationId] then
        RemoveBlip(stationBlipsList[stationId])
        stationBlipsList[stationId] = nil
    end
    if stationTargets[stationId] then
        exports.ox_target:removeZone(stationTargets[stationId])
        stationTargets[stationId] = nil
    end
    CreateStationBlips()
end)

RegisterNetEvent('qbx_firedepartmentjob:client:AddVehicleSpawn', function(stationId, spawnIdx, spawn)
    if not Config.VehicleSpawns[stationId] then Config.VehicleSpawns[stationId] = {} end
    Config.VehicleSpawns[stationId][spawnIdx] = {
        model  = spawn.model,
        label  = spawn.label,
        coords = vector4(spawn.coords.x, spawn.coords.y, spawn.coords.z, spawn.coords.w),
    }
    exports.ox_target:addBoxZone({
        coords   = vector3(spawn.coords.x, spawn.coords.y, spawn.coords.z),
        size     = vector3(3.0, 6.5, 2.0),
        rotation = spawn.coords.w,
        debug    = false,
        options  = {
            {
                name        = 'fd_vehicle_' .. stationId .. '_' .. spawnIdx,
                label       = spawn.label .. ' spawnen',
                icon        = 'fas fa-truck',
                distance    = 3.0,
                canInteract = function() return IsFirefighter(exports.qbx_core:GetPlayerData().job) end,
                onSelect    = function() TriggerEvent('qbx_firedepartmentjob:client:SpawnVehicle', spawn) end,
            },
        },
    })
end)

RegisterNetEvent('qbx_firedepartmentjob:client:RemoveVehicleSpawn', function(stationId, spawnIdx)
    if Config.VehicleSpawns[stationId] then
        Config.VehicleSpawns[stationId][spawnIdx] = nil
    end
    exports.ox_target:removeZone('fd_vehicle_' .. stationId .. '_' .. spawnIdx)
end)