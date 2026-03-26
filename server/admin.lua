-- ╔══════════════════════════════════════════╗
-- ║          SERVER / ADMIN.LUA             ║
-- ╚══════════════════════════════════════════╝

local function GetPlayer(src) return exports.qbx_core:GetPlayer(src) end
local function GetPlayers()   return exports.qbx_core:GetQBPlayers()   end

local ADMIN_ACE = 'qbx_firedepartmentjob.admin'

local function IsAdmin(src)
    return IsPlayerAceAllowed(src, ADMIN_ACE)
end

local gradeLabels = {
    [0] = 'Rookie',
    [1] = 'Feuerwehrmann',
    [2] = 'Senior Feuerwehrmann',
    [3] = 'Leutnant',
    [4] = 'Hauptmann',
    [5] = 'Feuerwehrchef',
}

-- ──────────────────────────────────────────
-- HELPERS
-- ──────────────────────────────────────────

local function GetFirefightersData()
    local players = GetPlayers()
    local result  = {}
    for _, player in pairs(players) do
        local job = player.PlayerData.job
        if IsFirefighter(job) then
            local charinfo = player.PlayerData.charinfo
            result[#result + 1] = {
                id         = player.PlayerData.source,
                name       = (charinfo and charinfo.firstname .. ' ' .. charinfo.lastname) or ('Spieler ' .. player.PlayerData.source),
                grade      = job.grade.level,
                gradeLabel = gradeLabels[job.grade.level] or 'Unbekannt',
                onDuty     = player.PlayerData.metadata.duty or false,
            }
        end
    end
    return result
end

local trackedVehicles = {}

local function GetVehiclesData()
    local result = {}
    for plate, v in pairs(trackedVehicles) do
        result[#result + 1] = { plate = plate, model = v.model, owner = v.ownerName }
    end
    return result
end

-- ──────────────────────────────────────────
-- PANEL ÖFFNEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:RequestAdminPanel', function()
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Zugriff verweigert', description = 'Keine Berechtigung für das Admin-Panel.', type = 'error',
        })
        return
    end

    local callouts = {}
    local raw = ActiveCallouts
    for _, c in pairs(raw) do callouts[#callouts + 1] = c end

    TriggerClientEvent('qbx_firedepartmentjob:client:OpenAdminPanel', src, {
        players  = GetFirefightersData(),
        callouts = callouts,
        vehicles = GetVehiclesData(),
    })

    -- Fahrzeuge nochmal nach kurzem Delay senden (sicherstellen dass Panel offen ist)
    SetTimeout(500, function()
        TriggerClientEvent('qbx_firedepartmentjob:client:AdminUpdateData', src, {
            vehicles = GetVehiclesData(),
        })
    end)
end)

-- ──────────────────────────────────────────
-- REFRESH
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:AdminRefresh', function()
    local src = source
    if not IsAdmin(src) then return end

    local callouts = {}
    local raw = ActiveCallouts
    for _, c in pairs(raw) do callouts[#callouts + 1] = c end

    TriggerClientEvent('qbx_firedepartmentjob:client:AdminUpdateData', src, {
        players  = GetFirefightersData(),
        callouts = callouts,
        vehicles = GetVehiclesData(),
    })
end)

-- ──────────────────────────────────────────
-- EINSATZ ERSTELLEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:AdminCreateCallout', function(data)
    local src = source
    if not IsAdmin(src) then return end

    TriggerEvent('qbx_firedepartmentjob:server:CreateManualCallout',
        data.type, data.coords, data.label)

    TriggerClientEvent('ox_lib:notify', src, {
        title = '🚨 Einsatz erstellt', description = data.label or data.type, type = 'success',
    })
end)

-- ──────────────────────────────────────────
-- EINSATZ ABBRECHEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:AdminCancelCallout', function(calloutId)
    local src = source
    if not IsAdmin(src) then return end

    -- Aus ActiveCallouts entfernen
    if ActiveCallouts[calloutId] then
        ActiveCallouts[calloutId] = nil
        MySQL.update('UPDATE fd_callouts SET completed = 1, completed_at = NOW() WHERE callout_id = ?', { calloutId })
    end

    -- Alle Clients informieren
    local players = GetPlayers()
    for _, player in pairs(players) do
        if IsFirefighter(player.PlayerData.job) then
            TriggerClientEvent('qbx_firedepartmentjob:client:RemoveCallout', player.PlayerData.source, calloutId)
        end
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = '🚨 Einsatz abgebrochen', description = 'Einsatz #' .. calloutId .. ' wurde abgebrochen.', type = 'success',
    })
end)

