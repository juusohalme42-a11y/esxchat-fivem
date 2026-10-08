local ESX = exports['es_extended']:getSharedObject()

-- Estä GTA/FiveM:n vanha tekstichat ja sen iso musta taustalaatikko.
-- Oma NUI-chat toimii tästä riippumatta.
CreateThread(function()
    SetTextChatEnabled(false)

    -- Varmistus resourcejen restartteja varten.
    while true do
        Wait(5000)
        SetTextChatEnabled(false)
    end
end)

local chatOpen = false
local isAdmin = false

-- Vain ESX-admin-komentojen autocomplete.
-- Ei reporttia eikä admin-chattia.
local AdminCommands = {
    { command='setcoords', description='📍 Teleporttaa koordinaatteihin', usage='/setcoords x y z' },
    { command='tp', description='📍 Teleporttaa koordinaatteihin', usage='/tp x y z' },
    { command='setjob', description='💼 Aseta pelaajan työ', usage='/setjob [id] [job] [grade]' },
    { command='car', description='🚗 Spawnaa ajoneuvo', usage='/car [model]' },
    { command='cardel', description='🗑️ Poista ajoneuvo', usage='/cardel' },
    { command='dv', description='🗑️ Poista ajoneuvo', usage='/dv' },
    { command='fix', description='🔧 Korjaa ajoneuvo', usage='/fix' },
    { command='repair', description='🔧 Korjaa ajoneuvo', usage='/repair' },
    { command='setaccountmoney', description='💰 Aseta tilin rahat', usage='/setaccountmoney [id] [account] [amount]' },
    { command='giveaccountmoney', description='💵 Anna rahaa', usage='/giveaccountmoney [id] [account] [amount]' },
    { command='removeaccountmoney', description='💸 Poista rahaa', usage='/removeaccountmoney [id] [account] [amount]' },
    { command='giveitem', description='📦 Anna item', usage='/giveitem [id] [item] [count]' },
    { command='giveweapon', description='🔫 Anna ase', usage='/giveweapon [id] [weapon] [ammo]' },
    { command='giveammo', description='🎯 Anna ammuksia', usage='/giveammo [id] [weapon] [ammo]' },
    { command='giveweaponcomponent', description='🧩 Anna aseen komponentti', usage='/giveweaponcomponent [id] [weapon] [component]' },
    { command='clearall', description='🧹 Tyhjennä kaikkien chat', usage='/clearall' },
    { command='clsall', description='🧹 Tyhjennä kaikkien chat', usage='/clsall' },
    { command='refreshjobs', description='🔄 Päivitä jobit', usage='/refreshjobs' },
    { command='refreshitems', description='🔄 Päivitä itemit', usage='/refreshitems' },
    { command='clearinventory', description='🎒 Tyhjennä inventory', usage='/clearinventory [id]' },
    { command='clearloadout', description='🗑️ Tyhjennä loadout', usage='/clearloadout [id]' },
    { command='setgroup', description='🛡️ Aseta group', usage='/setgroup [id] [group]' },
    { command='save', description='💾 Tallenna pelaaja', usage='/save [id]' },
    { command='saveall', description='💾 Tallenna kaikki', usage='/saveall' },
    { command='goto', description='➡️ Mene pelaajan luokse', usage='/goto [id]' },
    { command='bring', description='⬅️ Tuo pelaaja luoksesi', usage='/bring [id]' },
    { command='kill', description='💀 Tapa pelaaja', usage='/kill [id]' },
    { command='freeze', description='🧊 Jäädytä pelaaja', usage='/freeze [id]' },
    { command='unfreeze', description='🔥 Poista jäädytys', usage='/unfreeze [id]' },
    { command='setdim', description='🌐 Aseta routing bucket', usage='/setdim [id] [bucket]' },
    { command='setbucket', description='🌐 Aseta routing bucket', usage='/setbucket [id] [bucket]' },
    { command='players', description='👥 Näytä pelaajat', usage='/players' },
    { command='noclip', description='🪽 NoClip', usage='/noclip' },
    { command='tpm', description='🗺️ Teleporttaa waypointille', usage='/tpm' },
    { command='coords', description='📌 Näytä koordinaatit', usage='/coords' }
}

