local function sendChatMessage(target, title, text, color)
  TriggerClientEvent('esxchat:showMessage', target, {
    title = title,
    text = text,
    color = color or Config.defaultColor
  })
end

RegisterCommand('me', function(source, args, rawCommand)
  if source == 0 then
    print('This command can only be used by a player.')
    return
  end

  if #args == 0 then
    TriggerClientEvent('chat:addMessage', source, {
      args = { 'System', 'Usage: /me [action]' }
    })
    return
  end

  local playerName = GetPlayerName(source) or 'Unknown'
  local message = table.concat(args, ' ')
  sendChatMessage(-1, playerName, message, Config.meColor)
end, false)

RegisterCommand('do', function(source, args, rawCommand)
  if source == 0 then
    print('This command can only be used by a player.')
    return
  end

  if #args == 0 then
    TriggerClientEvent('chat:addMessage', source, {
      args = { 'System', 'Usage: /do [description]' }
    })
    return
  end

  local playerName = GetPlayerName(source) or 'Unknown'
  local message = table.concat(args, ' ')
  sendChatMessage(-1, playerName, message, Config.doColor)
end, false)

RegisterCommand('news', function(source, args, rawCommand)
  if source == 0 then
    print('This command can only be used by a player.')
    return
  end

  if #args == 0 then
    TriggerClientEvent('chat:addMessage', source, {
      args = { 'System', 'Usage: /news [message]' }
    })
    return
  end

  local message = table.concat(args, ' ')
  sendChatMessage(-1, 'News', message, Config.newsColor)
end, false)

RegisterCommand('ooc', function(source, args, rawCommand)
  if source == 0 then
    print('This command can only be used by a player.')
    return
  end

  if #args == 0 then
    TriggerClientEvent('chat:addMessage', source, {
      args = { 'System', 'Usage: /ooc [message]' }
    })
    return
  end

  local playerName = GetPlayerName(source) or 'Unknown'
  local message = table.concat(args, ' ')
  sendChatMessage(-1, playerName .. ' (OOC)', message, Config.oocColor)
end, false)

RegisterCommand('clear', function(source)
  TriggerClientEvent('chat:clear', source)
end, false)

RegisterCommand('chathelp', function(source)
  TriggerClientEvent('chat:addMessage', source, {
    args = { 'Commands', '/me [action] | /do [description] | /news [message] | /ooc [message] | /clear' }
  })
end, false)

for _, command in ipairs(Config.commands) do
  TriggerEvent('chat:addSuggestion', '/' .. command.name, command.help, command.args or {})
end

TriggerEvent('chat:addSuggestion', '/clear', 'Clear the chat', {})
TriggerEvent('chat:addSuggestion', '/chathelp', 'Show available chat commands', {})
