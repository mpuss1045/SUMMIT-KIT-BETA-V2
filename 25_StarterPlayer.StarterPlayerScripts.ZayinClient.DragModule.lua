local DragModule = {}
local UIS = game:GetService("UserInputService")

-- Guard: simpan frame yang sudah dibuat draggable
local registered = {}

function DragModule.makeDraggable(frame, handle)
    -- Cegah double-connect pada frame yang sama
    if registered[frame] then return end
    registered[frame] = true

    handle = handle or frame
    local dragging  = false
    local dragStart = nil
    local startPos  = nil
    local moveConn  = nil

    local function update(input)
        local delta  = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        local vp      = workspace.CurrentCamera.ViewportSize
        local absSize = frame.AbsoluteSize
        local x = math.clamp(newPos.X.Offset, 0, vp.X - absSize.X)
        local y = math.clamp(newPos.Y.Offset, 0, vp.Y - absSize.Y)
        frame.Position = UDim2.new(0, x, 0, y)
    end

    local beginConn = handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position

            -- Cleanup move listener lama sebelum buat baru
            if moveConn then moveConn:Disconnect(); moveConn = nil end

            moveConn = UIS.InputChanged:Connect(function(inp)
                if dragging and (
                    inp.UserInputType == Enum.UserInputType.MouseMovement or
                    inp.UserInputType == Enum.UserInputType.Touch) then
                    update(inp)
                end
            end)

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if moveConn then moveConn:Disconnect(); moveConn = nil end
                end
            end)
        end
    end)

    -- Cleanup otomatis saat frame dihancurkan
    frame.Destroying:Connect(function()
        registered[frame] = nil
        if moveConn   then moveConn:Disconnect();   moveConn   = nil end
        if beginConn  then beginConn:Disconnect();  beginConn  = nil end
    end)
end

return DragModule