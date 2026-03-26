-- ╔══════════════════════════════════════════╗
-- ║           CLIENT / HOSE.LUA             ║
-- ╚══════════════════════════════════════════╝

local hosePtfxHandle = nil
local hoseActive     = false

-- ──────────────────────────────────────────
-- ITEM BENUTZEN (server-side via ox_inventory usableItem)
-- ──────────────────────────────────────────

RegisterNetEvent('qbx_firedepartmentjob:client:UseHose', function()
    local job = exports.qbx_core:GetPlayerData().job
    if not IsFirefighter(job) then return end

    if hoseActive then
        StopHose()
    else
        StartHose()
    end
end)

-- ──────────────────────────────────────────
-- SCHLAUCH START
-- ──────────────────────────────────────────

function StartHose()
    hoseActive = true
    lib.notify({ title = '💧 Schlauch', description = 'Schlauch aktiviert. [E] zum Deaktivieren.', type = 'inform' })

    RequestNamedPtfxAsset(Config.Hose.ParticleEffect)
    while not HasNamedPtfxAssetLoaded(Config.Hose.ParticleEffect) do
        Wait(10)
    end

    CreateThread(function()
        while hoseActive do
            Wait(0)

            local ped    = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local camDir = GetFinalRenderedCamRot(2)

            local dirX = -math.sin(math.rad(camDir.z)) * math.cos(math.rad(camDir.x))
            local dirY =  math.cos(math.rad(camDir.z)) * math.cos(math.rad(camDir.x))
            local startPos = vector3(coords.x, coords.y, coords.z + 0.6)

            if not hosePtfxHandle or not DoesPtfxLoopedExist(hosePtfxHandle) then
                UseParticleFxAssetNextCall(Config.Hose.ParticleEffect)
                hosePtfxHandle = StartParticleFxLoopedAtCoord(
                    Config.Hose.ParticleName,
                    startPos.x, startPos.y, startPos.z,
                    0.0, 0.0, 0.0,
                    1.5, false, false, false, false
                )
            else
                SetParticleFxLoopedOffsets(hosePtfxHandle, startPos.x, startPos.y, startPos.z, 0.0, 0.0, 0.0)
            end

            local endPos = vector3(
                startPos.x + dirX * Config.Hose.MaxDistance,
                startPos.y + dirY * Config.Hose.MaxDistance,
                startPos.z
            )

            TriggerServerEvent('qbx_firedepartmentjob:server:HoseUpdate', startPos, endPos)

            if IsControlJustPressed(0, 38) then -- [E]
                StopHose()
            end
        end
    end)
end

-- ──────────────────────────────────────────
-- SCHLAUCH STOP
-- ──────────────────────────────────────────

function StopHose()
    hoseActive = false
    if hosePtfxHandle and DoesPtfxLoopedExist(hosePtfxHandle) then
        StopParticleFxLooped(hosePtfxHandle, false)
        hosePtfxHandle = nil
    end
    lib.notify({ title = '💧 Schlauch', description = 'Schlauch deaktiviert.', type = 'inform' })
end
