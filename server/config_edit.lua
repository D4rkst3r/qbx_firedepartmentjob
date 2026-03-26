-- ╔══════════════════════════════════════════╗
-- ║        SERVER / CONFIG_EDIT.LUA         ║
-- ║   Ingame Config-Änderungen (Admin)      ║
-- ╚══════════════════════════════════════════╝

local function GetPlayer(src) return exports.qbx_core:GetPlayer(src) end
local ADMIN_ACE = 'qbx_firedepartmentjob.admin'
local function IsAdmin(src) return IsPlayerAceAllowed(src, ADMIN_ACE) end

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