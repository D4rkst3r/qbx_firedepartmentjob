-- ╔══════════════════════════════════════════╗
-- ║        CLIENT / ADMIN.LUA               ║
-- ╚══════════════════════════════════════════╝

local panelOpen = false

-- ──────────────────────────────────────────
-- PANEL ÖFFNEN (vom Server authorisiert)
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:OpenAdminPanel', function(data)
    panelOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'openPanel', data = data })
end)

-- ──────────────────────────────────────────
-- NUI CALLBACKS
-- ──────────────────────────────────────────

-- Panel schließen
RegisterNUICallback('closeAdminPanel', function(_, cb)
    panelOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Daten aktualisieren
RegisterNUICallback('adminRefresh', function(_, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:AdminRefresh')
    cb('ok')
end)

-- Einsatz erstellen
RegisterNUICallback('adminCreateCallout', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:AdminCreateCallout', {
        type  = data.type,
        label = data.label,
        coords = vector3(data.x, data.y, data.z),
    })
    cb('ok')
end)

-- Einsatz abbrechen
RegisterNUICallback('adminCancelCallout', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:AdminCancelCallout', data.id)
    cb('ok')
end)

-- Dienststatus setzen
RegisterNUICallback('adminSetDuty', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:AdminSetDuty', data.playerId, data.duty)
    cb('ok')
end)

-- Rang setzen
RegisterNUICallback('adminSetGrade', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:AdminSetGrade', data.playerId, data.grade)
    cb('ok')
end)

-- Spieler aus Dienst entfernen
RegisterNUICallback('adminKickFromDuty', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:AdminKickFromDuty', data.playerId)
    cb('ok')
end)

-- Fahrzeug löschen
RegisterNUICallback('adminDeleteVehicle', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:AdminDeleteVehicle', data.plate)
    cb('ok')
end)

-- Alle Fahrzeuge löschen
RegisterNUICallback('adminDeleteAllVehicles', function(_, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:AdminDeleteAllVehicles')
    cb('ok')
end)

-- Meine Position holen und ans UI schicken
RegisterNUICallback('adminGetCoords', function(_, cb)
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    SendNUIMessage({
        type = 'setCoords',
        x    = coords.x,
        y    = coords.y,
        z    = coords.z,
        w    = heading,
    })
    cb('ok')
end)

-- ──────────────────────────────────────────
-- LIVE DATA UPDATE (vom Server)
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:AdminUpdateData', function(data)
    if panelOpen then
        SendNUIMessage({ type = 'updateData', data = data })
    end
end)

-- ──────────────────────────────────────────
-- COMMAND: /fdadmin
-- ──────────────────────────────────────────

RegisterCommand('fdadmin', function()
    TriggerServerEvent('qbx_firedepartmentjob:server:RequestAdminPanel')
end, false)

TriggerEvent('chat:addSuggestion', '/fdadmin', 'Feuerwehr Admin-Panel öffnen')

-- ──────────────────────────────────────────
-- CONFIG CALLBACKS
-- ──────────────────────────────────────────

