-- ╔══════════════════════════════════════════╗
-- ║        SERVER / CONFIG_EDIT.LUA         ║
-- ║   Ingame Config-Änderungen (Admin)      ║
-- ╚══════════════════════════════════════════╝

local function GetPlayer(src) return exports.qbx_core:GetPlayer(src) end
local ADMIN_ACE = 'qbx_firedepartmentjob.admin'
local function IsAdmin(src) return IsPlayerAceAllowed(src, ADMIN_ACE) end

-- ──────────────────────────────────────────
-- DB PERSISTENZ
-- ──────────────────────────────────────────

local function SaveConfig(key, value)
    local json = json.encode(value)
    MySQL.update('INSERT INTO fd_config (`key`, `value`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `value` = ?, updated_at = NOW()',
        { key, json, json })
end

local function LoadAllConfigs()
    local rows = MySQL.query.await('SELECT `key`, `value` FROM fd_config')
    if not rows then return end

    for _, row in ipairs(rows) do
        local ok, val = pcall(json.decode, row.value)
        if not ok then goto continue end

        if row.key == 'paycheck' then
            for gradeStr, amount in pairs(val) do
                local grade = tonumber(gradeStr)
                if grade then Config.Paycheck.Amounts[grade] = amount end
            end

        elseif row.key == 'calloutRewards' then
            for typeKey, reward in pairs(val) do
                if Config.Callouts.Types[typeKey] then
                    Config.Callouts.Types[typeKey].reward = reward
                end
            end

        elseif row.key == 'hose' then
            if val.maxDistance   then Config.Hose.MaxDistance   = val.maxDistance   end
            if val.waterPressure then Config.Hose.WaterPressure = val.waterPressure end

        elseif row.key == 'ambulance' then
            if val.reviveTime     then Config.Ambulance.ReviveTime     = val.reviveTime     end
            if val.reviveGrade    then Config.Ambulance.ReviveGrade    = val.reviveGrade    end
            if val.reviveDistance then Config.Ambulance.ReviveDistance = val.reviveDistance end
            if val.notifyEMS ~= nil then Config.Ambulance.NotifyEMS   = val.notifyEMS      end

        elseif row.key == 'calloutConfig' then
            if val.maxActive  then Config.Callouts.MaxActiveCallouts = val.maxActive  end
            if val.alertSound ~= nil then Config.Callouts.AlertSound = val.alertSound end

        elseif row.key:sub(1, 8) == 'station_' then
            local stationId = tonumber(row.key:sub(9))
            if stationId and Config.Stations[stationId] then
                Config.Stations[stationId].coords = vector4(
                    val.x or 0, val.y or 0, val.z or 0, val.w or 0)
            end

        elseif row.key:sub(1, 14) == 'vehiclespawn__' then
            -- Format: vehiclespawn__stationId_spawnIdx
            local parts = row.key:sub(15)
            local stId, spIdx = parts:match('(%d+)_(%d+)')
            stId  = tonumber(stId)
            spIdx = tonumber(spIdx)
            if stId and spIdx and Config.VehicleSpawns[stId] and Config.VehicleSpawns[stId][spIdx] then
                local spawn = Config.VehicleSpawns[stId][spIdx]
                if val.model  then spawn.model  = val.model  end
                if val.label  then spawn.label  = val.label  end
                if val.coords then
                    spawn.coords = vector4(val.coords.x, val.coords.y, val.coords.z, val.coords.w)
                end
            end

        elseif row.key == 'equipment' then
            for _, eq in ipairs(val) do
                for _, equip in ipairs(Config.Equipment) do
                    if equip.item == eq.item then
                        equip.grade = eq.grade
                        break
                    end
                end
            end
        end

        ::continue::
    end

    print('^2[FD] Config aus Datenbank geladen (' .. #rows .. ' Einträge)^7')
end

-- Beim Start laden
CreateThread(function()
    Wait(500) -- kurz warten bis MySQL bereit ist
    LoadAllConfigs()
end)

-- ──────────────────────────────────────────
-- AKTUELLE CONFIG SENDEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:GetConfig', function()
    local src = source
    if not IsAdmin(src) then return end

    TriggerClientEvent('qbx_firedepartmentjob:client:ReceiveConfig', src, {
        paycheck = Config.Paycheck.Amounts,
        calloutRewards = (function()
            local t = {}
            for k, v in pairs(Config.Callouts.Types) do
                t[k] = v.reward
            end
            return t
        end)(),
        stations = (function()
            local t = {}
            for i, s in pairs(Config.Stations) do
                t[i] = { label = s.label, x = s.coords.x, y = s.coords.y, z = s.coords.z, w = s.coords.w }
            end
            return t
        end)(),
        hose = {
            maxDistance   = Config.Hose.MaxDistance,
            waterPressure = Config.Hose.WaterPressure,
        },
        debug = Config.Debug,
    })
end)

