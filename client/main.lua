-- ╔══════════════════════════════════════════╗
-- ║         CLIENT / MAIN.LUA               ║
-- ╚══════════════════════════════════════════╝

-- QBX: kein GetCoreObject/getSharedObject – direkt exports nutzen
local function GetPlayerData() return exports.qbx_core:GetPlayerData() end

local PlayerJob    = {}
local isOnDuty     = false
local paycheckTimer = nil

-- ──────────────────────────────────────────
-- INITIALISIERUNG
-- ──────────────────────────────────────────

-- Blips immer für alle Spieler setzen (Wachen sichtbar auf Karte)
local stationBlips = {}

local function CreateStationBlips()
    -- Alte Blips entfernen falls vorhanden
    for _, blip in ipairs(stationBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    stationBlips = {}

    for _, station in pairs(Config.Stations) do
        local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
        SetBlipSprite(blip, station.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, station.blip.scale)
        SetBlipColour(blip, station.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(station.label)
        EndTextCommandSetBlipName(blip)
        stationBlips[#stationBlips + 1] = blip
    end
end

-- Resource gestartet während Spieler bereits eingeloggt ist
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Wait(500)
    CreateStationBlips()
    PlayerJob = GetPlayerData().job
    if IsFirefighter(PlayerJob) then
        SetupFirefighterJob()
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    CreateStationBlips()
    PlayerJob = GetPlayerData().job
    if IsFirefighter(PlayerJob) then
        SetupFirefighterJob()
    end
end)

AddEventHandler('QBCore:Client:OnJobUpdate', function(jobInfo)
    PlayerJob = jobInfo
    if IsFirefighter(PlayerJob) then
        SetupFirefighterJob()
    else
        CleanupFirefighterJob()
    end
end)

-- ──────────────────────────────────────────
-- JOB SETUP / CLEANUP
-- ──────────────────────────────────────────

function SetupFirefighterJob()
    TriggerEvent('qbx_firedepartmentjob:client:RegisterTargets')

    if Config.Paycheck.Enabled and isOnDuty then
        StartPaycheckTimer()
    end

    lib.notify({
        title       = '🔥 Feuerwehr',
        description = 'Willkommen zurück!',
        type        = 'success',
        duration    = 5000,
    })
end

function CleanupFirefighterJob()
    isOnDuty = false
    if paycheckTimer then
        ClearTimeout(paycheckTimer)
        paycheckTimer = nil
    end
end

-- ──────────────────────────────────────────
-- DIENST AN/AUS
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:SetDuty', function(duty)
    isOnDuty = duty
    if duty then
        lib.notify({ title = '🔥 Feuerwehr', description = 'Du bist jetzt im Dienst', type = 'success' })
        StartPaycheckTimer()
    else
        lib.notify({ title = '🔥 Feuerwehr', description = 'Du bist nicht mehr im Dienst', type = 'error' })
        if paycheckTimer then
            ClearTimeout(paycheckTimer)
            paycheckTimer = nil
        end
    end
end)

-- ──────────────────────────────────────────
-- HAUPTMENÜ
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:OpenMainMenu', function()
    PlayerJob = GetPlayerData().job
    if not IsFirefighter(PlayerJob) then return end

    lib.registerContext({
        id    = 'fd_main_menu',
        title = '🔥 Feuerwehr – Hauptmenü',
        options = {
            {
                title    = isOnDuty and '🔴 Dienst beenden' or '🟢 Dienst beginnen',
                icon     = isOnDuty and 'circle-stop' or 'circle-play',
                onSelect = function()
                    TriggerServerEvent('qbx_firedepartmentjob:server:ToggleDuty')
                end,
            },
            {
                title    = '🚒 Fahrzeug spawnen',
                icon     = 'truck',
                disabled = not isOnDuty,
                onSelect = function()
                    TriggerEvent('qbx_firedepartmentjob:client:OpenVehicleMenu')
                end,
            },
            {
                title    = '🎽 Ausrüstung holen',
                icon     = 'box-open',
                disabled = not isOnDuty,
                onSelect = function()
                    TriggerEvent('qbx_firedepartmentjob:client:GetEquipment')
                end,
            },
            {
                title    = '📡 Aktive Einsätze',
                icon     = 'bell',
                disabled = not isOnDuty,
                onSelect = function()
                    TriggerEvent('qbx_firedepartmentjob:client:ViewCallouts')
                end,
            },
        },
    })
    lib.showContext('fd_main_menu')
end)

-- ──────────────────────────────────────────
-- AUSRÜSTUNG
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:GetEquipment', function()
    if not isOnDuty then return end
    PlayerJob = GetPlayerData().job

    local options = {}
    for _, equip in ipairs(Config.Equipment) do
        if HasRequiredGrade(PlayerJob, equip.grade) then
            options[#options + 1] = {
                title       = equip.label,
                description = 'Grad erforderlich: ' .. equip.grade,
                icon        = 'box',
                onSelect    = function()
                    TriggerServerEvent('qbx_firedepartmentjob:server:GiveEquipment', equip.item)
                end,
            }
        end
    end

    lib.registerContext({
        id      = 'fd_equipment_menu',
        title   = '🎽 Ausrüstung',
        menu    = 'fd_main_menu',
        options = options,
    })
    lib.showContext('fd_equipment_menu')
end)

-- ──────────────────────────────────────────
-- GEHALT TIMER
-- ──────────────────────────────────────────

function StartPaycheckTimer()
    if paycheckTimer then ClearTimeout(paycheckTimer) end
    local intervalMs = Config.Paycheck.IntervalMin * 60 * 1000
    paycheckTimer = SetTimeout(intervalMs, function()
        PlayerJob = GetPlayerData().job
        if isOnDuty and IsFirefighter(PlayerJob) then
            TriggerServerEvent('qbx_firedepartmentjob:server:Paycheck')
            StartPaycheckTimer()
        end
    end)
end

-- ──────────────────────────────────────────
-- MARKER AN WACHEN
-- ──────────────────────────────────────────

CreateThread(function()
    while true do
        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local nearby = false

        for _, station in pairs(Config.Stations) do
            local dist = #(coords - vector3(station.coords.x, station.coords.y, station.coords.z))

            if dist < 30.0 then
                nearby = true
                -- Haupt-Marker (Boden)
                DrawMarker(
                    1,                                          -- Typ: Zylinder
                    station.coords.x, station.coords.y, station.coords.z - 0.1,
                    0.0, 0.0, 0.0,                             -- Richtung
                    0.0, 0.0, 0.0,                             -- Rotation
                    1.5, 1.5, 0.5,                             -- Größe
                    255, 106, 0, 120,                          -- Farbe (Orange, leicht transparent)
                    false, true, 2, false, nil, nil, false
                )

                -- Pfeil oben drüber
                DrawMarker(
                    25,                                        -- Typ: Pfeil nach unten
                    station.coords.x, station.coords.y, station.coords.z + 1.2,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    0.4, 0.4, 0.4,
                    255, 106, 0, 200,
                    false, true, 2, false, nil, nil, false
                )
            end
        end

        Wait(nearby and 0 or 500)
    end
end)