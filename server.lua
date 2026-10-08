local ESX = exports['es_extended']:getSharedObject()

-- Hndeesxchat korvaa FiveM:n vakiochatin kokonaan.
-- Vakio "chat" tekee kuvassa näkyvän ison mustan chat-window-taustan.
-- Tarkistetaan jatkuvasti, ettei jokin muu resource/server.cfg käynnistä sitä takaisin.
CreateThread(function()
    while true do
        local state = GetResourceState('chat')

        if state == 'started' or state == 'starting' then
            StopResource('chat')
            print('[Jube Chat] Stock chat pysäytetty: musta taustalaatikko poistettu.')
        end

        Wait(1000)
    end
end)

local SuggestionGroups = {
    admin = true,
    superadmin = true
}

ESX.RegisterServerCallback('hndeesxchat:isAdmin', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(false)
        return
    end
    cb(SuggestionGroups[xPlayer.getGroup()] == true)
end)

RegisterNetEvent('hndeesxchat:sendMessage', function(message)
    local src = source
    if type(message) ~= 'string' then return end

    message = message:gsub('^%s+', ''):gsub('%s+$', '')
    if message == '' then return end
    if #message > 500 then message = message:sub(1, 500) end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    TriggerClientEvent('hndeesxchat:addMessage', -1, {
        name = xPlayer.getName(),
        message = message,
        time = os.date('%H:%M'),
        kind = 'normal'
    })
end)
