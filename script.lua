-- loadstring(game:HttpGet('https://raw.githubusercontent.com/Gl1tchl-4r/7m_material_finder/refs/heads/main/obf.lua'))()

repeat wait() until game:IsLoaded() and game.Players.LocalPlayer and game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Main (minimal)")

task.spawn(function ()
    local args = {
        "SetTeam",
        "Marines"
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer(unpack(args))
end)

spawn(function ()
    for i,v in pairs(getconnections(game.Players.LocalPlayer.Idled)) do
        v:Disable()
    end
end)

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local RunService = game:GetService("RunService")
local isTweening = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function tpWorld(_world)
    local world = nil
    if _world == 2 then world = "TravelDressrosa"
    elseif _world == 3 then world = "TravelZou"
    end
    game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer(world)
end

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    hrp = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    isTweening = false
    if getgenv().startTween then
        getgenv().startTween:Cancel()
    end
    workspace:FindFirstChild("TweenPart"):Destroy()
end)

RunService.Heartbeat:Connect(function ()
    pcall(function ()
        if isTweening and character and workspace:FindFirstChild("TweenPart") then
            hrp.CFrame = workspace.TweenPart.CFrame
        end
    end)
end)

local function creatTweenPart()
    local part = Instance.new("Part")
    part.Size = Vector3.new(1, 1, 1)
    part.Anchored = true
    part.CanCollide = false
    part.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
    part.Transparency = 1
    part.Name = "TweenPart"
    part.Parent = workspace
    return part
end

local function tp(pos)
    isTweening = false
    character.HumanoidRootPart.CFrame = pos
end

local function tween(targetCFrame)
    local TweenPart = workspace:FindFirstChild("TweenPart") or creatTweenPart()
    TweenPart.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame

    if getgenv().startTween then
        getgenv().startTween:Cancel()
    end

    local distance = (targetCFrame.Position - TweenPart.Position).Magnitude
    
    if distance < 50 then
        tp(targetCFrame)
        return
    end

    local TweenService = game:GetService("TweenService")

    local tweenInfo = TweenInfo.new(distance / 300, Enum.EasingStyle.Linear)
    
    isTweening = true

    getgenv().startTween = TweenService:Create(TweenPart, tweenInfo, {CFrame = targetCFrame})
    getgenv().startTween:Play()
    getgenv().startTween.Completed:Wait()

end