-- ──────────────────────────────────────────
-- DIENSTSTATUS SETZEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:AdminSetDuty', function(targetId, duty)
    local src = source
    if not IsAdmin(src) then return end

    local Target = GetPlayer(targetId)
    if not Target then return end

    Target.Functions.SetMetaData('duty', duty)
    TriggerClientEvent('qbx_firedepartmentjob:client:SetDuty', targetId, duty)
    TriggerClientEvent('ox_lib:notify', targetId, {
        title = 'Admin',
        description = duty and 'Du wurdest in den Dienst versetzt.' or 'Du wurdest aus dem Dienst genommen.',
        type = duty and 'success' or 'error',
    })
end)

-- ──────────────────────────────────────────
-- RANG SETZEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:AdminSetGrade', function(targetId, grade)
    local src = source
    if not IsAdmin(src) then return end

    local Target = GetPlayer(targetId)
    if not Target then return end
    if not IsFirefighter(Target.PlayerData.job) then return end

    exports.qbx_core:SetJob(targetId, Config.JobName, grade)

    TriggerClientEvent('ox_lib:notify', targetId, {
        title = '🔥 Rang geändert',
        description = 'Dein neuer Rang: ' .. (gradeLabels[grade] or grade),
        type = 'success',
    })
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Rang gesetzt', description = 'Spieler ' .. targetId .. ' → Grad ' .. grade, type = 'success',
    })
end)

-- ──────────────────────────────────────────
-- AUS DIENST ENTFERNEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:AdminKickFromDuty', function(targetId)
    local src = source
    if not IsAdmin(src) then return end

    local Target = GetPlayer(targetId)
    if not Target then return end

    Target.Functions.SetMetaData('duty', false)
    TriggerClientEvent('qbx_firedepartmentjob:client:SetDuty', targetId, false)
    TriggerClientEvent('ox_lib:notify', targetId, {
        title = 'Admin', description = 'Du wurdest vom Admin aus dem Dienst entfernt.', type = 'error',
    })
end)

-- ──────────────────────────────────────────
-- FAHRZEUG LÖSCHEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:AdminDeleteVehicle', function(plate)
    local src = source
    if not IsAdmin(src) then return end

    if trackedVehicles[plate] then
        local netId = trackedVehicles[plate].netId
        local veh = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(veh) then DeleteEntity(veh) end
        -- Alle Clients informieren damit spawnedVehicles aufgeräumt wird
        TriggerClientEvent('qbx_firedepartmentjob:client:VehicleDeleted', -1, plate)
        trackedVehicles[plate] = nil
    else
        -- Fahrzeug nicht im Tracking → trotzdem Clients informieren
        TriggerClientEvent('qbx_firedepartmentjob:client:VehicleDeleted', -1, plate)
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Fahrzeug', description = 'Fahrzeug ' .. plate .. ' gelöscht.', type = 'success',
    })
end)

-- ──────────────────────────────────────────
-- ALLE FAHRZEUGE LÖSCHEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:AdminDeleteAllVehicles', function()
    local src = source
    if not IsAdmin(src) then return end

    for plate, v in pairs(trackedVehicles) do
        local veh = NetworkGetEntityFromNetworkId(v.netId)
        if DoesEntityExist(veh) then DeleteEntity(veh) end
        TriggerClientEvent('qbx_firedepartmentjob:client:VehicleDeleted', -1, plate)
    end
    trackedVehicles = {}

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Fahrzeuge', description = 'Alle Fahrzeuge gelöscht.', type = 'success',
    })
end)

-- ──────────────────────────────────────────
-- FAHRZEUG TRACKING HOOKS
-- ──────────────────────────────────────────

AddEventHandler('qbx_firedepartmentjob:server:RegisterVehicle', function(plate, model, ownerName, netId)
    trackedVehicles[plate] = { model = model, ownerName = ownerName, netId = netId }
    -- Admin-Panels live updaten
    PushVehicleUpdate()
end)

AddEventHandler('qbx_firedepartmentjob:server:UnregisterVehicle', function(plate)
    trackedVehicles[plate] = nil
    -- Admin-Panels live updaten
    PushVehicleUpdate()
end)

-- Live-Update an alle offenen Admin-Panels schicken
function PushVehicleUpdate()
    local players = GetPlayers()
    for _, player in pairs(players) do
        if IsPlayerAceAllowed(player.PlayerData.source, ADMIN_ACE) then
            TriggerClientEvent('qbx_firedepartmentjob:client:AdminUpdateData', player.PlayerData.source, {
                vehicles = GetVehiclesData(),
            })
        end
    end
end

--[[
    server.cfg:
    add_ace group.admin qbx_firedepartmentjob.admin allow
]]