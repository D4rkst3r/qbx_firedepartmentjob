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
    local coords = GetEntityCoords(PlayerPedId())
    SendNUIMessage({
        type = 'setCoords',
        x    = coords.x,
        y    = coords.y,
        z    = coords.z,
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
    end
end)

-- Schlauch-Config update empfangen
RegisterNetEvent('qbx_firedepartmentjob:client:UpdateHoseConfig', function(maxDistance, waterPressure)
    Config.Hose.MaxDistance   = maxDistance
    Config.Hose.WaterPressure = waterPressure
    DebugLog('admin.lua', 'Schlauch-Config aktualisiert: %dm / %.1f', maxDistance, waterPressure)
end)