-- ==================== SERVICES ====================
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
 
-- ==================== SPREAD MODIFICATION ====================
local old; old = hookfunction(math.random, function(...)
    local args = {...}
 
    if checkcaller() then
        return old(...)
    end
 
    if (#args == 0) or 
       (args[1] == -0.05 and args[2] == 0.05) or 
       (args[1] == -0.1) or
       (args[1] == -0.05) then
 
        if shared.script['Weapon Modification']['Spread Modifier']['Enabled'] then
            local spread = shared.script['Weapon Modification']['Spread Modifier']['Value']
            return old(...) * (spread / 100)
        else
            return old(...)
        end
    end
    
    return old(...)
end)
 
-- ==================== VISUAL HEADLESS SYSTEM ====================
local headlessEnabled = shared.script['Visual']['Local Body']['Headless']
local headlessWeld = nil
local headlessFakeNeck = nil
 
local function setupVisualHeadless(character)
    if not headlessEnabled or not character then return end
    
    repeat 
        RunService.Heartbeat:Wait() 
    until character:FindFirstChild("Head") and character:FindFirstChild("UpperTorso")
    
    local head = character.Head
    
    -- Make head completely invisible
    head.Transparency = 1
    
    -- Remove facial features
    for _, child in pairs(head:GetChildren()) do
        if child:IsA("Decal") or child:IsA("SpecialMesh") then
            child:Destroy()
        end
    end
    
    -- Clean up previous fake neck if exists
    if headlessFakeNeck then
        headlessFakeNeck:Destroy()
        headlessFakeNeck = nil
    end
    
    if headlessWeld then
        headlessWeld:Destroy()
        headlessWeld = nil
    end
    
    -- Create fake neck part
    headlessFakeNeck = Instance.new("Part")
    headlessFakeNeck.Name = "FakeNeck"
    headlessFakeNeck.Size = Vector3.new(1, 0.5, 1)
    headlessFakeNeck.Transparency = 1
    headlessFakeNeck.CanCollide = false
    headlessFakeNeck.Anchored = false
    headlessFakeNeck.Parent = character
    
    -- Create weld to attach to upper torso
    headlessWeld = Instance.new("Weld")
    headlessWeld.Part0 = character.UpperTorso
    headlessWeld.Part1 = headlessFakeNeck
    headlessWeld.C0 = CFrame.new(0, -0.5, 0)
    headlessWeld.Parent = headlessFakeNeck
end
 
local function cleanupVisualHeadless()
    if headlessFakeNeck then
        headlessFakeNeck:Destroy()
        headlessFakeNeck = nil
    end
    
    if headlessWeld then
        headlessWeld:Destroy()
        headlessWeld = nil
    end
    
    -- Restore head visibility if character exists
    if LocalPlayer.Character then
        local head = LocalPlayer.Character:FindFirstChild("Head")
        if head then
            head.Transparency = 0
        end
    end
end
 
local function toggleVisualHeadless()
    headlessEnabled = not headlessEnabled
    
    if headlessEnabled then
        if LocalPlayer.Character then
            setupVisualHeadless(LocalPlayer.Character)
        end
    else
        cleanupVisualHeadless()
    end
    
    return headlessEnabled
end
 
-- ==================== SPEED SYSTEM ====================
local isSpeedEnabled = false
local speedConnection = nil
 
local function updateSpeed()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if isSpeedEnabled and shared.script['Speed']['Enabled'] then
            LocalPlayer.Character.Humanoid.WalkSpeed = shared.script['Speed']['Speed Modifier']['Value']
        else
            LocalPlayer.Character.Humanoid.WalkSpeed = 16 -- Default Roblox walk speed
        end
    end
end
 
local function toggleSpeedConnection()
    if isSpeedEnabled and shared.script['Speed']['Enabled'] then
        -- Create connection if it doesn't exist
        if not speedConnection then
            speedConnection = RunService.RenderStepped:Connect(updateSpeed)
        end
    else
        -- Disconnect if connection exists
        if speedConnection then
            speedConnection:Disconnect()
            speedConnection = nil
        end
        
        -- Reset to normal speed when disabled
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end
end
 
-- Handle character added
LocalPlayer.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid")
    if isSpeedEnabled and shared.script['Speed']['Enabled'] then
        character.Humanoid.WalkSpeed = shared.script['Speed']['Speed Modifier']['Value']
        -- Re-establish connection for new character
        if not speedConnection then
            speedConnection = RunService.RenderStepped:Connect(updateSpeed)
        end
    else
        character.Humanoid.WalkSpeed = 16
    end
    
    -- Setup visual headless for new character
    if headlessEnabled then
        setupVisualHeadless(character)
    end
end)
 
