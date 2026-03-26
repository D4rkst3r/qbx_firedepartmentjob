-- ╔══════════════════════════════════════════╗
-- ║         CLIENT / CALLOUTS.LUA           ║
-- ╚══════════════════════════════════════════╝

local activeCallouts  = {}     -- { [id] = { blip, data } }
local acceptedCallout = nil    -- Derzeit angenommener Einsatz

-- ──────────────────────────────────────────
-- NEUER EINSATZ (vom Server)
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:NewCallout', function(callout)
    local playerData = exports.qbx_core:GetPlayerData()
    if not IsFirefighter(playerData.job) then return end

    -- Alert-Sound
    if Config.Callouts.AlertSound then
        PlaySoundFrontend(-1, 'TIMER_STOP', 'HUD_MINI_GAME_SOUNDSET', true)
    end

    -- Blip erstellen
    local blip = AddBlipForCoord(callout.coords.x, callout.coords.y, callout.coords.z)
    SetBlipSprite(blip, Config.Callouts.BlipSprite)
    SetBlipColour(blip, Config.Callouts.BlipColor)
    SetBlipScale(blip, 0.9)
    SetBlipDisplay(blip, 4)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('🔥 ' .. callout.label)
    EndTextCommandSetBlipName(blip)

    activeCallouts[callout.id] = { blip = blip, data = callout }

    -- Benachrichtigung mit Einsatzdetails
    lib.notify({
        title       = '🚨 Neuer Einsatz!',
        description = string.format('[%s] %s\nPriorität: %d',
            callout.type_label, callout.label, callout.priority),
        type        = 'warning',
        duration    = 10000,
        position    = 'top',
    })

    -- Einsatz-Dialog anzeigen
    local accepted = lib.alertDialog({
        header  = '🚨 ' .. callout.label,
        content = string.format('**Typ:** %s\n**Priorität:** %d\n**Ort:** %s\n**Belohnung:** $%d',
            callout.type_label, callout.priority, callout.location_label, callout.reward),
        centered = true,
        cancel   = true,
        labels   = { confirm = 'Einsatz annehmen', cancel = 'Ablehnen' },
    })

    if accepted == 'confirm' then
        TriggerServerEvent('qbx_firedepartmentjob:server:AcceptCallout', callout.id)
        SetNewWaypoint(callout.coords.x, callout.coords.y)
        acceptedCallout = callout

        lib.notify({
            title       = '✅ Einsatz angenommen',
            description = 'Route zu ' .. callout.label .. ' gesetzt.',
            type        = 'success',
        })
    end
end)

-- ──────────────────────────────────────────
-- EINSATZ ABGESCHLOSSEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:CalloutCompleted', function(calloutId, reward)
    if activeCallouts[calloutId] then
        RemoveBlip(activeCallouts[calloutId].blip)
        activeCallouts[calloutId] = nil
    end

    if acceptedCallout and acceptedCallout.id == calloutId then
        acceptedCallout = nil
    end

    lib.notify({
        title       = '✅ Einsatz abgeschlossen',
        description = 'Belohnung: $' .. reward,
        type        = 'success',
        duration    = 7000,
    })
end)

-- ──────────────────────────────────────────
-- EINSATZ ABGEBROCHEN / ENTFERNT
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:RemoveCallout', function(calloutId)
    if activeCallouts[calloutId] then
        RemoveBlip(activeCallouts[calloutId].blip)
        activeCallouts[calloutId] = nil
    end
end)

-- ──────────────────────────────────────────
-- EINSATZ-ÜBERSICHT (Menü)
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:ViewCallouts', function()
    if not next(activeCallouts) then
        lib.notify({ title = '📡 Einsätze', description = 'Keine aktiven Einsätze.', type = 'inform' })
        return
    end

    local options = {}
    for id, callout in pairs(activeCallouts) do
        options[#options + 1] = {
            title       = '🔥 ' .. callout.data.label,
            description = string.format('Typ: %s | Prio: %d | Belohnung: $%d',
                callout.data.type_label, callout.data.priority, callout.data.reward),
            icon        = 'location-dot',
            onSelect    = function()
                SetNewWaypoint(callout.data.coords.x, callout.data.coords.y)
                lib.notify({ title = 'GPS', description = 'Route gesetzt.', type = 'inform' })
            end,
        }
    end

    lib.registerContext({
        id      = 'fd_callout_list',
        title   = '📡 Aktive Einsätze (' .. #options .. ')',
        options = options,
    })
    lib.showContext('fd_callout_list')
end)

-- ──────────────────────────────────────────
-- EINSATZ MANUELL ABSCHLIESSEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:CompleteCurrentCallout', function()
    if not acceptedCallout then
        lib.notify({ title = 'Fehler', description = 'Kein aktiver Einsatz.', type = 'error' })
        return
    end
    TriggerServerEvent('qbx_firedepartmentjob:server:CompleteCallout', acceptedCallout.id)
end)