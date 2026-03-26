-- ╔══════════════════════════════════════════╗
-- ║         SERVER / VEHICLES.LUA           ║
-- ╚══════════════════════════════════════════╝

-- Fahrzeug-Tracking (ServerId → gespawnte Fahrzeuge)
local playerVehicles = {}

AddEventHandler('playerDropped', function()
    local src = source
    if playerVehicles[src] then
        for _, veh in ipairs(playerVehicles[src]) do
            if DoesEntityExist(veh) then
                DeleteEntity(veh)
            end
        end
        playerVehicles[src] = nil
    end
end)

-- Fahrzeug zum Tracking hinzufügen (wird von main.lua aufgerufen)
RegisterNetEvent('qbx_firedepartmentjob:server:TrackVehicle', function(veh)
    local src = source
    if not playerVehicles[src] then
        playerVehicles[src] = {}
    end
    playerVehicles[src][#playerVehicles[src] + 1] = veh
end)
