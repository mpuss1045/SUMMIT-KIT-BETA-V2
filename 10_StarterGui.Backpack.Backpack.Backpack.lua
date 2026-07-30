local NumberOfSlots = 0

local SG = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

SG:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false)


local BackpackFrame = script.Parent
local GUI = BackpackFrame.Parent.Parent
local Container = BackpackFrame.Container
local Slots = {}
local CurrentSlot = nil

local SlotTemplate = script.Slot
local function CreateSlot()
    NumberOfSlots = #Container:GetChildren()
    local new = SlotTemplate:Clone()
    new.Name = NumberOfSlots
    new.MouseEnter:Connect(function()
        CurrentSlot = new
    end)
    new.MouseLeave:Connect(function()
        if CurrentSlot == new then
            if UIS.TouchEnabled then
               task.wait()
            end
            CurrentSlot = nil
        end
    end)
    new.Parent = Container
    return new
end

local function RemoveSlot(Slot)
    if Slot.Name ~= NumberOfSlots then
        local c = tonumber(Slot.Name)
        for _,v in pairs(Container:GetChildren()) do
            local n = tonumber(v.Name)
            if n and n > c then
                v.Name = n-1
            end
        end
    end
    Slot:Destroy()
    NumberOfSlots = #Container:GetChildren() - 1
end

local Player = game.Players.LocalPlayer
local Backpack = Player.Backpack
local Character = Player.Character
local Hum

local SlotTracker = {}
local Holding = nil
local HoldStart = 0

local function IsMovement(input)
    return input == Enum.UserInputType.MouseMovement or input == Enum.UserInputType.Touch
end

local ToolRecord = {}
local InToolRecord = {}
local Equipped

local MouseButton1 = Enum.UserInputType.MouseButton1
local NulPos = UDim2.new(.5,0,.5,0)

local MoveCon

local HoldDeb = false
local function CreateToolSlot(Tool)
    local new = script.Button:Clone()
    local Texture = Tool.TextureId
    if Texture and Texture ~= '' then
        new.ImageLabel.Image = Texture
        new.ImageLabel.Visible = true
    else
        new.Label.Text = string.upper(Tool.Name)
    end
    new.MouseButton1Down:Connect(function()
        if not HoldDeb then
            HoldDeb = true
            if not Holding and not MoveCon then
                HoldStart = tick()
                local n = HoldStart
                Holding = new
                wait(.02)
                if n == HoldStart and Holding == new then
                    MoveCon = UIS.InputChanged:Connect(function(input)
                        if Holding and Holding == new then
                            if IsMovement(input.UserInputType) then
                                local input = input.Position
                                new.Parent = GUI
                                new.Position = UDim2.new(0,input.X,0,input.Y+32)
                            end
                        else
                            new.Position = NulPos
                            MoveCon:Disconnect()
                            MoveCon = nil
                        end
                    end)
                end
            end
            wait(.1)
            HoldDeb = false
        end
    end)
    return new
end


local function Equip(Tool)
    if Equipped and Equipped == Tool then
        Hum:UnequipTools()
    elseif Equipped then
        Hum:UnequipTools()
        wait(.05)
        Hum:EquipTool(Tool)
    else
        Hum:EquipTool(Tool)
    end
end

local function OnHoldEnd()
    local new = Holding
    if new then
        Holding = nil
        if MoveCon then
            MoveCon:Disconnect()
            MoveCon = nil
        end
        local dt = tick() - HoldStart
        local OldSlot,CS = SlotTracker[new],CurrentSlot
        if (OldSlot and CS == OldSlot) then
            new.Parent = CS
            local Tool = InToolRecord[new]
            Equip(Tool)
        elseif dt >= .02 then --dragged
            if CS then
                local old = Slots[CS]
                if old then
                    local last = SlotTracker[new]
                    if last then
                        SlotTracker[old] = last
                        old.Parent = last
                        Slots[last] = old
                    else
                        warn("Backpack: Slot lost")
                    end
                end
                SlotTracker[new] = CS
                Slots[CS] = new
                new.Parent = CS
            else
                if Equipped and Equipped == InToolRecord[new]  then
                    Hum:UnequipTools()
                end
                new.Parent = OldSlot
            end
        end
        new.Position = NulPos
    end
end

UIS.InputEnded:Connect(function(k)
    if k.UserInputType == MouseButton1 then
        OnHoldEnd()
    end
end)

UIS.TouchEnded:Connect(OnHoldEnd)

local function Add(Tool,new)
    ToolRecord[Tool] = new
    InToolRecord[new] = Tool
    local Slot = CreateSlot()
    Slots[Slot] = new
    SlotTracker[new] = Slot
    new.Parent = Slot
    Tool:GetPropertyChangedSignal("Parent"):Connect(function()
        local Parent = Tool.Parent
        if Parent ~= Character and Parent ~= Backpack and new then
            local new = ToolRecord[Tool]
            local OldSlot = SlotTracker[new]
            if OldSlot then
                Slots[OldSlot] = nil
                SlotTracker[new] = nil
            end
            if new then
                new:Destroy()
            end
            ToolRecord[Tool] = nil
            RemoveSlot(Slot)
        end
    end)
end

for _,Tool in pairs(Backpack:GetDescendants()) do
    if Tool.ClassName == "Tool" then
        local new = CreateToolSlot(Tool)
        Add(Tool,new)
    end
end

Backpack.DescendantAdded:Connect(function(Tool)
    if Tool.ClassName == "Tool" and not ToolRecord[Tool] then
        local new = CreateToolSlot(Tool)
        Add(Tool,new)
    end
end)


if not Character or not Character.Parent then
    Character = Player.CharacterAdded:Wait()
end
Hum = Character:WaitForChild("Humanoid")

Character.ChildAdded:Connect(function(tool)
    if tool.ClassName == "Tool" and not Equipped then
        Equipped = tool
        local slot = ToolRecord[tool]
        if not slot then
            slot = CreateToolSlot(tool)
            Add(tool,slot)
            task.wait()
            --Hum:UnequipTools()
        end
        TweenService:Create(slot.Anim,TweenInfo.new(.1),{Size = UDim2.new(1,0,1,0)}):Play()
    end
end)

Character.ChildRemoved:Connect(function(tool)
    if Equipped == tool then
        Equipped = nil
        local slot = ToolRecord[tool]
        if slot then
            TweenService:Create(slot.Anim,TweenInfo.new(.1),{Size = UDim2.new(0,0,0,0)}):Play()
        end
    end
end)



local Binds = {Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four,Enum.KeyCode.Five,Enum.KeyCode.Six,Enum.KeyCode.Seven,Enum.KeyCode.Eight,Enum.KeyCode.Nine,Enum.KeyCode.Zero}
UIS.InputBegan:Connect(function(k,g)
    if not g then
        for i = 1,NumberOfSlots do
            if k.KeyCode == Binds[i] then
                local Slot = Container:FindFirstChild(i)
                if Slot then
                    local new = Slots[Slot]
                    if new then
                        local Tool = InToolRecord[new]
                        Equip(Tool)
                    end
                end
                break
            end
        end
    end
end)