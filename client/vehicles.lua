-- ╔══════════════════════════════════════════╗
-- ║         CLIENT / VEHICLES.LUA           ║
-- ╚══════════════════════════════════════════╝

local spawnedVehicles = {}   -- Gespawnte Fahrzeuge { netId = plate }

-- ──────────────────────────────────────────
-- FAHRZEUG SPAWNEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:SpawnVehicle', function(spawn)
    local playerData = exports.qbx_core:GetPlayerData()
    if not IsFirefighter(playerData.job) then return end

    -- Prüfen ob schon ein Fahrzeug gespawnt ist
    if #spawnedVehicles >= 2 then
        lib.notify({ title = 'Fahrzeug', description = 'Maximal 2 Fahrzeuge erlaubt.', type = 'error' })
        return
    end

    -- Ladebalken
    if lib.progressBar({
        duration    = 3000,
        label       = 'Fahrzeug wird vorbereitet…',
        useWhileDead = false,
        canCancel   = false,
        disable     = { move = true, car = true, combat = true },
    }) then
        TriggerServerEvent('qbx_firedepartmentjob:server:SpawnVehicle', {
            model  = spawn.model,
            coords = spawn.coords,
            plate  = GeneratePlate(),
        })
    end
end)

RegisterNetEvent('qbx_firedepartmentjob:client:VehicleSpawned', function(netId, plate)
    local timeout = 0
    repeat
        Wait(100)
        timeout += 100
    until NetworkDoesEntityExistWithNetworkId(netId) or timeout > 5000

    if timeout >= 5000 then
        lib.notify({ title = 'Fehler', description = 'Fahrzeug konnte nicht gespawnt werden.', type = 'error' })
        return
    end

    local veh = NetToVeh(netId)
    SetVehicleNumberPlateText(veh, plate)
    spawnedVehicles[#spawnedVehicles + 1] = { netId = netId, plate = plate }

    lib.notify({ title = '🚒 Fahrzeug bereit', description = 'Kennzeichen: ' .. plate, type = 'success' })
end)

-- ──────────────────────────────────────────
-- FAHRZEUG ZURÜCKGEBEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:ReturnVehicle', function()
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for i, v in ipairs(spawnedVehicles) do
        if NetworkDoesEntityExistWithNetworkId(v.netId) then
            local veh = NetToVeh(v.netId)
            local dist = #(coords - GetEntityCoords(veh))
            if dist < 10.0 then
                TriggerServerEvent('qbx_firedepartmentjob:server:ReturnVehicle', v.netId)
                table.remove(spawnedVehicles, i)
                lib.notify({ title = 'Fahrzeug', description = 'Fahrzeug erfolgreich zurückgegeben.', type = 'success' })
                return
            end
        end
    end

    lib.notify({ title = 'Fahrzeug', description = 'Kein Fahrzeug in der Nähe.', type = 'error' })
end)

-- ──────────────────────────────────────────
-- HILFSFUNKTIONEN
-- ──────────────────────────────────────────

function GeneratePlate()
    local chars   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local numbers = '0123456789'
    local plate   = 'FW'
    for _ = 1, 2 do
        plate = plate .. chars:sub(math.random(1, #chars), math.random(1, #chars))
    end
    for _ = 1, 4 do
        plate = plate .. numbers:sub(math.random(1, #numbers), math.random(1, #numbers))
    end
    return plate
end

-- ──────────────────────────────────────────
-- FAHRZEUG MENÜ
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:OpenVehicleMenu', function()
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local options = {}

    -- Fahrzeuge in der Nähe finden
    for stationId, spawns in pairs(Config.VehicleSpawns) do
        for _, spawn in ipairs(spawns) do
            local dist = #(coords - vector3(spawn.coords.x, spawn.coords.y, spawn.coords.z))
            if dist < 30.0 then
                options[#options + 1] = {
                    title       = '🚒 ' .. spawn.label,
                    description = 'Wache ' .. stationId,
                    icon        = 'truck',
                    onSelect    = function()
                        TriggerEvent('qbx_firedepartmentjob:client:SpawnVehicle', spawn)
                    end,
                }
            end
        end
    end

    if #options == 0 then
        lib.notify({ title = 'Fahrzeuge', description = 'Keine Wache in der Nähe.', type = 'error' })
        return
    end

    -- Fahrzeug zurückgeben Option
    options[#options + 1] = {
        title    = '↩️ Fahrzeug zurückgeben',
        icon     = 'rotate-left',
        onSelect = function()
            TriggerNetEvent('qbx_firedepartmentjob:client:ReturnVehicle')
        end,
    }

    lib.registerContext({
        id      = 'fd_vehicle_menu',
        title   = '🚒 Fahrzeugverwaltung',
        menu    = 'fd_main_menu',
        options = options,
    })
    lib.showContext('fd_vehicle_menu')
end)