local function StripFiveMFormatting(text)
    text = tostring(text or '')

    -- ^0 ... ^9
    text = text:gsub('%^%d', '')

    -- FiveM:n muut yleiset formatointikoodit.
    text = text:gsub('%^%*', '')
    text = text:gsub('%^_', '')
    text = text:gsub('%^~', '')
    text = text:gsub('%^=', '')
    text = text:gsub('%^%+', '')
    text = text:gsub('%^%-', '')

    return text
end

local function DetectMessageKind(name, message)
    local cleanName = StripFiveMFormatting(name):lower()
    local cleanMessage = StripFiveMFormatting(message):lower()
    local check = cleanName .. ' ' .. cleanMessage

    if check:find('twitter', 1, true) then
        return 'twitter'
    end

    if cleanName:find('reportti', 1, true) or cleanName:find('report', 1, true) then
        return 'report'
    end

    -- Admin-chat pysyy kokonaan toisen scriptin omana.
    -- Tämä chatti vain tunnistaa sen otsikon/prefixin ja vaihtaa ulkoasun.
    if cleanName:find('admin', 1, true)
        or cleanName:find('ylläpito', 1, true)
        or cleanName:find('staff', 1, true)
    then
        return 'admin'
    end

    return 'system'
end

local function refreshAdmin()
    ESX.TriggerServerCallback('hndeesxchat:isAdmin', function(result)
        isAdmin = result == true

        SendNUIMessage({
            action = 'adminState',
            isAdmin = isAdmin,
            commands = isAdmin and AdminCommands or {}
        })
    end)
end

local function openChat()
    if chatOpen then return end

    chatOpen = true
    refreshAdmin()

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end

local function closeChat()
    chatOpen = false

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand('hndeesxchat_open', openChat, false)
RegisterKeyMapping('hndeesxchat_open', 'Avaa chat', 'keyboard', 'T')

RegisterNUICallback('close', function(_, cb)
    closeChat()
    cb('ok')
end)

RegisterNUICallback('sendMessage', function(data, cb)
    local message = tostring(data.message or ''):gsub('^%s+', ''):gsub('%s+$', '')

    if message ~= '' then
        if message:sub(1, 1) == '/' then
            -- Chatti ei rekisteröi report/adminchat-komentoja.
            -- Komento menee suoraan sille resourcelle, joka sen omistaa.
            local command = message:sub(2)

            if command ~= '' then
                ExecuteCommand(command)
            end
        else
            TriggerServerEvent('hndeesxchat:sendMessage', message)
        end
    end

    closeChat()
    cb('ok')
end)

RegisterNetEvent('hndeesxchat:addMessage', function(data)
    if type(data) ~= 'table' then return end

    data.name = StripFiveMFormatting(data.name)
    data.message = StripFiveMFormatting(data.message)

    SendNUIMessage({
        action = 'message',
        data = data
    })
end)

-- Yhteensopivuus muiden scriptien chat:addMessage-viesteille.
-- Twitter/report tulevat niiden OMISTA scripteistä; tämä vain näyttää ne oikein.
RegisterNetEvent('chat:addMessage', function(data)
    if type(data) ~= 'table' then return end

    local args = data.args or {}
    local rawName = 'Järjestelmä'
    local rawMessage = ''

    if #args >= 2 then
        rawName = tostring(args[1] or 'Järjestelmä')
        rawMessage = tostring(args[2] or '')
    elseif #args == 1 then
        rawMessage = tostring(args[1] or '')
    else
        return
    end

    local kind = DetectMessageKind(rawName, rawMessage)

    SendNUIMessage({
        action = 'message',
        data = {
            name = StripFiveMFormatting(rawName),
            message = StripFiveMFormatting(rawMessage),
            time = '',
            kind = kind
        }
    })
end)

RegisterNetEvent('chat:clear', function()
    SendNUIMessage({ action = 'clear' })
end)

-- Oma autocomplete näyttää vain yllä määritetyt admin-komennot.
RegisterNetEvent('chat:addSuggestion', function() end)
RegisterNetEvent('chat:addSuggestions', function() end)
RegisterNetEvent('chat:removeSuggestion', function() end)

CreateThread(function()
    while not ESX.IsPlayerLoaded() do
        Wait(500)
    end

    refreshAdmin()
end)

RegisterNetEvent('esx:playerLoaded', function()
    Wait(500)
    refreshAdmin()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        SetNuiFocus(false, false)
    end
end)
