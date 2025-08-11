lib.addCommand('me', {
    help = 'Display a roleplay action above your head',
    params = {
        {
            name = 'text',
            type = 'longString',
            help = 'The action text to display',
        }
    }
}, function(source, args)
    local text = args.text or ''
    local icon = 'icons'
    text = string.sub(text, 1, 100)
    TriggerClientEvent('3dme:me', -1, text, source, icon)
end)

lib.addCommand('do', {
    help = 'Display a roleplay description above your head',
    params = {
        {
            name = 'text',
            type = 'longString',
            help = 'The description text to display',
        }
    }
}, function(source, args)
    local text = args.text or ''
    local icon = 'icons'
    text = string.sub(text, 1, 100)
    TriggerClientEvent('3dme:do', -1, text, source, icon)
end)

lib.addCommand('med', {
    help = 'Display a medical roleplay action above your head',
    params = {
        {
            name = 'text',
            type = 'longString',
            help = 'The medical action text to display',
        }
    }
}, function(source, args)
    local text = args.text or ''
    local icon = 'icons'
    text = string.sub(text, 1, 100)
    TriggerClientEvent('3dme:med', -1, text, source, icon)
end)

lib.addCommand('animal', {
    help = 'Display an animal roleplay action above your head',
    params = {
        {
            name = 'text',
            type = 'longString',
            help = 'The animal action text to display',
        }
    }
}, function(source, args)
    local text = args.text or ''
    local icon = 'icons'
    text = string.sub(text, 1, 100)
    TriggerClientEvent('3dme:animal', -1, text, source, icon)
end)