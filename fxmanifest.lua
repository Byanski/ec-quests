fx_version "cerulean"
games {"gta5"}

description "Enhanced quests - OX Core Compatible"
author "Enhanced Studios"
version '1.1.0'

lua54 'yes'

ui_page 'web/build/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/**/*'
}

client_script 'client/**/*'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/bridge/*.lua', -- Load bridges first
    'server/**/*'
}

files {
    'locales/*.json',
    'web/index.html',
    'web/**/*'
}

dependencies {
    'ox_lib',
    'oxmysql'
}
