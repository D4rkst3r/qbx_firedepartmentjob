-- ╔══════════════════════════════════════════╗
-- ║           SERVER / MAIN.LUA             ║
-- ╚══════════════════════════════════════════╝

local function GetPlayer(src) return exports.qbx_core:GetPlayer(src) end
local function GetPlayers()   return exports.qbx_core:GetQBPlayers()   end

-- ──────────────────────────────────────────
-- DIENST TOGGLE
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:ToggleDuty', function()
    local src    = source
    local Player = GetPlayer(src)
    if not Player then return end

    local job = Player.PlayerData.job
    if not IsFirefighter(job) then return end

    local currentDuty = Player.PlayerData.metadata.duty or false
    local newDuty     = not currentDuty

    Player.Functions.SetMetaData('duty', newDuty)
    TriggerClientEvent('qbx_firedepartmentjob:client:SetDuty', src, newDuty)
end)

-- ──────────────────────────────────────────
-- AUSRÜSTUNG GEBEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:GiveEquipment', function(item)
    local src    = source
    local Player = GetPlayer(src)
    if not Player then return end

    local valid = false
    for _, equip in ipairs(Config.Equipment) do
        if equip.item == item then
            if HasRequiredGrade(Player.PlayerData.job, equip.grade) then
                valid = true
            end
            break
        end
    end

    if not valid then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Fehler', description = 'Kein Zugriff auf dieses Item.', type = 'error' })
        return
    end

    exports.ox_inventory:AddItem(src, item, 1)
    TriggerClientEvent('ox_lib:notify', src, {
        title       = '🎽 Ausrüstung',
        description = item .. ' erhalten.',
        type        = 'success',
    })
end)

-- ──────────────────────────────────────────
-- GEHALT
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:Paycheck', function()
    local src    = source
    local Player = GetPlayer(src)
    if not Player then return end

    local job = Player.PlayerData.job
    if not IsFirefighter(job) then return end

    local grade  = job.grade.level
    local amount = Config.Paycheck.Amounts[grade] or Config.Paycheck.Amounts[0]

    Player.Functions.AddMoney('bank', amount, 'firefighter-paycheck')

    TriggerClientEvent('ox_lib:notify', src, {
        title       = '💰 Gehalt',
        description = 'Du hast $' .. amount .. ' erhalten.',
        type        = 'success',
    })
end)

-- ──────────────────────────────────────────
-- FAHRZEUG SPAWNEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:SpawnVehicle', function(data)
    local src    = source
    local Player = GetPlayer(src)
    if not Player then return end
    if not IsFirefighter(Player.PlayerData.job) then return end

    local veh = CreateVehicle(
        GetHashKey(data.model),
        data.coords.x, data.coords.y, data.coords.z, data.coords.w,
        true, false
    )

    local timeout = 0
    while not DoesEntityExist(veh) and timeout < 3000 do
        Wait(100)
        timeout += 100
    end

    if not DoesEntityExist(veh) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Fehler', description = 'Fahrzeug konnte nicht erstellt werden.', type = 'error' })
        return
    end

    SetVehicleNumberPlateText(veh, data.plate)

    local netId = NetworkGetNetworkIdFromEntity(veh)
    local state = Player.PlayerData.charinfo
    local name  = (state and state.firstname and (state.firstname .. ' ' .. state.lastname)) or ('Spieler ' .. src)
    TriggerEvent('qbx_firedepartmentjob:server:RegisterVehicle', data.plate, data.model, name, netId)

    -- Schlüssel geben (qbx_vehiclekeys) - server-seitig mit Entity
    exports.qbx_vehiclekeys:GiveKeys(src, veh, true)

    TriggerClientEvent('qbx_firedepartmentjob:client:VehicleSpawned', src, netId, data.plate)
end)

-- ──────────────────────────────────────────
-- FAHRZEUG ZURÜCKGEBEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:ReturnVehicle', function(netId)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(veh) then return end
    if DoesEntityExist(veh) then
        local plate = GetVehicleNumberPlateText(veh)
        TriggerEvent('qbx_firedepartmentjob:server:UnregisterVehicle', plate)
        DeleteEntity(veh)
    end
end)

-- ──────────────────────────────────────────
-- REANIMATION
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:RevivePlayer', function(targetServerId)
    local src    = source
    local Player = GetPlayer(src)
    if not Player then return end
    if not HasRequiredGrade(Player.PlayerData.job, Config.Ambulance.ReviveGrade) then return end

    exports.ox_inventory:RemoveItem(src, Config.Ambulance.ReviveItem, 1)

    local Target = GetPlayer(targetServerId)
    if Target then
        Target.Functions.SetMetaData('isdead', false)
        TriggerClientEvent('hospital:client:Revive', targetServerId)
        TriggerClientEvent('ox_lib:notify', targetServerId, {
            title = '💚 Reanimiert', description = 'Du wurdest von der Feuerwehr reanimiert!', type = 'success',
        })
    end
end)

-- ──────────────────────────────────────────
-- ERSTVERSORGUNG
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:TreatPlayer', function(targetServerId)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end

    exports.ox_inventory:RemoveItem(src, 'firstaidkit', 1)

    local Target = GetPlayer(targetServerId)
    if Target then
        TriggerClientEvent('qbx_firedepartmentjob:client:AddHealth', targetServerId, 50)
        TriggerClientEvent('ox_lib:notify', targetServerId, {
            title = '🩹 Erstversorgung', description = 'Du wurdest von der Feuerwehr versorgt.', type = 'success',
        })
    end
end)

-- ──────────────────────────────────────────
-- EMS BENACHRICHTIGEN
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:NotifyEMS', function(downedPlayerId, coords)
    local players = GetPlayers()
    for _, player in pairs(players) do
        if player.PlayerData.job.name == 'ambulance' then
            TriggerClientEvent('ox_lib:notify', player.PlayerData.source, {
                title       = '🚑 Feuerwehr Info',
                description = string.format('Bewusstloser Spieler (ID %d) an Position %.1f / %.1f',
                    downedPlayerId, coords.x, coords.y),
                type = 'warning', duration = 10000,
            })
        end
    end
end)

-- ──────────────────────────────────────────
-- KLEIDUNG
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:server:SetOutfit', function(outfitName)
    local src = source
    -- bostra_appearance: Outfits werden client-seitig über den Outfit-Namen geladen
    -- Der Client sucht das Outfit aus der bostra_appearance Datenbank
    TriggerClientEvent('qbx_firedepartmentjob:client:ApplyOutfit', src, outfitName)
end)

-- ──────────────────────────────────────────
-- CLIENT: Gesundheit hinzufügen
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:AddHealth', function(amount)
    local ped = PlayerPedId()
    SetEntityHealth(ped, math.min(200, GetEntityHealth(ped) + amount))
end)


-- ──────────────────────────────────────────
-- ITEM: firehose – ox_inventory server export
-- In der item-Definition bei ox_inventory:
--   server.export = 'qbx_firedepartmentjob.firehose'
-- ──────────────────────────────────────────

exports('firehose', function(event, item, inventory, slot, data)
    if event == 'usingItem' then
        return -- Item darf benutzt werden
    end

    if event == 'usedItem' then
        TriggerClientEvent('qbx_firedepartmentjob:client:UseHose', inventory.id)
    end
end)