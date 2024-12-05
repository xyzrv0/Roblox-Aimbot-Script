local player = game.Players.LocalPlayer
local camera = game.Workspace.CurrentCamera
local userInputService = game:GetService("UserInputService")
local playersService = game:GetService("Players")

local isRightMousePressed = false
local targetPlayer = nil
local lockedOn = false
local toggleEnabled = false  -- New variable to control toggling

-- Create a GUI to show the status of the aimbot
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotStatusGui"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Create a status frame
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(0, 180, 0, 60)  -- Smaller size
statusFrame.Position = UDim2.new(0.5, -90, 0.9, 0)  -- Positioned at the bottom middle of the screen
statusFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statusFrame.BackgroundTransparency = 0.5
statusFrame.BorderSizePixel = 0
statusFrame.Parent = screenGui

-- Add rounded corners to the status frame
local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0.1, 0)
statusCorner.Parent = statusFrame

-- Add a UIStroke for the rainbow outline
local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = 2  -- Adjust thickness as needed
uiStroke.Parent = statusFrame

-- Function to create a rainbow color
local function getRainbowColor()
    local time = tick()  -- Current time
    local r = math.sin(time) * 0.5 + 0.5  -- Red component
    local g = math.sin(time + 2) * 0.5 + 0.5  -- Green component
    local b = math.sin(time + 4) * 0.5 + 0.5  -- Blue component
    return Color3.new(r, g, b)
end

-- Update the UIStroke color to create a rainbow effect
spawn(function()
    while true do
        uiStroke.Color = getRainbowColor()
        wait(0.01)  -- Adjust the speed of color change here
    end
end)

-- Add a label to show the status
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0.5, 0)
statusLabel.Position = UDim2.new(0, 0, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Aimbot Status: Off"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 16
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Parent = statusFrame

-- Add a label to show the hotkey information
local hotkeyLabel = Instance.new("TextLabel")
hotkeyLabel.Size = UDim2.new(1, 0, 0.5, 0)
hotkeyLabel.Position = UDim2.new(0, 0, 0.5, 0)
hotkeyLabel.BackgroundTransparency = 1
hotkeyLabel.Text = "On/Off Key: Left-Ctrl"
hotkeyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hotkeyLabel.TextSize = 14
hotkeyLabel.Font = Enum.Font.Gotham
hotkeyLabel.Parent = statusFrame

-- Function to update the status label
local function updateStatusLabel()
    if toggleEnabled then
        statusLabel.Text = "Aimbot Status: On"
    else
        statusLabel.Text = "Aimbot Status: Off"
        if lockedOn then
            lockedOn = false  -- Stop locking on if toggled off
            targetPlayer = nil  -- Clear the target player
        end
    end
end

-- Toggle aimbot using the Left-Ctrl key
userInputService.InputBegan:Connect(function(input, isProcessed)
    if not isProcessed and input.KeyCode == Enum.KeyCode.LeftControl then
        toggleEnabled = not toggleEnabled  -- Toggle the state
        updateStatusLabel()  -- Update the status label
    end
end)

-- Function to lock the camera rotation to look at the target player's torso
local function lockCameraRotation(targetPlayer)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local targetPosition = targetPlayer.Character.HumanoidRootPart.Position
        local cameraPosition = camera.CFrame.Position
        local lookAtPosition = targetPosition + Vector3.new(0, 2, 0)  -- Adjust the offset if needed
        
        -- Calculate the desired rotation
        local desiredCFrame = CFrame.new(cameraPosition, lookAtPosition)
        
        -- Smoothly interpolate the camera's CFrame to face the target player quickly
        camera.CFrame = camera.CFrame:Lerp(desiredCFrame, 1)  -- Faster lock-on
    end
end

-- Detect when the right mouse button is pressed or released
userInputService.InputBegan:Connect(function(input, isProcessed)
    if not isProcessed and input.UserInputType == Enum.UserInputType.MouseButton2 then  -- Right mouse button
        isRightMousePressed = true
    end
end)

userInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then  -- Right mouse button
        isRightMousePressed = false
        if toggleEnabled then
            lockedOn = false  -- Reset the lock when the right mouse button is released
            targetPlayer = nil  -- Clear the target player
        end
    end
end)

-- Dragging variables
local dragging = false
local dragStartPos = Vector2.new()
local startPos = statusFrame.Position

-- Function to make the frame draggable
statusFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then  -- Left mouse button
        dragging = true
        dragStartPos = input.Position
        startPos = statusFrame.Position
    end
end)

statusFrame.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStartPos
        statusFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

statusFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Continuously check for the right mouse button press and update the camera rotation
while true do
    if toggleEnabled and isRightMousePressed and not lockedOn then
        local closestPlayer = nil
        local smallestAngle = -math.huge  -- Initial value for the smallest dot product

        -- Find the closest player by angle that is not the local player
        for _, target in pairs(playersService:GetPlayers()) do
            if target ~= player and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local targetPosition = target.Character.HumanoidRootPart.Position
                local directionToTarget = (targetPosition - camera.CFrame.Position).unit
                local cameraDirection = camera.CFrame.LookVector

                -- Check if the angle between the vectors is small using dot product
                local dotProduct = cameraDirection:Dot(directionToTarget)
                if dotProduct > math.cos(math.rad(10)) then  -- Adjust for sensitivity
                    if dotProduct > smallestAngle then
                        closestPlayer = target
                        smallestAngle = dotProduct
                    end
                end
            end
        end

        -- Lock the camera rotation onto the closest player if one is found
        if closestPlayer then
            targetPlayer = closestPlayer
            lockedOn = true
            lockCameraRotation(targetPlayer)
        end
    elseif lockedOn and targetPlayer then
        -- If already locked onto a player, keep updating the camera rotation quickly
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            lockCameraRotation(targetPlayer)
        else
            -- If the target's character or HumanoidRootPart is not found, reset lock-on
            lockedOn = false
            targetPlayer = nil
        end
    end

    task.wait(0.01)  -- Faster update rate for quicker response
end
