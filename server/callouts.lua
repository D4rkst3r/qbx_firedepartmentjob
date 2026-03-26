-- ╔══════════════════════════════════════════╗
-- ║        SERVER / CALLOUTS.LUA            ║
-- ╚══════════════════════════════════════════╝

local function GetPlayer(src) return exports.qbx_core:GetPlayer(src) end
local function GetPlayers()   return exports.qbx_core:GetQBPlayers()   end

local activeCallouts   = {}
local calloutIdCounter = 0

-- ──────────────────────────────────────────
-- EINSATZ ERSTELLEN
-- ──────────────────────────────────────────

local function CreateCallout(typeKey, locationData)
    if #activeCallouts >= Config.Callouts.MaxActiveCallouts then return end

    calloutIdCounter += 1
    local calloutType = Config.Callouts.Types[typeKey]
    if not calloutType then return end

    local callout = {
        id             = calloutIdCounter,
        type           = typeKey,
        type_label     = calloutType.label,
        label          = calloutType.label,
        location_label = locationData.label,
        coords         = locationData.coords,
        priority       = calloutType.priority,
        reward         = calloutType.reward,
        assignedTo     = {},
        completed      = false,
        createdAt      = os.time(),
    }

    activeCallouts[callout.id] = callout

    MySQL.insert('INSERT INTO fd_callouts (callout_id, type, label, coords_x, coords_y, coords_z, priority, reward, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())', {
        callout.id, callout.type, callout.label,
        callout.coords.x, callout.coords.y, callout.coords.z,
        callout.priority, callout.reward
    })

    local players = GetPlayers()
    for _, player in pairs(players) do
        if IsFirefighter(player.PlayerData.job) then
            TriggerClientEvent('qbx_firedepartmentjob:client:NewCallout', player.PlayerData.source, callout)
        end
    end

    print(string.format('[FD] Neuer Einsatz #%d: %s bei %s', callout.id, callout.label, callout.location_label))
    return callout
end

-- ──────────────────────────────────────────
-- ZUFÄLLIGE EINSÄTZE
-- ──────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(math.random(3, 8) * 60 * 1000)
        if #activeCallouts < Config.Callouts.MaxActiveCallouts then
            local loc = Config.Callouts.Locations[math.random(#Config.Callouts.Locations)]
            CreateCallout(loc.type, loc)
        end
    end
end)

-- ──────────────────────────────────────────
-- EINSATZ ANNEHMEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:AcceptCallout', function(calloutId)
    local src    = source
    local Player = GetPlayer(src)
    if not Player then return end
    if not IsFirefighter(Player.PlayerData.job) then return end

    local callout = activeCallouts[calloutId]
    if not callout or callout.completed then return end

    callout.assignedTo[#callout.assignedTo + 1] = src
end)

-- ──────────────────────────────────────────
-- EINSATZ ABSCHLIESSEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:CompleteCallout', function(calloutId)
    local src    = source
    local Player = GetPlayer(src)
    if not Player then return end

    local callout = activeCallouts[calloutId]
    if not callout or callout.completed then return end

    callout.completed = true

    for _, playerId in ipairs(callout.assignedTo) do
        local assignedPlayer = GetPlayer(playerId)
        if assignedPlayer then
            assignedPlayer.Functions.AddMoney('bank', callout.reward, 'callout-reward')
            TriggerClientEvent('qbx_firedepartmentjob:client:CalloutCompleted', playerId, calloutId, callout.reward)
        end
    end

    MySQL.update('UPDATE fd_callouts SET completed = 1, completed_at = NOW() WHERE callout_id = ?', { calloutId })
    activeCallouts[calloutId] = nil

    local players = GetPlayers()
    for _, player in pairs(players) do
        if IsFirefighter(player.PlayerData.job) then
            TriggerClientEvent('qbx_firedepartmentjob:client:RemoveCallout', player.PlayerData.source, calloutId)
        end
    end
end)

-- ──────────────────────────────────────────
-- MANUELLER EINSATZ
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:CreateManualCallout', function(typeKey, coords, label)
    local src    = source
    local Player = GetPlayer(src)
    if not Player then return end
    if not HasRequiredGrade(Player.PlayerData.job, 4) then return end

    CreateCallout(typeKey, { coords = coords, label = label or 'Manueller Einsatz' })
end)

-- ──────────────────────────────────────────
-- EXPORTS
-- ──────────────────────────────────────────

exports('CreateCallout', CreateCallout)
exports('GetActiveCallouts', function() return activeCallouts end)