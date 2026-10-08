fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Jube'
description 'ESX Legacy custom chat'
version '2.0.0'

ui_page 'html/index.html'

shared_script '@es_extended/imports.lua'
client_script 'client.lua'
server_script 'server.lua'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependency 'es_extended'