-- Handle initial character
if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
    LocalPlayer.Character.Humanoid.WalkSpeed = 16
    if headlessEnabled then
        setupVisualHeadless(LocalPlayer.Character)
    end
end
 
-- ==================== CACHE AND OPTIMIZATIONS ====================
local cachedPlayers = {}
local lastPlayerUpdate = 0
local playerUpdateInterval = 5
 
-- Cache frequently used values
local math_min = math.min
local math_clamp = math.clamp
local Vector2_new = Vector2.new
local CFrame_new = CFrame.new
local Color3_new = Color3.new
 
-- ==================== RAYCAST FUNCTION ====================
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.IgnoreWater = true
 
local function isPartVisible(origin, targetPart, ignoreList)
    local direction = (targetPart.Position - origin).Unit
    local distance = (targetPart.Position - origin).Magnitude
    
    local filter = {LocalPlayer.Character}
    if ignoreList then
        for i = 1, #ignoreList do
            filter[#filter + 1] = ignoreList[i]
        end
    end
    raycastParams.FilterDescendantsInstances = filter
    
    local raycastResult = Workspace:Raycast(origin, direction * distance, raycastParams)
    
    if not raycastResult then
        return true
    end
    
    local hitInstance = raycastResult.Instance
    if hitInstance and (hitInstance == targetPart or hitInstance:IsDescendantOf(targetPart.Parent)) then
        return true
    end
    
    if hitInstance and hitInstance:IsA("BasePart") and hitInstance.Transparency >= 0.8 then
        local newOrigin = raycastResult.Position + (direction * 1)
        local newRaycastResult = Workspace:Raycast(newOrigin, direction * (distance - 1), raycastParams)
        
        if not newRaycastResult then
            return true
        end
        
        local newHitInstance = newRaycastResult.Instance
        return newHitInstance and (newHitInstance == targetPart or newHitInstance:IsDescendantOf(targetPart.Parent))
    end
    
    return false
end
 
-- ==================== KNOCK CHECK ====================
local function isKnocked(char)
    if not char then return false end
    local bodyEffects = char:FindFirstChild('BodyEffects')
    if not bodyEffects then return false end
    local ko = bodyEffects:FindFirstChild('K.O')
    return ko and ko.Value == true
end
 
-- ==================== SILENT AIM SYSTEM ====================
local R15Parts = {
    "Head", 
    "HumanoidRootPart", 
    "UpperTorso", 
    "LowerTorso",
    "LeftUpperLeg",
    "LeftLowerLeg",
    "LeftFoot",
    "RightUpperLeg", 
    "RightLowerLeg",
    "RightFoot",
    "LeftUpperArm",
    "LeftLowerArm",
    "LeftHand",
    "RightUpperArm",
    "RightLowerArm",
    "RightHand"
}
 
-- UPDATED FUNCTION: Added scale offset to closest point calculation
local function getClosestPointOnPart(part, rayOrigin, rayDirection)
    local partPos = part.Position
    local partSize = part.Size
 
    local relative = partPos - rayOrigin
    local dot = relative:Dot(rayDirection.Unit)
    local pointOnRay = rayOrigin + rayDirection.Unit * dot
 
    local localPoint = part.CFrame:PointToObjectSpace(pointOnRay)
    local clampedLocal = Vector3.new(
        math_clamp(localPoint.X, -partSize.X/2, partSize.X/2),
        math_clamp(localPoint.Y, -partSize.Y/2, partSize.Y/2),
        math_clamp(localPoint.Z, -partSize.Z/2, partSize.Z/2)
    )
    
    local closestPoint = part.CFrame:PointToWorldSpace(clampedLocal)
    
    -- ADDED: Apply scale offset if configured
    local scale = shared.script['Silent Aim']['Target']['Closest Point']['Point Scale']
    if scale and scale > 0 then
        local mouseDir = (pointOnRay - closestPoint).Unit
        closestPoint = closestPoint + (mouseDir * scale)
    end
    
    return closestPoint
end
 
-- ==================== FOV CIRCLE ====================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = shared.script['Silent Aim']['FOV']['Color']
FOVCircle.Thickness = shared.script['Silent Aim']['FOV']['Thickness']
FOVCircle.Filled = false
FOVCircle.Transparency = shared.script['Silent Aim']['FOV']['Transparency']
FOVCircle.Radius = shared.script['Silent Aim']['FOV']['Size']
FOVCircle.Visible = false
 
local lastFOVUpdate = 0
local fovUpdateInterval = 0.1
 
-- ==================== PLAYER CACHE ====================
local function updatePlayerCache()
    local currentTime = tick()
    if currentTime - lastPlayerUpdate < playerUpdateInterval then
        return
    end
    
    lastPlayerUpdate = currentTime
    table.clear(cachedPlayers)
    
    local players = Players:GetPlayers()
    for i = 1, #players do
        local player = players[i]
        if player ~= LocalPlayer then
            cachedPlayers[#cachedPlayers + 1] = player
        end
    end
end
 
local function GetClosestPlayerForSilentAim()
    if not shared.script['Silent Aim']['Enabled'] then
        return nil, nil
    end
    
    updatePlayerCache()
    
    local ClosestDistance = math.huge
    local ClosestPart = nil
    local ClosestPoint = nil
    
    local MousePosition = UserInputService:GetMouseLocation()
    local maxDistance = shared.script['Silent Aim']['Max Distance']
    local requireVisible = shared.script['Global']['Conditions']['Visible']
    local fovRadius = shared.script['Silent Aim']['FOV']['Size']
    local hitPartSetting = shared.script['Silent Aim']['Target']['Hit Part']
    local checkKnocked = shared.script['Global']['Conditions']['Knocked']
    
    local localChar = LocalPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
    local localHead = localChar and (localChar:FindFirstChild("Head") or localRoot)
    
    for i = 1, #cachedPlayers do
        local Player = cachedPlayers[i]
        local Character = Player.Character
        
        if not Character then continue end
        
        -- Check if target is knocked and we should ignore knocked players
        if checkKnocked and isKnocked(Character) then continue end
        
        local Humanoid = Character:FindFirstChild("Humanoid")
        if not Humanoid or Humanoid.Health <= 0 then continue end
        
        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        if not RootPart or not localRoot then continue end
        
        local distance = (localRoot.Position - RootPart.Position).Magnitude
        if distance > maxDistance then continue end
        
        local targetPart = nil
        local closestPartDistance = math.huge
        
        -- If Hit Part is set to 'Head', only look for the head
        if hitPartSetting == 'Head' then
            local headPart = Character:FindFirstChild("Head")
            if headPart then
                local scr, ons = Camera:WorldToViewportPoint(headPart.Position)
                if ons then
                    local d = (Vector2_new(scr.X, scr.Y) - MousePosition).Magnitude
                    if d < closestPartDistance and d <= fovRadius then 
                        closestPartDistance = d
                        targetPart = headPart
                    end
                end
            end
        else
            -- For other hit parts or Closest Point, check all R15 parts
            for j = 1, #R15Parts do
                local p = Character:FindFirstChild(R15Parts[j])
                if p then
                    local scr, ons = Camera:WorldToViewportPoint(p.Position)
                    if ons then
                        local d = (Vector2_new(scr.X, scr.Y) - MousePosition).Magnitude
                        if d < closestPartDistance and d <= fovRadius then 
                            closestPartDistance = d
                            targetPart = p
                        end
                    end
                end
            end
        end
        
        if not targetPart then continue end
        
        if requireVisible and localHead then
            if not isPartVisible(localHead.Position, targetPart, {Character}) then
                continue
            end
        end
        
        if closestPartDistance < ClosestDistance then
            ClosestDistance = closestPartDistance
            ClosestPart = targetPart
            
            if hitPartSetting == 'Closest Point' then
                local m = UserInputService:GetMouseLocation()
                local ray = Camera:ViewportPointToRay(m.X, m.Y)
                ClosestPoint = getClosestPointOnPart(targetPart, ray.Origin, ray.Direction)
            end
        end
    end
    
    return ClosestPart, ClosestPoint
end
 
-- ==================== SILENT AIM HOOK ====================
local function setupSilentAimHook()
    local grm = getrawmetatable(game)
    if not grm then return end
    
    local index = grm.__index
    setreadonly(grm, false)
 
    grm.__index = function(self, Index)
        if not checkcaller() and self == Mouse and shared.script['Silent Aim']['Enabled'] then
            if Index == "Hit" or Index == "Target" then
                local TargetPart, TargetPoint = GetClosestPlayerForSilentAim()
                if TargetPart then
                    if TargetPoint then
                        return CFrame_new(TargetPoint)
                    else
                        return CFrame_new(TargetPart.Position)
                    end
                end
            end
        end
        return index(self, Index)
    end
end
 
-- ==================== ESP SYSTEM ====================
local espEnabled = shared.script['Visual']['Enabled']
local espCache = {}
local espConnections = {}
 
-- Use the new color configuration from the table
local function getESPColor(player, isTargetInFOV, isDeadOrKO, isVisible)
    if isDeadOrKO then
        return shared.script['Visual']['Visual Settings']['Configuration']['Knocked Color']
    elseif isTargetInFOV then
        return shared.script['Visual']['Visual Settings']['Configuration']['On-FOV Color']
    else
        return shared.script['Visual']['Visual Settings']['Configuration']['Default Color']
    end
end
 
local function isTargetVisibleForESP(player)
    if not player.Character then return false end
    local head = player.Character:FindFirstChild("Head")
    if not head then return false end
    if not LocalPlayer.Character then return false end
    local localHead = LocalPlayer.Character:FindFirstChild("Head") or LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localHead then return false end
    return isPartVisible(localHead.Position, head, {player.Character})
end
 
local function createESP(player)
    if player == LocalPlayer then return end
    if espCache[player] then return end
    
    local text = Drawing.new("Text")
    text.Visible = false
    text.Center = true
    text.Outline = true
    text.Color = shared.script['Visual']['Visual Settings']['Configuration']['Default Color']
    
    -- Use display name if enabled
    if shared.script['Visual']['Visual Settings']['Display Name'] then
        text.Text = player.DisplayName or player.Name
    else
        text.Text = player.Name
    end
    
    text.Size = 20
    text.Font = 4
    
    espCache[player] = text
    
    local connections = {}
    
    local function cleanup()
        if espCache[player] then
            espCache[player]:Remove()
            espCache[player] = nil
        end
        for _, conn in pairs(connections) do
            conn:Disconnect()
        end
        espConnections[player] = nil
    end
    
    local leaveConn = player.AncestryChanged:Connect(function()
        if not player.Parent then
            cleanup()
        end
    end)
    table.insert(connections, leaveConn)
    
    local function setupCharacterListeners(character)
        if not character then return end
        local charRemovingConn = character.AncestryChanged:Connect(function()
            if not character.Parent then
                if espCache[player] then
                    espCache[player].Visible = false
                end
            end
        end)
        table.insert(connections, charRemovingConn)
        
        -- Update text if display name changes
        if shared.script['Visual']['Visual Settings']['Display Name'] then
            local displayNameConn = player:GetPropertyChangedSignal("DisplayName"):Connect(function()
                if espCache[player] then
                    espCache[player].Text = player.DisplayName or player.Name
                end
            end)
            table.insert(connections, displayNameConn)
        end
    end
    
    if player.Character then
        setupCharacterListeners(player.Character)
    end
    
    local charAddedConn = player.CharacterAdded:Connect(function(character)
        setupCharacterListeners(character)
    end)
    table.insert(connections, charAddedConn)
    
    espConnections[player] = connections
end
 
local lastESPUpdate = 0
local espUpdateInterval = 1/75  -- exactly 99 FPS in calculation
 
local function updateESP()
    if not espEnabled then
        for _, text in pairs(espCache) do
            text.Visible = false
        end
        return
    end
    
    local currentTime = tick()
    if currentTime - lastESPUpdate < espUpdateInterval then
        return
    end
    lastESPUpdate = currentTime
    
    local silentAimPart = GetClosestPlayerForSilentAim()
    local silentAimPlayer = nil
    if silentAimPart then
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and silentAimPart:IsDescendantOf(player.Character) then
                silentAimPlayer = player
                break
            end
        end
    end
    
    for player, text in pairs(espCache) do
        if player and player.Character then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if not rootPart then
                text.Visible = false
                continue
            end
            
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local isDead = humanoid and humanoid.Health <= 0
            local isKO = isKnocked(player.Character)
            local isDeadOrKO = isDead or isKO
            
            local position3D
            if isDeadOrKO then
                position3D = rootPart.Position
            else
                local lowestPosition = rootPart.Position.Y
                
                local leftFoot = player.Character:FindFirstChild("LeftFoot")
                local rightFoot = player.Character:FindFirstChild("RightFoot")
                local leftLowerLeg = player.Character:FindFirstChild("LeftLowerLeg")
                local rightLowerLeg = player.Character:FindFirstChild("RightLowerLeg")
                
                if leftFoot then
                    lowestPosition = math_min(lowestPosition, leftFoot.Position.Y)
                end
                if rightFoot then
                    lowestPosition = math_min(lowestPosition, rightFoot.Position.Y)
                end
                if leftLowerLeg then
                    lowestPosition = math_min(lowestPosition, leftLowerLeg.Position.Y)
                end
                if rightLowerLeg then
                    lowestPosition = math_min(lowestPosition, rightLowerLeg.Position.Y)
                end
                
                position3D = Vector3.new(rootPart.Position.X, lowestPosition - 2, rootPart.Position.Z)
            end
            
            local position, onScreen = Camera:WorldToViewportPoint(position3D)
            
            if onScreen then
                text.Position = Vector2_new(position.X, position.Y)
                text.Visible = true
                text.Size = 20
                
                local isVisible = isTargetVisibleForESP(player)
                local isTargetInFOV = (silentAimPlayer == player)
                
                text.Color = getESPColor(player, isTargetInFOV, isDeadOrKO, isVisible)
                
                -- Update text if display name changes
                if shared.script['Visual']['Visual Settings']['Display Name'] then
                    text.Text = player.DisplayName or player.Name
                else
                    text.Text = player.Name
                end
            else
                text.Visible = false
            end
        else
            text.Visible = false
        end
    end
end
 
local function initializeESP()
    for player, text in pairs(espCache) do
        if text then
            text:Remove()
        end
    end
    
    for player, connections in pairs(espConnections) do
        for _, conn in pairs(connections) do
            conn:Disconnect()
        end
    end
    
    espCache = {}
    espConnections = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        createESP(player)
    end
    
    Players.PlayerAdded:Connect(function(player)
        createESP(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        if espCache[player] then
            espCache[player]:Remove()
            espCache[player] = nil
        end
        if espConnections[player] then
            for _, conn in pairs(espConnections[player]) do
                conn:Disconnect()
            end
            espConnections[player] = nil
        end
    end)
end
 
-- ==================== CAMLOCK SYSTEM ====================
local target = nil
local isLocked = false
local renderConnection = nil
 
local function getKeyCodeFromString(keyString)
    local keyUpper = keyString:upper()
    local keyMap = {
        ["Q"] = Enum.KeyCode.Q, ["E"] = Enum.KeyCode.E, ["R"] = Enum.KeyCode.R,
        ["T"] = Enum.KeyCode.T, ["F"] = Enum.KeyCode.F, ["G"] = Enum.KeyCode.G,
        ["C"] = Enum.KeyCode.C, ["V"] = Enum.KeyCode.V, ["X"] = Enum.KeyCode.X,
        ["Z"] = Enum.KeyCode.Z, ["LEFTALT"] = Enum.KeyCode.LeftAlt,
        ["RIGHTALT"] = Enum.KeyCode.RightAlt, ["LEFTCONTROL"] = Enum.KeyCode.LeftControl,
        ["RIGHTCONTROL"] = Enum.KeyCode.RightControl, ["LEFTSHIFT"] = Enum.KeyCode.LeftShift,
        ["RIGHTSHIFT"] = Enum.KeyCode.RightShift, ["SPACE"] = Enum.KeyCode.Space,
        ["CAPSLOCK"] = Enum.KeyCode.CapsLock, ["TAB"] = Enum.KeyCode.Tab,
    }
    
    if #keyUpper == 1 and keyUpper:match("[A-Z]") then
        return Enum.KeyCode[keyUpper]
    end
    
    return keyMap[keyUpper] or Enum.KeyCode.C
end
 
local CamlockKeyCode = getKeyCodeFromString(shared.script['Global']['Keybind']['Camlock'])
 
local lastCamlockUpdate = 0
local camlockUpdateInterval = 0.01
 
local function getClosestTarget()
    local closest = nil
    local closestDistance = math.huge
    local maxDistance = shared.script['Camlock']['Max Distance']
    local requireVisible = shared.script['Global']['Conditions']['Visible']
    local checkKnocked = shared.script['Global']['Conditions']['Knocked']
    local checkSelfKnocked = shared.script['Global']['Conditions']['Self Knocked']
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local humanoid = character:FindFirstChild("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local head = character:FindFirstChild("Head")
            
            if not humanoid or humanoid.Health <= 0 then
                continue
            end
            
            if checkKnocked and isKnocked(character) then
                continue
            end
            
            if rootPart and LocalPlayer.Character then
                local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not localRoot then continue end
                
                local distance = (localRoot.Position - rootPart.Position).Magnitude
                if distance > maxDistance then
                    continue
                end
                
                if requireVisible then
                    local localHead = LocalPlayer.Character:FindFirstChild("Head") or localRoot
                    local isVisible = isPartVisible(localHead.Position, head or rootPart, {character})
                    if not isVisible then
                        continue
                    end
                end
                
                local screenPoint, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                
                if onScreen then
                    local mousePos = Vector2_new(Mouse.X, Mouse.Y)
                    local targetPos = Vector2_new(screenPoint.X, screenPoint.Y)
                    local screenDistance = (mousePos - targetPos).Magnitude
                    
                    if screenDistance < closestDistance and screenDistance < 500 then
                        closestDistance = screenDistance
                        closest = {
                            Player = player,
                            Character = character,
                            RootPart = rootPart,
                            Head = head,
                        }
                    end
                end
            end
        end
    end
    
    return closest
end
 
local function updateCamlock()
    local currentTime = tick()
    if currentTime - lastCamlockUpdate < camlockUpdateInterval then
        return
    end
    lastCamlockUpdate = currentTime
    
    if not shared.script['Camlock']['Enabled'] or not isLocked then
        return
    end
    
    if LocalPlayer.Character and shared.script['Global']['Conditions']['Self Knocked'] and isKnocked(LocalPlayer.Character) then
        isLocked = false
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
        target = nil
        return
    end
    
    if not target or not target.Character or not target.RootPart then
        target = getClosestTarget()
        if not target then
            isLocked = false
            if renderConnection then
                renderConnection:Disconnect()
                renderConnection = nil
            end
            return
        end
    end
    
    local humanoid = target.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        isLocked = false
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
        target = nil
        return
    end
    
    if shared.script['Global']['Conditions']['Knocked'] and isKnocked(target.Character) then
        isLocked = false
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
        target = nil
        return
    end
    
    if shared.script['Global']['Conditions']['Visible'] then
        if LocalPlayer.Character then
            local localHead = LocalPlayer.Character:FindFirstChild("Head") or LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetPart = target.Head or target.RootPart
            if localHead and targetPart then
                local isVisible = isPartVisible(localHead.Position, targetPart, {target.Character})
                if not isVisible then
                    isLocked = false
                    if renderConnection then
                        renderConnection:Disconnect()
                        renderConnection = nil
                    end
                    target = nil
                    return
                end
            end
        end
    end
    
    if LocalPlayer.Character then
        local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if localRoot and target.RootPart then
            local distance = (localRoot.Position - target.RootPart.Position).Magnitude
            if distance > shared.script['Camlock']['Max Distance'] then
                isLocked = false
                if renderConnection then
                    renderConnection:Disconnect()
                    renderConnection = nil
                end
                target = nil
                return
            end
        end
    end
    
    local targetPart = nil
    local hitPartSetting = shared.script['Camlock']['Target']['Hit Part']
    
    if hitPartSetting == 'Head' then
        targetPart = target.Head or target.RootPart
    elseif hitPartSetting == 'RootPart' then
        targetPart = target.RootPart
    else
        targetPart = target.Character:FindFirstChild(hitPartSetting) or target.RootPart
    end
    
    if not targetPart then
        targetPart = target.RootPart
    end
    
    local cameraPosition = Camera.CFrame.Position
    local predictedPosition = targetPart.Position
    
    if shared.script['Camlock']['Target']['Prediction'] then
        local velocity = target.RootPart.Velocity
        predictedPosition = predictedPosition + Vector3.new(
            velocity.X * shared.script['Camlock']['Target']['Prediction']['X'],
            velocity.Y * shared.script['Camlock']['Target']['Prediction']['Y'],
            velocity.Z * shared.script['Camlock']['Target']['Prediction']['X']
        )
    end
    
    local direction = (predictedPosition - cameraPosition).Unit
    local targetCFrame = CFrame_new(cameraPosition, cameraPosition + direction)
    
    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, shared.script['Camlock']['Target']['Snappiness'])
end
 
local function toggleCamlock()
    if not shared.script['Camlock']['Enabled'] then
        return
    end
    
    if LocalPlayer.Character and shared.script['Global']['Conditions']['Self Knocked'] and isKnocked(LocalPlayer.Character) then
        return
    end
    
    isLocked = not isLocked
    
    if isLocked then
        target = getClosestTarget()
        
        if not target then
            isLocked = false
            return
        end
        
        if not renderConnection then
            renderConnection = RunService.RenderStepped:Connect(updateCamlock)
        end
    else
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
        target = nil
    end
end
 
-- ==================== INPUT HANDLER ====================
local function handleInput(input, gameProcessed)
    if gameProcessed then return end
    
    local key = input.KeyCode
    
    if key == Enum.KeyCode[shared.script['Global']['Keybind']['Visual']] then
        espEnabled = not espEnabled
        if not espEnabled then
            for _, text in pairs(espCache) do
                text.Visible = false
            end
        end
    
    elseif key == Enum.KeyCode[shared.script['Global']['Keybind']['Camlock']] then
        toggleCamlock()
    
    elseif key == Enum.KeyCode[shared.script['Global']['Keybind']['Speed']] then
        isSpeedEnabled = not isSpeedEnabled
        toggleSpeedConnection()
    end
end
 
-- ==================== MAIN UPDATE LOOP ====================
local lastMainUpdate = 0
local mainUpdateInterval = 0.016
 
local function mainUpdate()
    local currentTime = tick()
    if currentTime - lastMainUpdate < mainUpdateInterval then
        return
    end
    lastMainUpdate = currentTime
    
    if currentTime - lastFOVUpdate >= fovUpdateInterval then
        lastFOVUpdate = currentTime
        FOVCircle.Visible = shared.script['Silent Aim']['FOV']['Visible'] and shared.script['Silent Aim']['Enabled']
        if FOVCircle.Visible then
            FOVCircle.Position = UserInputService:GetMouseLocation()
        end
    end
    
    updateESP()
end
 
-- ==================== INITIALIZATION ====================
local function initialize()
    UserInputService.InputBegan:Connect(handleInput)
    initializeESP()
    setupSilentAimHook()
    
    -- Initialize visual headless
    if headlessEnabled and LocalPlayer.Character then
        setupVisualHeadless(LocalPlayer.Character)
    end
    
    -- Initialize speed
    toggleSpeedConnection()
    
    RunService.Heartbeat:Connect(mainUpdate)
    
    LocalPlayer.AncestryChanged:Connect(function()
        if not LocalPlayer.Parent then
            -- Clean up ESP
            for player, text in pairs(espCache) do
                if text then
                    text:Remove()
                end
            end
            
            -- Clean up FOV circle
            if FOVCircle then
                FOVCircle:Remove()
            end
            
            -- Clean up camlock
            if renderConnection then
                renderConnection:Disconnect()
            end
            
            -- Clean up speed
            if speedConnection then
                speedConnection:Disconnect()
                speedConnection = nil
            end
            
            -- Clean up visual headless
            cleanupVisualHeadless()
        end
    end)
end
 
if LocalPlayer.Character then
    initialize()
else
    LocalPlayer.CharacterAdded:Wait()
    initialize()
end
 
return {
    toggleVisuals = function()
        espEnabled = not espEnabled
    end,
    
    toggleCamlock = toggleCamlock,
    
    toggleSpeed = function()
        isSpeedEnabled = not isSpeedEnabled
        toggleSpeedConnection()
    end,
    
    toggleHeadless = toggleVisualHeadless,
    
    setSpeed = function(speed)
        shared.script['Speed']['Speed Modifier']['Value'] = speed
        if isSpeedEnabled then
            updateSpeed()
        end
    end,
    
    setSilentAimFOV = function(radius)
        shared.script['Silent Aim']['FOV']['Size'] = radius
    end,
    
    setSilentAimHitPart = function(part)
        shared.script['Silent Aim']['Target']['Hit Part'] = part
    end,
    
    setSilentAimClosestPointScale = function(scale)
        shared.script['Silent Aim']['Target']['Closest Point']['Point Scale'] = scale
    end,
    
    setSilentAimFOVVisible = function(visible)
        shared.script['Silent Aim']['FOV']['Visible'] = visible
    end,
    
    setSilentAimVisibleCheck = function(enabled)
        shared.script['Global']['Conditions']['Visible'] = enabled
    end,
    
    setSilentAimMaxDistance = function(distance)
        shared.script['Silent Aim']['Max Distance'] = distance
    end,
    
    setCamlockSnappiness = function(snappiness)
        shared.script['Camlock']['Target']['Snappiness'] = snappiness
    end,
    
    setCamlockHitPart = function(part)
        shared.script['Camlock']['Target']['Hit Part'] = part
    end,
    
    setCamlockPrediction = function(x, y)
        shared.script['Camlock']['Target']['Prediction']['X'] = x
        shared.script['Camlock']['Target']['Prediction']['Y'] = y
    end,
    
    setCamlockVisibleCheck = function(enabled)
        shared.script['Global']['Conditions']['Visible'] = enabled
    end,
    
    setCamlockMaxDistance = function(distance)
        shared.script['Camlock']['Max Distance'] = distance
    end,
    
    setKnockedCheck = function(enabled)
        shared.script['Global']['Conditions']['Knocked'] = enabled
    end,
    
    setSelfKnockedCheck = function(enabled)
        shared.script['Global']['Conditions']['Self Knocked'] = enabled
    end,
    
    setSpreadMod = function(enabled, amount)
        shared.script['SpreadMod']['BulletSpread']['Enabled'] = enabled
        if amount then
            shared.script['SpreadMod']['BulletSpread']['Amount'] = amount
        end
    end,
    
    getSpreadModStatus = function()
        return {
            enabled = shared.script['SpreadMod']['BulletSpread']['Enabled'],
            amount = shared.script['SpreadMod']['BulletSpread']['Amount']
        }
    end,
    
    getStatus = function()
        local silentAimTarget, _ = GetClosestPlayerForSilentAim()
        local silentAimTargetName = "None"
        if silentAimTarget then
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character and silentAimTarget:IsDescendantOf(player.Character) then
                    silentAimTargetName = player.DisplayName or player.Name
                    break
                end
            end
        end
        
        return {
            visuals = {
                enabled = espEnabled,
                playerCount = #Players:GetPlayers() - 1,
                headless = headlessEnabled,
                displayName = shared.script['Visual']['Visual Settings']['Display Name']
            },
            camlock = {
                locked = isLocked,
                target = target and (target.Player.DisplayName or target.Player.Name) or "None",
                hitPart = shared.script['Camlock']['Target']['Hit Part'],
                snappiness = shared.script['Camlock']['Target']['Snappiness'],
                visibleCheck = shared.script['Global']['Conditions']['Visible'],
                knockedCheck = shared.script['Global']['Conditions']['Knocked'],
                selfKnockedCheck = shared.script['Global']['Conditions']['Self Knocked'],
                maxDistance = shared.script['Camlock']['Max Distance']
            },
            silentAim = {
                enabled = shared.script['Silent Aim']['Enabled'],
                target = silentAimTargetName,
                fov = shared.script['Silent Aim']['FOV']['Size'],
                hitPart = shared.script['Silent Aim']['Target']['Hit Part'],
                closestPointScale = shared.script['Silent Aim']['Target']['Closest Point']['Point Scale'],
                fovVisible = shared.script['Silent Aim']['FOV']['Visible'],
                visibleCheck = shared.script['Global']['Conditions']['Visible'],
                knockedCheck = shared.script['Global']['Conditions']['Knocked'],
                maxDistance = shared.script['Silent Aim']['Max Distance']
            },
            speed = {
                enabled = isSpeedEnabled,
                speed = shared.script['Speed']['Speed Modifier']['Value']
            },
            spreadMod = {
                enabled = shared.script['SpreadMod']['BulletSpread']['Enabled'],
                amount = shared.script['SpreadMod']['BulletSpread']['Amount']
            },
            conditions = {
                knocked = shared.script['Global']['Conditions']['Knocked'],
                selfKnocked = shared.script['Global']['Conditions']['Self Knocked'],
                visible = shared.script['Global']['Conditions']['Visible']
            }
        }
    end
}
