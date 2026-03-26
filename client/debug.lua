-- ╔══════════════════════════════════════════╗
-- ║          CLIENT / DEBUG.LUA             ║
-- ╚══════════════════════════════════════════╝

local debugEnabled = Config.Debug

-- ──────────────────────────────────────────
-- COMMAND: /fddebug
-- ──────────────────────────────────────────

RegisterCommand('fddebug', function()
    debugEnabled  = not debugEnabled
    Config.Debug  = debugEnabled

    -- ox_target Zonen live togglen
    for _, station in pairs(Config.Stations) do
        exports.ox_target:setDebug(debugEnabled)
    end

    lib.notify({
        title       = '🛠️ FD Debug',
        description = 'Debug-Modus: ' .. (debugEnabled and 'AN' or 'AUS'),
        type        = debugEnabled and 'success' or 'error',
    })

    DebugLog('debug.lua', 'Debug-Modus auf %s gesetzt', tostring(debugEnabled))
end, false)

TriggerEvent('chat:addSuggestion', '/fddebug', 'Feuerwehr Debug-Modus togglen')

-- ──────────────────────────────────────────
-- DEBUG OVERLAY (Text auf Bildschirm)
-- ──────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(debugEnabled and 0 or 500)
        if not debugEnabled then goto continue end

        local ped      = PlayerPedId()
        local coords   = GetEntityCoords(ped)
        local playerData = exports.qbx_core:GetPlayerData()
        local job      = playerData and playerData.job or {}

        -- Hintergrund-Box oben links
        DrawRect(0.01 + 0.12, 0.13 + 0.10, 0.24, 0.20, 0, 0, 0, 160)

        -- Job / Grade Info
        DrawDebugText(0.01, 0.04, '~o~[FD DEBUG]')
        DrawDebugText(0.01, 0.07, string.format('~w~Job: ~y~%s', tostring(job.name or '?')))
        DrawDebugText(0.01, 0.10, string.format('~w~Grade: ~y~%d  ~w~(%s)',
            job.grade and job.grade.level or 0,
            job.grade and job.grade.name or '?'))
        DrawDebugText(0.01, 0.13, string.format('~w~Coords: ~y~%.1f / %.1f / %.1f',
            coords.x, coords.y, coords.z))

        -- Marker Koordinaten der Wachen
        for i, station in pairs(Config.Stations) do
            local dist = #(coords - vector3(station.coords.x, station.coords.y, station.coords.z))
            if dist < 60.0 then
                -- Koordinaten über dem Marker in der Welt
                DrawText3D(
                    station.coords.x,
                    station.coords.y,
                    station.coords.z + 2.0,
                    string.format('~o~Wache %d~n~~w~%.1f / %.1f / %.1f~n~Dist: ~y~%.1fm',
                        i, station.coords.x, station.coords.y, station.coords.z, dist)
                )
            end
        end

        ::continue::
    end
end)

-- ──────────────────────────────────────────
-- HILFSFUNKTION: 3D Text
-- ──────────────────────────────────────────

function DrawText3D(x, y, z, text)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    local camCoords = GetGameplayCamCoords()
    local dist      = #(camCoords - vector3(x, y, z))
    local scale     = (1 / dist) * 2.5
    local fov       = (1 / GetGameplayCamFov()) * 100

    SetTextScale(0.0, math.min(scale * fov, 0.45))
    SetTextFont(0)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(sx, sy)
end

-- ──────────────────────────────────────────
-- HILFSFUNKTION: 2D Text (Screen-Overlay)
-- ──────────────────────────────────────────

function DrawDebugText(x, y, text)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextScale(0.0, 0.30)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

-- ──────────────────────────────────────────
-- DEBUG: Server-seitige Config-Änderung empfangen
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:DebugToggle', function(state)
    debugEnabled = state
    Config.Debug = state
    exports.ox_target:setDebug(state)
    DebugLog('debug.lua', 'Debug remote gesetzt: %s', tostring(state))
end)