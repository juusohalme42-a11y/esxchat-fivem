local function addChatMessage(title, text, color)
  TriggerEvent('chat:addMessage', {
    args = { title, text },
    color = color or Config.defaultColor
  })
end

RegisterNetEvent('esxchat:showMessage', function(data)
  if not data or not data.text then
    return
  end

  addChatMessage(data.title or 'System', data.text, data.color or Config.defaultColor)
end)