-- ──────────────────────────────────────────
-- GEHALT ÄNDERN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:SetPaycheck', function(grade, amount)
    local src = source
    if not IsAdmin(src) then return end

    grade  = tonumber(grade)
    amount = tonumber(amount)
    if not grade or not amount then return end
    if grade < 0 or grade > 5 then return end
    if amount < 0 or amount > 99999 then return end

    Config.Paycheck.Amounts[grade] = amount
    SaveConfig('paycheck', Config.Paycheck.Amounts)
    DebugLog('config_edit', 'Gehalt Grad %d → $%d (gesetzt von %d)', grade, amount, src)

    TriggerClientEvent('ox_lib:notify', src, {
        title = '⚙️ Config', description = string.format('Gehalt Grad %d → $%d', grade, amount), type = 'success',
    })
end)

-- ──────────────────────────────────────────
-- EINSATZ-BELOHNUNG ÄNDERN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:SetCalloutReward', function(typeKey, reward)
    local src = source
    if not IsAdmin(src) then return end

    reward = tonumber(reward)
    if not reward or not Config.Callouts.Types[typeKey] then return end
    if reward < 0 or reward > 99999 then return end

    Config.Callouts.Types[typeKey].reward = reward
    -- Alle Rewards als Objekt speichern
    local rewards = {}
    for k, v in pairs(Config.Callouts.Types) do rewards[k] = v.reward end
    SaveConfig('calloutRewards', rewards)
    DebugLog('config_edit', 'Einsatz-Belohnung %s → $%d (gesetzt von %d)', typeKey, reward, src)

    TriggerClientEvent('ox_lib:notify', src, {
        title = '⚙️ Config', description = string.format('%s Belohnung → $%d', typeKey, reward), type = 'success',
    })
end)

-- ──────────────────────────────────────────
-- WACHEN-KOORDINATEN ÄNDERN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:SetStationCoords', function(stationId, coords)
    local src = source
    if not IsAdmin(src) then return end

    stationId = tonumber(stationId)
    if not stationId or not Config.Stations[stationId] then return end

    Config.Stations[stationId].coords = vector4(
        tonumber(coords.x) or 0,
        tonumber(coords.y) or 0,
        tonumber(coords.z) or 0,
        tonumber(coords.w) or 0
    )

    SaveConfig('station_' .. stationId, {
        x = Config.Stations[stationId].coords.x,
        y = Config.Stations[stationId].coords.y,
        z = Config.Stations[stationId].coords.z,
        w = Config.Stations[stationId].coords.w,
    })
    DebugLog('config_edit', 'Wache %d Coords geändert (gesetzt von %d)', stationId, src)

    -- Alle Clients über neue Coords informieren
    TriggerClientEvent('qbx_firedepartmentjob:client:UpdateStationCoords', -1, stationId, coords)
    TriggerClientEvent('ox_lib:notify', src, {
        title = '⚙️ Config', description = 'Wache ' .. stationId .. ' Koordinaten aktualisiert', type = 'success',
    })
end)

