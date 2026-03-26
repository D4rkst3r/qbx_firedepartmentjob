-- ╔══════════════════════════════════════════╗
-- ║          CLIENT / TARGETS.LUA           ║
-- ╚══════════════════════════════════════════╝

local function GetPlayerData() return exports.qbx_core:GetPlayerData() end

AddEventHandler('qbx_firedepartmentjob:client:RegisterTargets', function()
    RegisterStationTargets()
end)

-- ──────────────────────────────────────────
-- WACHEN TARGETS
-- ──────────────────────────────────────────

function RegisterStationTargets()
    for stationId, station in pairs(Config.Stations) do
        exports.ox_target:addBoxZone({
            coords   = vector3(station.coords.x, station.coords.y, station.coords.z),
            size     = vector3(1.5, 1.5, 2.0),
            rotation = station.coords.w,
            debug    = false,
            options  = {
                {
                    name     = 'fd_mainmenu_' .. stationId,
                    label    = 'Feuerwehr Menü',
                    icon     = 'fas fa-fire',
                    distance = 2.0,
                    canInteract = function()
                        return IsFirefighter(GetPlayerData().job)
                    end,
                    onSelect = function()
                        TriggerNetEvent('qbx_firedepartmentjob:client:OpenMainMenu')
                    end,
                },
                {
                    name     = 'fd_cloakroom_' .. stationId,
                    label    = 'Umkleide',
                    icon     = 'fas fa-tshirt',
                    distance = 2.0,
                    canInteract = function()
                        return IsFirefighter(GetPlayerData().job)
                    end,
                    onSelect = function()
                        TriggerNetEvent('qbx_firedepartmentjob:client:OpenCloakroom')
                    end,
                },
            },
        })
    end

    for stationId, spawns in pairs(Config.VehicleSpawns) do
        for spawnIdx, spawn in ipairs(spawns) do
            exports.ox_target:addBoxZone({
                coords   = vector3(spawn.coords.x, spawn.coords.y, spawn.coords.z),
                size     = vector3(3.0, 6.5, 2.0),
                rotation = spawn.coords.w,
                debug    = false,
                options  = {
                    {
                        name     = 'fd_vehicle_' .. stationId .. '_' .. spawnIdx,
                        label    = spawn.label .. ' spawnen',
                        icon     = 'fas fa-truck',
                        distance = 3.0,
                        canInteract = function()
                            return IsFirefighter(GetPlayerData().job)
                        end,
                        onSelect = function()
                            TriggerEvent('qbx_firedepartmentjob:client:SpawnVehicle', spawn)
                        end,
                    },
                },
            })
        end
    end
end

-- ──────────────────────────────────────────
-- UMKLEIDE
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:OpenCloakroom', function()
    local grade = GetPlayerData().job.grade.level or 0

    lib.registerContext({
        id      = 'fd_cloakroom',
        title   = '🧥 Umkleide',
        options = {
            {
                title    = '🧥 Standarduniform',
                icon     = 'shirt',
                onSelect = function()
                    TriggerServerEvent('qbx_firedepartmentjob:server:SetOutfit', 'uniform')
                end,
            },
            {
                title    = '🔥 Brandschutzanzug',
                icon     = 'fire',
                onSelect = function()
                    TriggerServerEvent('qbx_firedepartmentjob:server:SetOutfit', 'firesuit')
                end,
            },
            {
                title    = '🏥 Rettungsanzug',
                icon     = 'kit-medical',
                disabled = grade < 2,
                onSelect = function()
                    TriggerServerEvent('qbx_firedepartmentjob:server:SetOutfit', 'rescue')
                end,
            },
            {
                title    = '👕 Zivilkleidung',
                icon     = 'person',
                onSelect = function()
                    TriggerServerEvent('qbx_firedepartmentjob:server:SetOutfit', 'civilian')
                end,
            },
        },
    })
    lib.showContext('fd_cloakroom')
end)

-- ──────────────────────────────────────────
-- GLOBALE PLAYER TARGETS (Reanimation etc.)
-- ──────────────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Wait(1000)

    exports.ox_target:addGlobalPlayer({
        {
            name     = 'fd_revive_player',
            label    = 'Reanimieren',
            icon     = 'fas fa-heart-pulse',
            distance = 3.0,
            canInteract = function(entity)
                local job = GetPlayerData().job
                if not HasRequiredGrade(job, Config.Ambulance.ReviveGrade) then return false end
                return IsPedDeadOrDying(entity, true) or IsEntityDead(entity)
            end,
            onSelect = function(data)
                local targetNetId = NetworkGetPlayerIndexFromPed(data.entity)
                TriggerEvent('qbx_firedepartmentjob:client:RevivePlayer', GetPlayerServerId(targetNetId))
            end,
        },
        {
            name     = 'fd_treat_player',
            label    = 'Erstversorgung',
            icon     = 'fas fa-kit-medical',
            distance = 3.0,
            canInteract = function(entity)
                local job = GetPlayerData().job
                if not IsFirefighter(job) then return false end
                return GetEntityHealth(entity) < 150 and not IsPedDeadOrDying(entity, true)
            end,
            onSelect = function(data)
                local targetNetId = NetworkGetPlayerIndexFromPed(data.entity)
                TriggerEvent('qbx_firedepartmentjob:client:TreatPlayer', GetPlayerServerId(targetNetId))
            end,
        },
    })
end)
