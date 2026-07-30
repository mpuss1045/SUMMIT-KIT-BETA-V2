--[[

  /$$$$$$                                  /$$                     /$$       /$$                       /$$$$$$$$        /$$$$$$$                      
 /$$__  $$                                | $$                    | $$      | $$                      | $$_____/       | $$__  $$                     
| $$  \__/  /$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$    /$$$$$$   /$$$$$$$      | $$$$$$$  /$$   /$$      | $$    /$$$$$$$$| $$  \ $$  /$$$$$$  /$$    /$$
| $$       /$$__  $$ /$$__  $$ |____  $$|_  $$_/   /$$__  $$ /$$__  $$      | $$__  $$| $$  | $$      | $$$$$|____ /$$/| $$  | $$ /$$__  $$|  $$  /$$/
| $$      | $$  \__/| $$$$$$$$  /$$$$$$$  | $$    | $$$$$$$$| $$  | $$      | $$  \ $$| $$  | $$      | $$__/   /$$$$/ | $$  | $$| $$$$$$$$ \  $$/$$/ 
| $$    $$| $$      | $$_____/ /$$__  $$  | $$ /$$| $$_____/| $$  | $$      | $$  | $$| $$  | $$      | $$     /$$__/  | $$  | $$| $$_____/  \  $$$/  
|  $$$$$$/| $$      |  $$$$$$$|  $$$$$$$  |  $$$$/|  $$$$$$$|  $$$$$$$      | $$$$$$$/|  $$$$$$$      | $$    /$$$$$$$$| $$$$$$$/|  $$$$$$$   \  $/   
 \______/ |__/       \_______/ \_______/   \___/   \_______/ \_______/      |_______/  \____  $$      |__/   |________/|_______/  \_______/    \_/    
                                                                                       /$$  | $$                                                      
                                                                                      |  $$$$$$/                                                      
                                                                                       \______/                                                       
]]

local Tool = script.Parent
local Players = game:GetService("Players")

local SPEED_BOOST = 37 -- Tambahan walkspeed
local DEFAULT_WALKSPEED = 16 -- Walkspeed default Roblox

local currentCharacter = nil
local savedSpeed = nil

local function Equipped()
    
    currentCharacter = Tool.Parent
    local humanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
    
    if humanoid then
        savedSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = savedSpeed + SPEED_BOOST
        
    end
end

local function Unequipped()
    
    if currentCharacter then
        local humanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
        
        if humanoid then
            humanoid.WalkSpeed = savedSpeed or DEFAULT_WALKSPEED; savedSpeed = nil
            
        end
    end
    
    currentCharacter = nil
end

Tool.Equipped:Connect(Equipped)
Tool.Unequipped:Connect(Unequipped)