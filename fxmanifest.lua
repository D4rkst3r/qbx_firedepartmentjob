fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name        'qbx_firedepartmentjob'
description 'Feuerwehr Job Script für QBX Framework'
author      'D4rkst3r'
version     '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/functions.lua',
    'shared/debug.lua',
}

client_scripts {
    'client/main.lua',
    'client/callouts.lua',
    'client/vehicles.lua',
    'client/hose.lua',
    'client/ambulance.lua',
    'client/targets.lua',
    'client/admin.lua',
    'client/debug.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/callouts.lua',
    'server/vehicles.lua',
    'server/admin.lua',
    'server/config_edit.lua',
}

files {
    'locales/*.json',
    'html/admin.html',
}

ui_page 'html/admin.html'

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'oxmysql',
}