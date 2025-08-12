local activePopups = {}
local popupVisibilityState = {}

local cachedScreenRes = {1920, 1080}
local lastScreenResCheck = 0
local nuiReady = false

CreateThread(function()
    Wait(1000)
    SendNUIMessage({
        action = "init"
    })
    nuiReady = true
end)

--- Updates cached screen resolution for performance optimization
--- Only updates every 1000ms to avoid excessive calls
local UpdateScreenResolution = function()
    local currentTime = GetGameTimer()
    
    if currentTime - lastScreenResCheck > 1000 then
        cachedScreenRes[1], cachedScreenRes[2] = GetActiveScreenResolution()
        lastScreenResCheck = currentTime
    end
end

--- Checks for players entering range of active popups and shows them
--- Only processes players who have active popups and are within 25 units
--- Handles showing popups for newly in-range players
local CheckPlayersInRange = function()
    if next(activePopups) == nil then 
        return 
    end
    
    local myPed = PlayerPedId()
    local myServerId = GetPlayerServerId(PlayerId())
    local myCoords = GetEntityCoords(myPed)
    local players = GetActivePlayers()
    
    for _, player in ipairs(players) do
        local playerServerId = GetPlayerServerId(player)
        
        if playerServerId ~= myServerId and activePopups[playerServerId] then
            local playerPed = GetPlayerPed(player)
            
            if DoesEntityExist(playerPed) then
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(playerCoords - myCoords)
                
                if distance < 25.0 then
                    local popupData = activePopups[playerServerId]
                    
                    if GetGameTimer() - popupData.startTime < 5000 and not popupVisibilityState[playerServerId] then
                        -- Get head bone position for consistent positioning relative to head
                        local headBone = GetPedBoneCoords(playerPed, 0x796e, 0.0, 0.0, 0.0)
                        local popupPos = vector3(headBone.x, headBone.y, headBone.z + 0.3)
                        local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(popupPos.x, popupPos.y, popupPos.z)
                        
                        if onScreen and nuiReady then
                            local pixelX = screenX * cachedScreenRes[1]
                            local pixelY = screenY * cachedScreenRes[2]
                            
                            SendNUIMessage({
                                action = "showPopup",
                                type = popupData.type,
                                text = popupData.text,
                                playerName = popupData.playerName,
                                source = playerServerId,
                                screenX = pixelX,
                                screenY = pixelY
                            })
                            
                            popupVisibilityState[playerServerId] = true
                        end
                    end
                elseif popupVisibilityState[playerServerId] then
                    SendNUIMessage({
                        action = "hidePopup",
                        source = playerServerId
                    })
                    popupVisibilityState[playerServerId] = false
                end
            end
        end
    end
end

--- Updates positions of all active popups in 3D space
--- Handles popup expiration, visibility changes, and position updates
--- Only processes visible popups for performance optimization
local UpdatePopupPositions = function()
    if next(activePopups) == nil then 
        return 
    end
    
    UpdateScreenResolution()
    local myPed = PlayerPedId()
    local myServerId = GetPlayerServerId(PlayerId())
    local myCoords = GetEntityCoords(myPed)
    local currentTime = GetGameTimer()
    
    for source, popupData in pairs(activePopups) do
        if currentTime - popupData.startTime > 5000 then
            activePopups[source] = nil
            popupVisibilityState[source] = nil
            SendNUIMessage({
                action = "hidePopup",
                source = source
            })
        else
            local playerId = GetPlayerFromServerId(source)
            
            if playerId ~= -1 or source == myServerId then
                local playerPed = GetPlayerPed(playerId)
                
                if DoesEntityExist(playerPed) then
                    local sourceCoords = GetEntityCoords(playerPed)
                    local distance = #(sourceCoords - myCoords)
                    local isCurrentlyVisible = popupVisibilityState[source] or false
                    
                    if distance < 25.0 then
                        local headBone = GetPedBoneCoords(playerPed, 0x796e, 0.0, 0.0, 0.0)
                        local popupPos = vector3(headBone.x, headBone.y, headBone.z + 0.3)
                        local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(popupPos.x, popupPos.y, popupPos.z)
                        
                        if onScreen and isCurrentlyVisible and nuiReady then
                            local pixelX = screenX * cachedScreenRes[1]
                            local pixelY = screenY * cachedScreenRes[2]
                            
                            SendNUIMessage({
                                action = "updatePosition",
                                source = source,
                                screenX = pixelX,
                                screenY = pixelY,
                                visible = true
                            })
                        elseif not onScreen and isCurrentlyVisible and nuiReady then
                            SendNUIMessage({
                                action = "updatePosition",
                                source = source,
                                visible = false
                            })
                        end
                    elseif isCurrentlyVisible and nuiReady then
                        SendNUIMessage({
                            action = "updatePosition",
                            source = source,
                            visible = false
                        })
                    end
                end
            end
        end
    end
    
    CheckPlayersInRange()