RegisterNUICallback('adminGetConfig', function(_, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:GetConfig')
    cb('ok')
end)

RegisterNUICallback('adminSetPaycheck', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:SetPaycheck', data.grade, data.amount)
    cb('ok')
end)

RegisterNUICallback('adminSetCalloutReward', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:SetCalloutReward', data.typeKey, data.reward)
    cb('ok')
end)

RegisterNUICallback('adminSetHoseConfig', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:SetHoseConfig', data.maxDistance, data.waterPressure)
    cb('ok')
end)

RegisterNUICallback('adminSetStationCoords', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:SetStationCoords', data.stationId, data.coords)
    cb('ok')
end)

RegisterNUICallback('adminSetDebug', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:SetDebug', data.state)
    cb('ok')
end)

-- Config vom Server empfangen → ans NUI weiterleiten
RegisterNetEvent('qbx_firedepartmentjob:client:ReceiveConfig', function(data)
    SendNUIMessage({ type = 'receiveConfig', data = data })
end)

-- Wachen-Coords update empfangen
RegisterNetEvent('qbx_firedepartmentjob:client:UpdateStationCoords', function(stationId, coords)
    if Config.Stations[stationId] then
        Config.Stations[stationId].coords = vector4(coords.x, coords.y, coords.z, coords.w)
        DebugLog('admin.lua', 'Wache %d Coords aktualisiert', stationId)
        -- Blips neu setzen damit sie an der richtigen Position sind
        CreateStationBlips()
    end
end)

-- Schlauch-Config update empfangen
RegisterNetEvent('qbx_firedepartmentjob:client:UpdateHoseConfig', function(maxDistance, waterPressure)
    Config.Hose.MaxDistance   = maxDistance
    Config.Hose.WaterPressure = waterPressure
    DebugLog('admin.lua', 'Schlauch-Config aktualisiert: %dm / %.1f', maxDistance, waterPressure)
end)

-- Fahrzeug-Spawn update empfangen
RegisterNetEvent('qbx_firedepartmentjob:client:UpdateVehicleSpawn', function(stationId, spawnIdx, data)
    if Config.VehicleSpawns[stationId] and Config.VehicleSpawns[stationId][spawnIdx] then
        local spawn = Config.VehicleSpawns[stationId][spawnIdx]
        if data.model  then spawn.model  = data.model  end
        if data.label  then spawn.label  = data.label  end
        if data.coords then
            spawn.coords = vector4(data.coords.x, data.coords.y, data.coords.z, data.coords.w)
        end
        DebugLog('admin.lua', 'VehicleSpawn %d/%d aktualisiert', stationId, spawnIdx)
    end
end)

-- ──────────────────────────────────────────
-- ERWEITERTE CONFIG CALLBACKS
-- ──────────────────────────────────────────

RegisterNUICallback('adminGetFullConfig', function(_, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:GetFullConfig')
    cb('ok')
end)

RegisterNUICallback('adminSetVehicleSpawn', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:SetVehicleSpawn',
        data.stationId, data.spawnIdx, data)
    cb('ok')
end)

RegisterNUICallback('adminSetAmbulanceConfig', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:SetAmbulanceConfig', data)
    cb('ok')
end)

RegisterNUICallback('adminSetCalloutConfig', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:SetCalloutConfig', data)
    cb('ok')
end)

RegisterNUICallback('adminSetEquipmentGrade', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:SetEquipmentGrade', data.item, data.grade)
    cb('ok')
end)

RegisterNetEvent('qbx_firedepartmentjob:client:ReceiveFullConfig', function(data)
    SendNUIMessage({ type = 'receiveFullConfig', data = data })
end)

-- ──────────────────────────────────────────
-- WACHEN & LAGER CALLBACKS
-- ──────────────────────────────────────────

-- Neue Wache anlegen
RegisterNUICallback('adminAddStation', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:AdminAddStation', data)
    cb('ok')
end)

-- Wache löschen
RegisterNUICallback('adminDeleteStation', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:AdminDeleteStation', data.stationId)
    cb('ok')
end)

-- Fahrzeug-Spawn hinzufügen
RegisterNUICallback('adminAddVehicleSpawn', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:AdminAddVehicleSpawn', data.stationId, data)
    cb('ok')
end)

-- Fahrzeug-Spawn löschen
RegisterNUICallback('adminDeleteVehicleSpawn', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:AdminDeleteVehicleSpawn', data.stationId, data.spawnIdx)
    cb('ok')
end)

-- Neues Lager anlegen
RegisterNUICallback('adminAddStorage', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:AdminAddStorage', data)
    cb('ok')
end)

-- Lager löschen
RegisterNUICallback('adminDeleteStorage', function(data, cb)
    TriggerServerEvent('qbx_firedepartmentjob:server:AdminDeleteStorage', data.storageId)
    cb('ok')
end)

-- Lager-Items werden direkt über ox_inventory UI verwaltet (kein NUI-Callback nötig)

-- Vollständige Config für Station/Storage Tab
RegisterNUICallback('adminGetStationStorageConfig', function(_, cb)
    local stations = {}
    for id, s in pairs(Config.Stations) do
        stations[id] = {
            label = s.label,
            x = s.coords.x, y = s.coords.y, z = s.coords.z, w = s.coords.w,
        }
    end
    local spawns = {}
    for stId, spawnList in pairs(Config.VehicleSpawns) do
        spawns[stId] = {}
        for idx, sp in ipairs(spawnList) do
            spawns[stId][idx] = {
                model = sp.model, label = sp.label,
                x = sp.coords.x, y = sp.coords.y, z = sp.coords.z, w = sp.coords.w,
            }
        end
    end
    local storages = {}
    for id, stor in pairs(Config.Storage.Locations) do
        storages[id] = {
            label = stor.label,
            x = stor.coords.x, y = stor.coords.y, z = stor.coords.z, w = stor.coords.w,
            stationId = stor.stationId,
            items = stor.items,
        }
    end
    SendNUIMessage({
        type = 'receiveStationStorageConfig',
        stations = stations,
        spawns   = spawns,
        storages = storages,
    })
    cb('ok')
end)