local function tween_mob(targetPosition, mob)
    local hrp = mob:FindFirstChild("HumanoidRootPart")
    local humanoid = mob:FindFirstChild("Humanoid")
    if not humanoid or not hrp then return end
    
    for _, part in pairs(mob:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end

    hrp.Anchored = false
    humanoid.WalkSpeed = 350
    
    humanoid:MoveTo(targetPosition.Position)

end

local Net = require(ReplicatedStorage.Modules.Net)
local RegisterAttack = Net:RemoteEvent("RegisterAttack", true)
local RegisterHit = Net:RemoteEvent("RegisterHit", true)
local sessionId = tostring(player.UserId):sub(2,4) .. tostring(coroutine.running()):sub(11,15)

task.spawn(function()
    RegisterHit:FireServer(sessionId)
end)

local function getEnemies(range)
    local targets = {}
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return targets end
    
    for _, folder in {workspace.Enemies, workspace.Characters} do
        for _, enemy in pairs(folder:GetChildren()) do
            if enemy == player.Character then continue end
            local root = enemy:FindFirstChild("HumanoidRootPart")
            local hum = enemy:FindFirstChild("Humanoid")
            if root and hum and hum.Health > 0 and (root.Position - hrp.Position).Magnitude <= range then
                table.insert(targets, enemy)
            end
        end
    end
    return targets
end

local function attack()
    local char = player.Character
    if not char or not char:FindFirstChildOfClass("Tool") then return end
    
    local enemies = getEnemies(55)
    if #enemies == 0 then return end
    
    local hitList = {}
    local mainPart = nil
    
    local priorityParts = {"Head", "UpperTorso", "HumanoidRootPart", "RightHand", "LeftHand"}
    
    for _, enemy in ipairs(enemies) do
        local chosen = nil
        for _, name in ipairs(priorityParts) do
            chosen = enemy:FindFirstChild(name)
            if chosen then break end
        end
        if not chosen then chosen = enemy:FindFirstChild("HumanoidRootPart") end
        
        if chosen then
            table.insert(hitList, {enemy, chosen})
            if not mainPart then mainPart = chosen end
        end
    end
    
    if not mainPart then return end

    if not char:FindFirstChild("HasBuso") then
        ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
    end

    RegisterAttack:FireServer(-math.huge)
    RegisterHit:FireServer(mainPart, hitList, nil, sessionId)
    
    task.delay(0.025, function()
        RegisterHit:FireServer(true, nil, nil, sessionId)
    end)
end

spawn(function()
    while task.wait() do
        if player.Character then
            attack()
        end
    end
end)

local function checkItem(itemList_)
    local InventoryController = require(ReplicatedStorage.Controllers.UI.Inventory)
    local ItemReplication = require(ReplicatedStorage.Util.ItemReplication)
    
    local count_ = 0

    for _, item in ipairs(InventoryController:GetTiles()) do
        local itemId = item.ItemId
        local uid = item.NetworkedUID
        local count = ItemReplication.Quantity.readClient(itemId, uid) or 0

        for _, target in ipairs(itemList_) do
            if itemId == target.id then
                count_ = count
            end
        end
    end

    return count_

end

local function equipTool(typeTool)
    pcall(function()
        local backpack = game:GetService("Players").LocalPlayer.Backpack:GetChildren()
        for _, v in pairs(backpack) do
            if v:IsA("Tool") and (v.ToolTip == typeTool or v.Name == typeTool) then
                humanoid:EquipTool(v)
            end
        end
    end)
end

local function getConnectBoss(_name)

    for _, eliteModel in pairs(_name) do
        if ReplicatedStorage:FindFirstChild(eliteModel) then
            return ReplicatedStorage:FindFirstChild(eliteModel)
        elseif workspace.Enemies:FindFirstChild(eliteModel) then
            return workspace.Enemies:FindFirstChild(eliteModel)
        end
    end
    return
end

local function getConnectEnemy(_name)
    if not hrp then return nil end

    local enemySpawns = workspace._WorldOrigin.EnemySpawns:GetChildren()
    local enemySpawned = workspace.Enemies:GetChildren()
    local enemiesList = _name
    local closestTarget = nil
    local closestDistance = math.huge

    for _, enemy in pairs(enemySpawned) do
        for _, enemyName in pairs(enemiesList) do
            if string.find(enemy.Name, enemyName) and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                local targetHrp = enemy:FindFirstChild("HumanoidRootPart")
                if targetHrp then
                    local dist = (targetHrp.Position - hrp.Position).Magnitude
                    if dist < closestDistance then
                        closestDistance = dist
                        closestTarget = enemy
                    end
                end
            end
        end
    end

    if not closestTarget then
        for _, spawnPoint in pairs(enemySpawns) do
            for _, enemyName in pairs(enemiesList) do
                if string.find(spawnPoint.Name, enemyName) then
                    local dist = (spawnPoint.CFrame.Position - hrp.Position).Magnitude
                    if dist < closestDistance then
                        closestDistance = dist
                        closestTarget = spawnPoint
                    end
                end
            end
        end
    end

    if closestTarget then
        closestTarget:SetAttribute("inUse", true)
        if closestTarget:FindFirstChild("HumanoidRootPart") then
            closestTarget.HumanoidRootPart.CanCollide = false
        end
        return closestTarget
    end

    return nil
end

local function bringMob(enemyObject)
    local connectingEnemy = enemyObject
    local enemySpawned = workspace.Enemies:GetChildren()
    local allowned = {}

    for _, v in pairs(enemySpawned) do
        if not v:GetAttribute("inUse") and v.Name == connectingEnemy.Name then
            table.insert(allowned, v)
        end
    end

    for _, _v in pairs(allowned) do
        tween_mob(connectingEnemy:FindFirstChild("HumanoidRootPart"), _v)
    end

    return
end

local function getBlackPack(item)
    return player.Backpack:FindFirstChild(item) or character:FindFirstChild(item)
end

local function collectChest()
    if not character then
        return
    end
    local CollectionService = game:GetService("CollectionService")
    local Position = character:GetPivot().Position
    local Chests = CollectionService:GetTagged("_ChestTagged")
    local Distance, Nearest = math.huge, nil
    for i = 1, #Chests do
        local Chest = Chests[i]
        local Magnitude = (Chest:GetPivot().Position - Position).Magnitude
        if (not Chest:GetAttribute("IsDisabled") or Chest.CanTouch) and Magnitude < Distance then
            Distance = Magnitude
            Nearest = Chest
        end
    end

    if not Nearest or not Nearest.Parent then return end

    if Nearest then
        humanoid.Sit = false
        tween(Nearest:GetPivot())
        humanoid.Jump = true
    end
end

local collectedJobIds = {}
local ServerBrowserRemote = ReplicatedStorage:WaitForChild("__ServerBrowser")

local function getJobId()

        local done = 0
        
        for i = 1, 100 do
            task.delay(i * 1/50, function()
                local success, data = pcall(function()
                    return ServerBrowserRemote:InvokeServer(i)
                end)
                
                if success and data then
                    for jobId, serverData in pairs(data) do
                        table.insert(collectedJobIds, jobId)
                    end
                end
                
                done = done + 1
            end)
        end
        
        -- รอจนครบ 100 chunks
        repeat task.wait() until done >= 100

end

local function hopServer()
    if not collectedJobIds[1] then getJobId() end
    local jobId = math.random(1, #collectedJobIds)
    ServerBrowserRemote:InvokeServer("teleport", collectedJobIds[jobId])
end

-- เช็คว่ามี Fist of Darkness หรือยัง
local function hasFOD()
    return getBlackPack("Fist of Darkness")
end

-- function นี้ใช้หา dark flag
local function Get_Dark_Flagment()
    if game:GetService("Lighting"):GetAttribute("MAP") ~= "Sea2" then tpWorld(2) end
    local Darkbeard = getConnectEnemy({"Darkbeard"})
    if Darkbeard then
        repeat task.wait()
            if Darkbeard and Darkbeard:FindFirstChild("Humanoid") then
                tween(CFrame.new(Darkbeard.HumanoidRootPart.Position) * CFrame.new(0,30,0))
                equipTool("Melee")
            else
                break
            end
        until not Darkbeard or humanoid.Health <= 0
    elseif hasFOD() then
        repeat task.wait()
            equipTool("Fist of Darkness")
            tween(CFrame.new(3776.93921, 14.6768322, -3499.31567, 0.609171271, -2.72086922e-08, -0.793038666, 7.68717001e-08, 1, 2.47394496e-08, 0.793038666, -7.60327907e-08, 0.609171271))
        until workspace.Enemies:FindFirstChild("Darkbeard") or not hasFOD()
        task.wait(1)
    else
        local startTime = os.clock()
        local timeLimit = 90

        repeat task.wait()
            collectChest()
        until hasFOD() or (os.clock() - startTime) >= timeLimit or Darkbeard

        if (os.clock() - startTime) >= timeLimit and not hasFOD() then
            while not hasFOD() do
                task.wait(0.3)
                hopServer()
            end
        end

    end

end

local function Get_Vampire_Fang()
    if game:GetService("Lighting"):GetAttribute("MAP") ~= "Sea2" then tpWorld(2) end
    local targetMons = {"Vampire"}
    pcall(function()
        local anemy = getConnectEnemy(targetMons)
        local _anemyPos;
        if anemy:IsA("Part") then -- หาตำแหน่งที่แท้จริงเด้อ
            _anemyPos = anemy.Position
        else
            _anemyPos = nil
        end
        repeat task.wait()
            tween(CFrame.new(_anemyPos or anemy.HumanoidRootPart.Position) * CFrame.new(0,30,0))
            equipTool("Melee")
            spawn(function()
                bringMob(anemy)
            end)
        until anemy.Humanoid.Health <= 0
    end)
end

local function Get_Demonic_Wisp()
    if game:GetService("Lighting"):GetAttribute("MAP") ~= "Sea3" then tpWorld(3) end
    local targetMons = {"Demonic Soul"}
    pcall(function()
        local anemy = getConnectEnemy(targetMons)
        local _anemyPos;
        if anemy:IsA("Part") then -- หาตำแหน่งที่แท้จริงเด้อ
            _anemyPos = anemy.Position
        else
            _anemyPos = nil
        end
        repeat task.wait()
            tween(CFrame.new(_anemyPos or anemy.HumanoidRootPart.Position) * CFrame.new(0,30,0))
            equipTool("Melee")
            spawn(function()
                bringMob(anemy)
            end)
        until anemy.Humanoid.Health <= 0
    end)
end

local function Buy_7m()
    if game:GetService("Lighting"):GetAttribute("MAP") ~= "Sea3" then tpWorld(3) end
    tween(CFrame.new(-16516.1328125, 23.38727569580078, -189.69615173339844))
    task.wait(0.5)
    warn("Done: Waiting to buy 7M")
end

local function Main()

    if checkItem({{id = 598}}) < 2 then -- หาหนวดดำ
        Get_Dark_Flagment()
    elseif checkItem({{id = 559}}) < 20 then -- หาเขี้ยว
        Get_Vampire_Fang()
    elseif checkItem({{id = 601}}) < 20 then -- หาลูกไฟ
        Get_Demonic_Wisp()
    else
        Buy_7m()
        task.wait(5)
    end

end

task.wait(5)
while task.wait() do
    Main()
end