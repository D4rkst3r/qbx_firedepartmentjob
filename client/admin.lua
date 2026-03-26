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
