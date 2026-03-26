Config = {}

-- ╔══════════════════════════════════════════╗
-- ║           JOB & GRADE SETTINGS           ║
-- ╚══════════════════════════════════════════╝

Config.JobName = 'firefighter'

Config.Grades = {
    [0] = { name = 'Rookie',        label = 'Rookie Feuerwehrmann' },
    [1] = { name = 'firefighter',   label = 'Feuerwehrmann' },
    [2] = { name = 'senior',        label = 'Senior Feuerwehrmann' },
    [3] = { name = 'lieutenant',    label = 'Leutnant' },
    [4] = { name = 'captain',       label = 'Hauptmann' },
    [5] = { name = 'chief',         label = 'Feuerwehrchef' },
}

-- ╔══════════════════════════════════════════╗
-- ║              STANDORTE / BLIPS           ║
-- ╚══════════════════════════════════════════╝

Config.Stations = {
    [1] = {
        label   = 'Feuerwache 1 – Davis',
        coords  = vector4(1193.77, -1473.41, 34.86, 91.0),
        blip    = { sprite = 436, color = 1, scale = 0.8 },
    },
    [2] = {
        label   = 'Feuerwache 2 – Strawberry',
        coords  = vector4(204.89, -1643.81, 29.79, 232.0),
        blip    = { sprite = 436, color = 1, scale = 0.8 },
    },
}

-- ╔══════════════════════════════════════════╗
-- ║            FAHRZEUG SPAWNS               ║
-- ╚══════════════════════════════════════════╝

Config.VehicleSpawns = {
    [1] = { -- Station 1
        { coords = vector4(1195.5, -1480.2, 34.86, 0.0),   model = 'firetruk',  label = 'Löschfahrzeug' },
        { coords = vector4(1199.5, -1480.2, 34.86, 0.0),   model = 'ambulance', label = 'Rettungswagen' },
    },
    [2] = { -- Station 2
        { coords = vector4(206.0, -1652.0, 29.79, 55.0),   model = 'firetruk',  label = 'Löschfahrzeug' },
    },
}

-- ╔══════════════════════════════════════════╗
-- ║               AUSRÜSTUNG                 ║
-- ╚══════════════════════════════════════════╝

Config.Equipment = {
    { item = 'fireaxe',        label = 'Feuerwehraxt',      grade = 0 },
    { item = 'firehose',       label = 'Feuerwehrschlauch', grade = 0 },
    { item = 'fireextinguisher', label = 'Feuerlöscher',    grade = 0 },
    { item = 'oxygenkit',      label = 'Sauerstoffmaske',   grade = 1 },
    { item = 'firstaidkit',    label = 'Verbandskasten',    grade = 0 },
    { item = 'defibrilator',   label = 'Defibrillator',     grade = 2 },
}

-- ╔══════════════════════════════════════════╗
-- ║              EINSATZ SETTINGS            ║
-- ╚══════════════════════════════════════════╝

Config.Callouts = {
    MinGrade        = 0,        -- Mindeststufe für Einsatzannahme
    AutoAssign      = false,    -- Automatisch zuweisen?
    BlipSprite      = 436,
    BlipColor       = 1,
    AlertSound      = true,
    MaxActiveCallouts = 5,

    Types = {
        ['house_fire']    = { label = 'Hausbrand',          priority = 2, reward = 500  },
        ['car_fire']      = { label = 'Fahrzeugbrand',      priority = 1, reward = 300  },
        ['wildfire']      = { label = 'Waldbrand',          priority = 3, reward = 800  },
        ['gas_leak']      = { label = 'Gasaustritt',        priority = 3, reward = 700  },
        ['accident']      = { label = 'Verkehrsunfall',     priority = 2, reward = 400  },
        ['medical']       = { label = 'Medizinischer Notfall', priority = 2, reward = 450 },
    },

    -- Mögliche zufällige Einsatzorte
    Locations = {
        { coords = vector3(116.27,  -1007.02, 29.38), type = 'house_fire',  label = 'Rockford Hills' },
        { coords = vector3(-1045.2,  -2751.0, 21.36), type = 'car_fire',    label = 'Sandy Shores'   },
        { coords = vector3(285.42,  -1256.93, 28.64), type = 'accident',    label = 'Davis Ave'      },
        { coords = vector3(425.33,   -980.19, 30.69), type = 'gas_leak',    label = 'Little Seoul'   },
        { coords = vector3(-350.0,   -1567.0, 28.21), type = 'medical',     label = 'Vespucci Blvd'  },
    },
}

-- ╔══════════════════════════════════════════╗
-- ║            SCHLAUCH / WASSER             ║
-- ╚══════════════════════════════════════════╝

Config.Hose = {
    Item            = 'firehose',
    MaxDistance     = 15.0,         -- Max. Reichweite in Metern
    WaterPressure   = 5.0,          -- Löschkraft pro Sekunde
    RequiredItem    = true,         -- Item nötig?
    ParticleEffect  = 'core',
    ParticleName    = 'ent_amb_fountain_spray_mist',
}

-- ╔══════════════════════════════════════════╗
-- ║          AMBULANZ INTEGRATION            ║
-- ╚══════════════════════════════════════════╝

Config.Ambulance = {
    Enabled         = true,
    ReviveItem      = 'defibrilator',
    ReviveGrade     = 2,
    ReviveTime      = 8000,         -- ms
    ReviveDistance  = 3.0,
    NotifyEMS       = true,         -- EMS bei Bewusstlosen informieren?
}

-- ╔══════════════════════════════════════════╗
-- ║                  GEHALT                  ║
-- ╚══════════════════════════════════════════╝

Config.Paycheck = {
    Enabled     = true,
    IntervalMin = 30,   -- Minuten
    Amounts = {
        [0] = 300,
        [1] = 450,
        [2] = 600,
        [3] = 800,
        [4] = 1000,
        [5] = 1500,
    },
}

-- ╔══════════════════════════════════════════╗
-- ║              LAGER-SYSTEM                ║
-- ║  ox_inventory Stash – kein Cooldown      ║
-- ╚══════════════════════════════════════════╝

Config.Storage = {
    -- Lager-Standorte (Inhalt wird direkt im ox_inventory Stash verwaltet)
    Locations = {
        [1] = {
            label     = 'Hauptlager – Wache 1',
            coords    = vector4(1196.5, -1475.0, 34.86, 91.0),
            stationId = 1,  -- Welcher Wache zugeordnet (optional)
        },
    },
}