fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Jube'
description 'ESX Chat'
version '1.0.0'

dependency 'es_extended'

shared_scripts {
  'config.lua'
}

server_scripts {
  '@es_extended/imports.lua',
  'server/main.lua'
}

client_scripts {
  '@es_extended/imports.lua',
  'client/main.lua'
}