-- ──────────────────────────────────────────
-- SCHLAUCH-EINSTELLUNGEN ÄNDERN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:SetHoseConfig', function(maxDistance, waterPressure)
    local src = source
    if not IsAdmin(src) then return end

    maxDistance   = tonumber(maxDistance)
    waterPressure = tonumber(waterPressure)
    if not maxDistance or not waterPressure then return end
    if maxDistance < 1 or maxDistance > 50 then return end
    if waterPressure < 1 or waterPressure > 20 then return end

    Config.Hose.MaxDistance   = maxDistance
    Config.Hose.WaterPressure = waterPressure
    SaveConfig('hose', { maxDistance = maxDistance, waterPressure = waterPressure })

    -- Alle Clients updaten
    TriggerClientEvent('qbx_firedepartmentjob:client:UpdateHoseConfig', -1, maxDistance, waterPressure)
    DebugLog('config_edit', 'Schlauch: Reichweite=%d, Druck=%.1f (gesetzt von %d)', maxDistance, waterPressure, src)

    TriggerClientEvent('ox_lib:notify', src, {
        title = '⚙️ Config',
        description = string.format('Schlauch: Reichweite %dm, Druck %.1f', maxDistance, waterPressure),
        type = 'success',
    })
end)

-- ──────────────────────────────────────────
-- DEBUG TOGGLE (server → alle clients)
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:SetDebug', function(state)
    local src = source
    if not IsAdmin(src) then return end

    Config.Debug = state
    TriggerClientEvent('qbx_firedepartmentjob:client:DebugToggle', -1, state)
    print(string.format('^3[FD] Debug-Modus %s (gesetzt von %d)^7', state and 'AN' or 'AUS', src))
end)

-- ──────────────────────────────────────────
-- FAHRZEUG-SPAWNS ÄNDERN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:SetVehicleSpawn', function(stationId, spawnIdx, data)
    local src = source
    if not IsAdmin(src) then return end

    stationId = tonumber(stationId)
    spawnIdx  = tonumber(spawnIdx)
    if not stationId or not spawnIdx then return end
    if not Config.VehicleSpawns[stationId] then return end
    if not Config.VehicleSpawns[stationId][spawnIdx] then return end

    local spawn = Config.VehicleSpawns[stationId][spawnIdx]
    if data.model  then spawn.model  = data.model end
    if data.label  then spawn.label  = data.label end
    if data.coords then
        spawn.coords = vector4(
            tonumber(data.coords.x) or spawn.coords.x,
            tonumber(data.coords.y) or spawn.coords.y,
            tonumber(data.coords.z) or spawn.coords.z,
            tonumber(data.coords.w) or spawn.coords.w
        )
    end

    -- In DB persistieren
    local spawn = Config.VehicleSpawns[stationId][spawnIdx]
    SaveConfig('vehiclespawn__' .. stationId .. '_' .. spawnIdx, {
        model  = spawn.model,
        label  = spawn.label,
        coords = { x = spawn.coords.x, y = spawn.coords.y, z = spawn.coords.z, w = spawn.coords.w },
    })

    -- Alle Clients über Änderung informieren
    TriggerClientEvent('qbx_firedepartmentjob:client:UpdateVehicleSpawn', -1, stationId, spawnIdx, data)

    TriggerClientEvent('ox_lib:notify', src, {
        title = '⚙️ Config',
        description = string.format('Fahrzeug-Spawn %d/%d aktualisiert', stationId, spawnIdx),
        type = 'success',
    })
    DebugLog('config_edit', 'VehicleSpawn %d/%d geändert von %d', stationId, spawnIdx, src)
end)

-- ──────────────────────────────────────────
-- AMBULANZ-EINSTELLUNGEN ÄNDERN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:SetAmbulanceConfig', function(data)
    local src = source
    if not IsAdmin(src) then return end

    if data.reviveTime  then
        local t = tonumber(data.reviveTime)
        if t and t >= 1000 and t <= 30000 then Config.Ambulance.ReviveTime = t end
    end
    if data.reviveGrade then
        local g = tonumber(data.reviveGrade)
        if g and g >= 0 and g <= 5 then Config.Ambulance.ReviveGrade = g end
    end
    if data.reviveDistance then
        local d = tonumber(data.reviveDistance)
        if d and d >= 1.0 and d <= 10.0 then Config.Ambulance.ReviveDistance = d end
    end
    if data.notifyEMS ~= nil then
        Config.Ambulance.NotifyEMS = data.notifyEMS
    end

    SaveConfig('ambulance', {
        reviveTime     = Config.Ambulance.ReviveTime,
        reviveGrade    = Config.Ambulance.ReviveGrade,
        reviveDistance = Config.Ambulance.ReviveDistance,
        notifyEMS      = Config.Ambulance.NotifyEMS,
    })
    TriggerClientEvent('ox_lib:notify', src, {
        title = '⚙️ Config', description = 'Ambulanz-Einstellungen aktualisiert', type = 'success',
    })
    DebugLog('config_edit', 'Ambulanz-Config geändert von %d', src)