end

--- Displays a 3D popup above a player's head for roleplay actions
--- @param actionType string The type of action (me, do, med, animal)
--- @param text string The text content to display in the popup
--- @param source number The server ID of the player performing the action
local ShowActionPopup = function(actionType, text, source)
    local myServerId = GetPlayerServerId(PlayerId())
    local myPed = PlayerPedId()
    
    -- Wait for NUI to be ready
    if not nuiReady then
        CreateThread(function()
            while not nuiReady do
                Wait(100)
            end
            ShowActionPopup(actionType, text, source)
        end)
        return
    end
    
    local playerId = GetPlayerFromServerId(source)
    
    if activePopups[source] and popupVisibilityState[source] then
        SendNUIMessage({
            action = "hidePopup",
            source = source
        })
    end
    
    activePopups[source] = {
        type = actionType,
        text = text,
        playerName = "",
        startTime = GetGameTimer()
    }
    
    popupVisibilityState[source] = false
    
    if playerId ~= -1 or source == myServerId then
        local playerPed = GetPlayerPed(playerId)
        
        if DoesEntityExist(playerPed) then
            local sourceCoords = GetEntityCoords(playerPed)
            local nearCoords = GetEntityCoords(myPed)
            local distance = #(sourceCoords - nearCoords)
            
            if distance < 25.0 then
                local headBone = GetPedBoneCoords(playerPed, 0x796e, 0.0, 0.0, 0.0)
                local popupPos = vector3(headBone.x, headBone.y, headBone.z + 0.3)
                local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(popupPos.x, popupPos.y, popupPos.z)
                
                if onScreen then
                    UpdateScreenResolution()
                    local pixelX = screenX * cachedScreenRes[1]
                    local pixelY = screenY * cachedScreenRes[2]
                    
                    SendNUIMessage({
                        action = "showPopup",
                        type = actionType,
                        text = text,
                        playerName = "",
                        source = source,
                        screenX = pixelX,
                        screenY = pixelY
                    })
                    
                    popupVisibilityState[source] = true
                end
            end
        end
    end
end

--- Main render loop for updating popup positions
--- Runs at 60fps when popups are active, sleeps when idle for performance
CreateThread(function()
    while true do
        if next(activePopups) ~= nil then
            UpdatePopupPositions()
            Wait(16)
        else
            Wait(500)
        end
    end
end)

--- Event handler for /me commands (character emotes/actions)
--- @param text string The emote text to display
--- @param source number The server ID of the player
--- @param icon any Unused parameter for compatibility
RegisterNetEvent("3dme:me", function(text, source, icon)
    ShowActionPopup("me", text, source)
end)

--- Event handler for /do commands (environmental actions/outcomes)
--- @param text string The action description to display
--- @param source number The server ID of the player
--- @param icon any Unused parameter for compatibility
RegisterNetEvent("3dme:do", function(text, source, icon)
    ShowActionPopup("do", text, source)
end)

--- Event handler for /med commands (medical roleplay actions)
--- @param text string The medical action text to display
--- @param source number The server ID of the player
--- @param icon any Unused parameter for compatibility
RegisterNetEvent("3dme:med", function(text, source, icon)
    ShowActionPopup("med", text, source)
end)

--- Event handler for /animal commands (animal roleplay actions)
--- @param text string The animal action text to display
--- @param source number The server ID of the player
--- @param icon any Unused parameter for compatibility
RegisterNetEvent("3dme:animal", function(text, source, icon)
    ShowActionPopup("animal", text, source)
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Clear all active popups
        for source, _ in pairs(activePopups) do
            SendNUIMessage({
                action = "hidePopup",
                source = source
            })
        end
        activePopups = {}
        popupVisibilityState = {}
        nuiReady = false
    end
end)

