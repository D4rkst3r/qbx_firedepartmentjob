-- ╔══════════════════════════════════════════╗
-- ║        CLIENT / AMBULANCE.LUA           ║
-- ╚══════════════════════════════════════════╝

local function GetPlayerData() return exports.qbx_core:GetPlayerData() end

local reviving = false

-- ──────────────────────────────────────────
-- BEWUSSTLOSE SCANNEN & EMS INFORMIEREN
-- ──────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(3000)
        local job = GetPlayerData().job
        if not IsFirefighter(job) then goto continue end
        if not HasRequiredGrade(job, Config.Ambulance.ReviveGrade) then goto continue end

        local coords = GetEntityCoords(PlayerPedId())

        for _, playerId in ipairs(GetActivePlayers()) do
            if playerId ~= PlayerId() then
                local targetPed = GetPlayerPed(playerId)
                local dist = #(coords - GetEntityCoords(targetPed))
                if dist < Config.Ambulance.ReviveDistance + 5.0 then
                    if IsEntityDead(targetPed) or IsPedDeadOrDying(targetPed, true) then
                        if Config.Ambulance.NotifyEMS then
                            TriggerServerEvent('qbx_firedepartmentjob:server:NotifyEMS',
                                GetPlayerServerId(playerId), coords)
                        end
                    end
                end
            end
        end

        ::continue::
    end
end)

-- ──────────────────────────────────────────
-- SPIELER REANIMIEREN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:RevivePlayer', function(targetServerId)
    if reviving then return end

    local job = GetPlayerData().job
    if not HasRequiredGrade(job, Config.Ambulance.ReviveGrade) then
        lib.notify({ title = 'Reanimation', description = 'Nicht genug Rang!', type = 'error' })
        return
    end

    if exports.ox_inventory:Search('count', Config.Ambulance.ReviveItem) < 1 then
        lib.notify({ title = 'Reanimation', description = 'Kein Defibrillator vorhanden!', type = 'error' })
        return
    end

    reviving = true

    if lib.progressBar({
        duration     = Config.Ambulance.ReviveTime,
        label        = 'Reanimation läuft…',
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
        anim         = { dict = 'mini@cpr@char_a@cpr_str', clip = 'cpr_pumpchest', flag = 1 },
    }) then
        TriggerServerEvent('qbx_firedepartmentjob:server:RevivePlayer', targetServerId)
        lib.notify({ title = '💚 Reanimation', description = 'Spieler erfolgreich reanimiert!', type = 'success' })
    else
        lib.notify({ title = 'Reanimation', description = 'Reanimation abgebrochen.', type = 'error' })
    end

    reviving = false
end)

-- ──────────────────────────────────────────
-- ERSTVERSORGUNG
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:TreatPlayer', function(targetServerId)
    if reviving then return end

    if not IsFirefighter(GetPlayerData().job) then return end

    if exports.ox_inventory:Search('count', 'firstaidkit') < 1 then
        lib.notify({ title = 'Erstversorgung', description = 'Kein Verbandskasten vorhanden!', type = 'error' })
        return
    end

    reviving = true

    if lib.progressBar({
        duration     = 5000,
        label        = 'Erstversorgung läuft…',
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
        anim         = { dict = 'anim@sports@ballgame@handball@', clip = 'ball_get_down_r', flag = 1 },
    }) then
        TriggerServerEvent('qbx_firedepartmentjob:server:TreatPlayer', targetServerId)
        lib.notify({ title = '🩹 Erstversorgung', description = 'Spieler versorgt!', type = 'success' })
    end

    reviving = false
end)