end)

-- ──────────────────────────────────────────
-- EINSATZ-EINSTELLUNGEN ÄNDERN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:SetCalloutConfig', function(data)
    local src = source
    if not IsAdmin(src) then return end

    if data.maxActive then
        local m = tonumber(data.maxActive)
        if m and m >= 1 and m <= 20 then Config.Callouts.MaxActiveCallouts = m end
    end
    if data.alertSound ~= nil then
        Config.Callouts.AlertSound = data.alertSound
    end

    SaveConfig('calloutConfig', {
        maxActive  = Config.Callouts.MaxActiveCallouts,
        alertSound = Config.Callouts.AlertSound,
    })
    TriggerClientEvent('ox_lib:notify', src, {
        title = '⚙️ Config', description = 'Einsatz-Einstellungen aktualisiert', type = 'success',
    })
    DebugLog('config_edit', 'Callout-Config geändert von %d', src)
end)

-- ──────────────────────────────────────────
-- AUSRÜSTUNGS-GRADE ÄNDERN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:SetEquipmentGrade', function(item, grade)
    local src = source
    if not IsAdmin(src) then return end

    grade = tonumber(grade)
    if not grade or grade < 0 or grade > 5 then return end

    for _, equip in ipairs(Config.Equipment) do
        if equip.item == item then
            equip.grade = grade
            -- Alle Equipment-Grades speichern
            local eqData = {}
            for _, e in ipairs(Config.Equipment) do
                eqData[#eqData + 1] = { item = e.item, grade = e.grade }
            end
            SaveConfig('equipment', eqData)
            TriggerClientEvent('ox_lib:notify', src, {
                title = '⚙️ Config',
                description = string.format('%s → Mindestgrad %d', item, grade),
                type = 'success',
            })
            DebugLog('config_edit', 'Equipment %s grade → %d (von %d)', item, grade, src)
            return
        end
    end
end)

-- ──────────────────────────────────────────
-- ERWEITERTE CONFIG SENDEN (überschreibt GetConfig)
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:GetFullConfig', function()
    local src = source
    if not IsAdmin(src) then return end

    -- Fahrzeug-Spawns serialisieren
    local vehicleSpawns = {}
    for stationId, spawns in pairs(Config.VehicleSpawns) do
        vehicleSpawns[stationId] = {}
        for idx, spawn in ipairs(spawns) do
            vehicleSpawns[stationId][idx] = {
                model  = spawn.model,
                label  = spawn.label,
                x = spawn.coords.x, y = spawn.coords.y,
                z = spawn.coords.z, w = spawn.coords.w,
            }
        end
    end

    -- Equipment serialisieren
    local equipment = {}
    for _, equip in ipairs(Config.Equipment) do
        equipment[#equipment + 1] = {
            item  = equip.item,
            label = equip.label,
            grade = equip.grade,
        }
    end

    TriggerClientEvent('qbx_firedepartmentjob:client:ReceiveFullConfig', src, {
        vehicleSpawns = vehicleSpawns,
        ambulance = {
            reviveTime     = Config.Ambulance.ReviveTime,
            reviveGrade    = Config.Ambulance.ReviveGrade,
            reviveDistance = Config.Ambulance.ReviveDistance,
            notifyEMS      = Config.Ambulance.NotifyEMS,
        },
        callouts = {
            maxActive  = Config.Callouts.MaxActiveCallouts,
            alertSound = Config.Callouts.AlertSound,
        },
        equipment = equipment,
    })
end)