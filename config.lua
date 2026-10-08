Config = {}

Config.defaultColor = { 255, 255, 255 }
Config.meColor = { 255, 176, 0 }
Config.doColor = { 102, 204, 255 }
Config.newsColor = { 255, 215, 0 }
Config.oocColor = { 170, 170, 170 }
Config.systemColor = { 89, 171, 227 }

Config.commands = {
  { name = 'me', help = 'Roleplay action', args = { { name = 'action', help = 'What are you doing?' } } },
  { name = 'do', help = 'Describe surroundings or actions', args = { { name = 'action', help = 'What is happening around you?' } } },
  { name = 'news', help = 'Broadcast a news message', args = { { name = 'message', help = 'News text' } } },
  { name = 'ooc', help = 'Out-of-character chat', args = { { name = 'message', help = 'OOC message' } } }
}
