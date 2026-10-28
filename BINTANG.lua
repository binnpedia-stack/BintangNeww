-- ============================================================
-- BINTANGX6LOCC — FULL LOGIC & UI FIX
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local PathService = game:GetService("PathfindingService")
local VIM = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local DISCORD_LINK = "" 

local CFG = {
    KillerESP = true, SurvivorESP = true, GenESP = true, GateESP = true, HookESP = false,
    PalletESP = false, VaultESP = false, PumpkinESP = false, TrapESP = false,
    ESPName = true, ESPDistance = true, ESPProgres = true, ESPRange = 999999, StreamerMode = false,
    ColorKiller = Color3.fromRGB(255, 60, 60), ColorSurvivor = Color3.fromRGB(80, 255, 120),
    ColorSurvivorInjured = Color3.fromRGB(255, 120, 60), ColorSurvivorKnocked = Color3.fromRGB(255, 180, 60),
    ColorGenerator = Color3.fromRGB(0, 200, 255), ColorHook = Color3.fromRGB(255, 150, 0),
    ColorPallet = Color3.fromRGB(200, 160, 80), ColorVault = Color3.fromRGB(180, 180, 180),
    ColorGate = Color3.fromRGB(255, 220, 0), ColorPumpkin = Color3.fromRGB(255, 140, 0),
    ColorTrap = Color3.fromRGB(200, 0, 0),
    
    AutoSkillCheck = true, SkillCheckMode = "Instant", GenBoost = false, PerfectRate = 100,
    AutoParry = false, ParryMode = "Agresif", ParryRadius = 14, AntiFakeHit = true, FrenzyParry = false,
    
    RevolverSilent = false, RevolverTarget = "Killer", RevolverPredict = true, RevolverFOVRadius = 200, RevolverBypass = false,
    
    SpearSilent = false, SpearTrajectory = false, SpearPredict = true, SpearFOVRadius = 240,
    SpearShowFOV = true, SpearFOVColor = "Red",
    
    AutoFarmKiller = false, InfiniteLunge = false, DoubleTap = false, AttackCooldown = false,
    StalkerNoCD = false, HiddenNoCD = false,
    
    AutoFarmSurvivor = false, AutoPumpkin = false, AutoUnhook = false, AutoFlee = false,
    AutoCrouch = false, InstantHeal = false, SpeedBoost = false, SpeedMult = 1.3, NoclipVP = false, AlwaysFastVault = false,
    
    FullBright = false, NoFog = false, CleanSky = false, RemoveDOF = false, RTXGraphics = false, CinematicDOF = false
}

-- ============================================================
-- ENGINE LOGIC
-- ============================================================
local function isKiller(player)
    return (player.Team and player.Team.Name == "Killer") or (player:GetAttribute("Role") == "Killer") or (player:GetAttribute("IsKiller") == true)
end

local function getGeneratorProgress(resultValue)
    local rp = resultValue:GetAttribute("RepairProgress") or (resultValue:FindFirstChild("RepairProgress") and resultValue.RepairProgress.Value)
    if not rp then return 0 end
    local num = tonumber(rp)
    if num then return (num <= 1.01 and num > 0) and math.round(num * 100) or math.round(num) end
    return 0
end

local cachedGenerators, cachedPumpkins = {}, {}
local function scanMapObjects()
    cachedGenerators, cachedPumpkins = {}, {}
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    for _, v in ipairs(map:GetDescendants()) do
        if v.Name == "Generator" and v:IsA("Model") then table.insert(cachedGenerators, v) end
        if v.Name:lower():find("pumpkin") and v.Name ~= "Pumpkins" then table.insert(cachedPumpkins, v) end
    end
end

-- ESP
local ActiveESP = { Players = {}, Map = {} }
local function createPlayerESP(player)
    if ActiveESP.Players[player] then return ActiveESP.Players[player] end
    local hl = Instance.new("Highlight"); hl.Enabled = false; hl.Parent = workspace
    local bb = Instance.new("BillboardGui"); bb.AlwaysOnTop = true; bb.StudsOffset = Vector3.new(0, 3.5, 0); bb.Size = UDim2.new(0, 180, 0, 42); bb.Enabled = false; bb.Parent = workspace
    local name = Instance.new("TextLabel", bb); name.Size = UDim2.new(1,0,0.5,0); name.BackgroundTransparency = 1; name.Font = Enum.Font.Code; name.TextSize = 12; name.TextStrokeTransparency = 0.4
    local info = Instance.new("TextLabel", bb); info.Size = UDim2.new(1,0,0.5,0); info.Position = UDim2.new(0,0,0.5,0); info.BackgroundTransparency = 1; info.Font = Enum.Font.Code; info.TextSize = 11; info.TextStrokeTransparency = 0.5
    ActiveESP.Players[player] = { hl = hl, bb = bb, name = name, info = info }
    return ActiveESP.Players[player]
end

local function updatePlayersESP()
    local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local killer = isKiller(plr)
                if (killer and CFG.KillerESP) or (not killer and CFG.SurvivorESP) then
                    local e = createPlayerESP(plr)
                    local d = (myHRP.Position - hrp.Position).Magnitude
                    if d <= CFG.ESPRange then
                        local roleColor = killer and CFG.ColorKiller or CFG.ColorSurvivor
                        if plr.Character:GetAttribute("Knocked") then roleColor = CFG.ColorSurvivorKnocked
                        elseif hum.Health < hum.MaxHealth then roleColor = CFG.ColorSurvivorInjured end
                        e.hl.Adornee = plr.Character; e.hl.FillColor = roleColor; e.hl.OutlineColor = roleColor; e.hl.Enabled = true
                        e.bb.Adornee = hrp; e.bb.Enabled = true
                        
                        if CFG.StreamerMode then
                            e.name.Text = killer and "KILLER" or ("Survivor " .. string.sub(plr.Name, 1, 3))
                            e.name.Visible = true
                        else
                            e.name.Text = CFG.ESPName and plr.DisplayName or ""
                            e.name.Visible = CFG.ESPName
                        end
                        e.name.TextColor3 = roleColor
                        e.info.Text = CFG.ESPDistance and string.format("[%dm]", math.floor(d)) or ""
                        e.info.Visible = CFG.ESPDistance
                    else e.hl.Enabled = false; e.bb.Enabled = false end
                else
                    local e = ActiveESP.Players[plr]; if e then e.hl.Enabled = false; e.bb.Enabled = false end
                end
            end
        end
    end
end

local function scanMapESP()
    for i, e in pairs(ActiveESP.Map) do e.hl:Destroy(); e.bb:Destroy(); ActiveESP.Map[i] = nil end
    local map = workspace:FindFirstChild("Map"); if not map then return end
    for _, inst in ipairs(map:GetDescendants()) do
        local n = inst.Name; local role = nil
        if n == "Generator" and inst:IsA("Model") then role = "GEN"
        elseif n == "Hook" or n == "HookPoint" then role = "HOOK"
        elseif n == "Pallet" and inst:IsA("Model") then role = "PALLET"
        elseif n == "Window" or n == "Vault" then role = "VAULT"
        elseif n == "ExitLever" then role = "GATE"
        elseif n == "BearTrap" then role = "TRAP"
        elseif n:lower():find("pumpkin") and n ~= "Pumpkins" then role = "PUMPKIN" end
        if role then
            local show = (role == "GEN" and CFG.GenESP) or (role == "HOOK" and CFG.HookESP) or (role == "PALLET" and CFG.PalletESP) or (role == "VAULT" and CFG.VaultESP) or (role == "GATE" and CFG.GateESP) or (role == "TRAP" and CFG.TrapESP) or (role == "PUMPKIN" and CFG.PumpkinESP)
            if show then
                local color = CFG["Color" .. string.lower(role)] or Color3.fromRGB(255,255,255)
                local hl = Instance.new("Highlight"); hl.FillTransparency = 0.6; hl.OutlineTransparency = 0.1; hl.FillColor = color; hl.OutlineColor = color; hl.Enabled = true; hl.Adornee = inst; hl.Parent = workspace
                local bb = Instance.new("BillboardGui"); bb.AlwaysOnTop = true; bb.StudsOffset = Vector3.new(0, 3.5, 0); bb.Size = UDim2.new(0, 120, 0, 30); bb.Enabled = true
                bb.Adornee = inst:IsA("Model") and (inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")) or inst; bb.Parent = workspace
                local lbl = Instance.new("TextLabel", bb); lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1; lbl.TextColor3 = color; lbl.Font = Enum.Font.Code; lbl.TextSize = 11; lbl.TextStrokeTransparency = 0.4; lbl.Text = "[" .. role .. "]"
                ActiveESP.Map[inst] = { hl = hl, bb = bb, label = lbl, role = role }
            end
        end
    end
end

local function updateMapESPText()
    for inst, data in pairs(ActiveESP.Map) do
        if not inst.Parent then data.hl:Destroy(); data.bb:Destroy(); ActiveESP.Map[inst] = nil
        else
            if data.role == "GEN" and CFG.ESPProgres then
                local prog = getGeneratorProgress(inst)
                data.label.Text = string.format("[GEN: %d%%]", prog)
                local c = prog >= 100 and Color3.fromRGB(80,255,120) or CFG.ColorGenerator
                data.label.TextColor3 = c; data.hl.FillColor = c; data.hl.OutlineColor = c
            end
        end
    end
end

-- Skill Check
local lastFire = 0
local function getSkillGui()
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end
    local g = pg:FindFirstChild("SkillCheckPromptGui") or pg:FindFirstChild("SkillCheckPromptGui-con")
    if g and g:FindFirstChild("Check") and g.Check.Visible then return g end
    return nil
end

local function fireSkillCheck(isTrap)
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    local mob = pg and (pg:FindFirstChild("Survivor-mob") or pg:FindFirstChild("Survivor"))
    local ctrl = mob and mob:FindFirstChild("Controls")
    local action = ctrl and ctrl:FindFirstChild("action")
    if action and firesignal then pcall(firesignal, action.MouseButton1Down); pcall(firesignal, action.MouseButton1Click) end
    local key = isTrap and Enum.KeyCode.ButtonL1 or Enum.KeyCode.Space
    pcall(function() VIM:SendKeyEvent(true, key, false, game); task.wait(0.01); VIM:SendKeyEvent(false, key, false, game) end)
end

local function handleSkillCheck()
    if not CFG.AutoSkillCheck then return end
    if tick() - lastFire < 0.1 then return end
    local gui = getSkillGui(); if not gui then return end
    local checkObj = gui:FindFirstChild("Check"); if not checkObj then return end
    local lineObj = checkObj:FindFirstChild("Line")
    local goalObj = checkObj:FindFirstChild("TrapPerfect") or checkObj:FindFirstChild("TrapGoal") or checkObj:FindFirstChild("Goal")
    if not lineObj or not goalObj then return end
    local isTrap = gui.Name == "SkillCheckPromptGui-con" or checkObj:FindFirstChild("TrapPerfect") ~= nil
    
    if CFG.GenBoost or CFG.SkillCheckMode == "Instant" then
        pcall(function() lineObj.Rotation = goalObj.Rotation end)
        task.wait(0.01); lastFire = tick(); fireSkillCheck(isTrap)
    elseif CFG.SkillCheckMode == "Normal" then
        local diff = (goalObj.Rotation % 360 - lineObj.Rotation % 360 + 180) % 360 - 180
        if math.abs(diff) <= 8 then lastFire = tick(); fireSkillCheck(isTrap) end
    elseif CFG.SkillCheckMode == "Hybrid" then
        if math.random(1, 100) <= (CFG.PerfectRate or 100) then
            pcall(function() lineObj.Rotation = goalObj.Rotation end)
            task.wait(0.01); lastFire = tick(); fireSkillCheck(isTrap)
        else
            local diff = (goalObj.Rotation % 360 - lineObj.Rotation % 360 + 180) % 360 - 180
            if math.abs(diff) <= 8 then lastFire = tick(); fireSkillCheck(isTrap) end
        end
    elseif CFG.SkillCheckMode == "Legit" then
        local diff = (goalObj.Rotation % 360 - lineObj.Rotation % 360 + 180) % 360 - 180
        if math.abs(diff) <= 5 then lastFire = tick(); task.wait(math.random(0.05, 0.15)); fireSkillCheck(isTrap) end
    end
end

-- Parry
local parryAnimIds = {["71008020992570"]=true, ["72742711718023"]=true, ["72908958549833"]=true, ["73681849513551"]=true, ["73923929500477"]=true, ["74968262036854"]=true, ["75857500533792"]=true, ["76385865186777"]=true, ["76503974441748"]=true, ["76744850905644"]=true, ["77081789642514"]=true, ["78432063483146"]=true}
local function fireParry()
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    local s = pg and (pg:FindFirstChild("Survivor") or pg:FindFirstChild("Survivor-mob"))
    local a = s and s:FindFirstChild("Controls") and s.Controls:FindFirstChild("action")
    if a and firesignal then pcall(firesignal, a.MouseButton1Down); pcall(firesignal, a.MouseButton1Click) end
end

local function hookKiller(plr)
    if not plr or plr == LP or not plr.Character then return end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    local an = hum and hum:FindFirstChildOfClass("Animator")
    if an and not an:GetAttribute("X6_Hooked") then
        an:SetAttribute("X6_Hooked", true)
        an.AnimationPlayed:Connect(function(t)
            if not CFG.AutoParry then return end
            local id = tostring(t.Animation and t.Animation.AnimationId or ""):match("%d+")
            if id and parryAnimIds[id] then
                local my = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                local k = plr.Character:FindFirstChild("HumanoidRootPart")
                if my and k and (my.Position - k.Position).Magnitude <= CFG.ParryRadius then
                    if CFG.ParryMode == "Safety" and t.TimePosition > 0.4 then return end
                    if CFG.AntiFakeHit and t.TimePosition < 0.1 then return end
                    if CFG.ParryMode == "Legit" then task.delay(math.random(0.1, 0.2), fireParry) else fireParry() end
                end
            end
        end)
    end
end

-- FOV Visual
local function createFOVCircle(name, color, radius, enabled)
    local sg = Instance.new("ScreenGui", LP:FindFirstChildOfClass("PlayerGui"))
    sg.Name = "VD_" .. name .. "FOV"; sg.IgnoreGuiInset = true; sg.ResetOnSpawn = false
    local f = Instance.new("Frame", sg)
    f.Size = UDim2.new(0, radius*2, 0, radius*2); f.Position = UDim2.new(0.5, 0, 0.5, 0); f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.BackgroundTransparency = 1; Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", f); stroke.Color = color; stroke.Thickness = 1.5
    sg.Enabled = enabled
    return sg, f, stroke
end

local revolverFOV, revolverFOVFrame, revolverStroke = createFOVCircle("Revolver", Color3.fromRGB(0,255,255), CFG.RevolverFOVRadius, false)
local veilFOV, veilFOVFrame, veilStroke = createFOVCircle("Veil", Color3.fromRGB(255,0,0), CFG.SpearFOVRadius, false)

RunService.RenderStepped:Connect(function()
    revolverFOV.Enabled = CFG.RevolverSilent
    if revolverFOVFrame then revolverFOVFrame.Size = UDim2.new(0, CFG.RevolverFOVRadius*2, 0, CFG.RevolverFOVRadius*2) end
    veilFOV.Enabled = CFG.SpearSilent and CFG.SpearShowFOV
    if veilFOVFrame then 
        veilFOVFrame.Size = UDim2.new(0, CFG.SpearFOVRadius*2, 0, CFG.SpearFOVRadius*2) 
        local c = CFG.SpearFOVColor
        local col = c == "Red" and Color3.fromRGB(255,0,0) or c == "Cyan" and Color3.fromRGB(0,255,255) or c == "Green" and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,255,0)
        veilStroke.Color = col
    end
end)

local function setupHooks()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if method == "FireServer" and typeof(self) == "Instance" then
            if self.Name == "VaultEvent" and CFG.AlwaysFastVault then
                if args[2] == false then args[2] = true end
                return oldNamecall(self, unpack(args))
            end
            if self.Name == "Fire" and self.Parent and self.Parent.Name:lower():find("twist") then
                if CFG.RevolverSilent then
                    local target = nil; local best = CFG.RevolverFOVRadius
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LP and plr.Character then
                            local isTarget = (CFG.RevolverTarget == "Killer" and isKiller(plr)) or (CFG.RevolverTarget == "Survivor" and not isKiller(plr)) or (CFG.RevolverTarget == "SCP" and plr.Name:lower():find("scp"))
                            if isTarget then
                                local head = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
                                if head then
                                    local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                                    if onScreen then
                                        local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                                        if d < best then best = d; target = head end
                                    end
                                end
                            end
                        end
                    end
                    if target and args[2] then args[2] = (target.Position - Camera.CFrame.Position).Unit end
                end
                return oldNamecall(self, unpack(args))
            end
            if self.Name == "SpearThrow" and CFG.SpearSilent then
                local target = nil; local best = CFG.SpearFOVRadius
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LP and plr.Character and not isKiller(plr) then
                        local head = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
                        if head then
                            local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                            if onScreen then
                                local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                                if d < best then best = d; target = head end
                            end
                        end
                    end
                end
                if target and args[1] then args[1] = { Origin = Camera.CFrame.Position, Direction = (target.Position - Camera.CFrame.Position).Unit } end
                return oldNamecall(self, unpack(args))
            end
        end
        return oldNamecall(self, ...)
    end)
end

-- Loops
local repairEvent, leverEvent = nil, nil
task.spawn(function()
    local remotes = RS:WaitForChild("Remotes", 5)
    if remotes then
        repairEvent = remotes:WaitForChild("Generator", 2) and remotes.Generator:WaitForChild("RepairEvent", 2)
        leverEvent = remotes:WaitForChild("Exit", 2) and remotes.Exit:WaitForChild("LeverEvent", 2)
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if not CFG.AutoFarmSurvivor then continue end
        local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not myHRP then continue end
        if not CFG.AutoPumpkin then
            for _, gen in ipairs(cachedGenerators) do
                if gen and gen.Parent and not gen:GetAttribute("Completed") then
                    local bp = gen:FindFirstChildWhichIsA("BasePart")
                    if bp and (myHRP.Position - bp.Position).Magnitude < 10 then
                        if repairEvent then pcall(function() repairEvent:FireServer(bp, true, nil, "X6", LP.Character) end) end
                        break
                    end
                end
            end
        else
            for _, p in ipairs(cachedPumpkins) do
                if p and p.Parent then
                    local bp = p:FindFirstChildWhichIsA("BasePart")
                    if bp and (myHRP.Position - bp.Position).Magnitude < 7 then
                        local crush = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Events") and RS.Remotes.Events:FindFirstChild("Halloween") and RS.Remotes.Events.Halloween:FindFirstChild("Crush")
                        if crush then pcall(function() crush:FireServer(p) end) end
                        VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game); task.wait(0.05); VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                        break
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.15) do
        if not CFG.AutoFarmKiller then continue end
        local char = LP.Character; if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character and not isKiller(plr) then
                local thrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if thrp and (hrp.Position - thrp.Position).Magnitude < 15 then
                    hrp.CFrame = CFrame.new(thrp.Position - thrp.CFrame.LookVector * 1.2, thrp.Position)
                    local attacks = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Attacks")
                    if attacks then
                        if attacks:FindFirstChild("Lunge") then attacks.Lunge:FireServer() end
                        if attacks:FindFirstChild("BasicAttack") then attacks.BasicAttack:FireServer() end
                    end
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if CFG.SpeedBoost then
        local char = LP.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0 and hum.MoveDirection.Magnitude > 0.05 then
            local target = (char:GetAttribute("Speed") or 16) * CFG.SpeedMult
            local dir = Vector3.new(hum.MoveDirection.X, 0, hum.MoveDirection.Z).Unit
            hrp.AssemblyLinearVelocity = Vector3.new(dir.X * target, hrp.AssemblyLinearVelocity.Y, dir.Z * target)
        end
    end
    if CFG.NoclipVP then local char = LP.Character; if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end
    if CFG.FullBright then Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.Ambient = Color3.fromRGB(255,255,255); Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255) end
    if CFG.NoFog then Lighting.FogStart = 1e6; Lighting.FogEnd = 1e6 end
    if CFG.CleanSky then for _, v in ipairs(Lighting:GetChildren()) do if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("Clouds") then v:Destroy() end end end
end)

RunService.RenderStepped:Connect(function()
    pcall(updatePlayersESP)
    pcall(updateMapESPText)
    pcall(handleSkillCheck)
end)

task.spawn(function()
    pcall(setupHooks)
    task.spawn(function() while true do task.wait(3); pcall(scanMapObjects); pcall(scanMapESP); for _, p in ipairs(Players:GetPlayers()) do if isKiller(p) then hookKiller(p) end end end end)
end)

-- ============================================================
-- UI RENDER (FORCED FIX)
-- ============================================================
local Colors = { Bg = Color3.fromRGB(0, 0, 0), Sidebar = Color3.fromRGB(5, 5, 5), Card = Color3.fromRGB(10, 10, 10), Hover = Color3.fromRGB(20, 20, 20), Stroke = Color3.fromRGB(0, 255, 0), Accent = Color3.fromRGB(0, 255, 0), Text = Color3.fromRGB(200, 200, 200), TextDim = Color3.fromRGB(100, 100, 100), Font = Enum.Font.Code }

local function buildUI()
    local sg = Instance.new("ScreenGui")
    sg.Name = "BintangX6LocHUB"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() sg.Parent = gethui() end)
    if not sg.Parent then sg.Parent = LP:WaitForChild("PlayerGui") end

    local main = Instance.new("Frame", sg)
    main.Size = UDim2.new(0, 520, 0, 380)
    main.Position = UDim2.new(0.5, -260, 0.5, -190)
    main.BackgroundColor3 = Colors.Bg
    main.BorderSizePixel = 1
    main.BorderColor3 = Colors.Stroke
    main.Active = true
    main.Visible = true
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 4)

    local header = Instance.new("Frame", main); header.Size = UDim2.new(1, 0, 0, 30); header.BackgroundColor3 = Colors.Sidebar; header.BorderSizePixel = 1; header.BorderColor3 = Colors.Stroke
    local title = Instance.new("TextLabel", header); title.Size = UDim2.new(1, -10, 1, 0); title.Position = UDim2.new(0, 10, 0, 0); title.BackgroundTransparency = 1; title.Text = "root@BINTANGX6LOCC:~# ./inject --target=VD"; title.TextColor3 = Colors.Accent; title.Font = Colors.Font; title.TextSize = 12; title.TextXAlignment = Enum.TextXAlignment.Left

    local side = Instance.new("Frame", main); side.Size = UDim2.new(0, 150, 1, -30); side.Position = UDim2.new(0, 0, 0, 30); side.BackgroundColor3 = Colors.Sidebar; side.BorderSizePixel = 1; side.BorderColor3 = Colors.Stroke
    local tabScroll = Instance.new("ScrollingFrame", side); tabScroll.Size = UDim2.new(1, 0, 1, 0); tabScroll.BackgroundTransparency = 1; tabScroll.BorderSizePixel = 0; tabScroll.ScrollBarThickness = 2
    local tabList = Instance.new("UIListLayout", tabScroll); tabList.Padding = UDim.new(0, 2); tabList.SortOrder = Enum.SortOrder.LayoutOrder

    local content = Instance.new("Frame", main); content.Size = UDim2.new(1, -160, 1, -40); content.Position = UDim2.new(0, 155, 0, 35); content.BackgroundTransparency = 1
    local pages = {}; local tabButtons = {}
    
    local function makeTab(id, name, order)
        local btn = Instance.new("TextButton", tabScroll); btn.Size = UDim2.new(1, 0, 0, 28); btn.BackgroundColor3 = Colors.Card; btn.BackgroundTransparency = 0.5; btn.BorderSizePixel = 0; btn.Text = "[ ] " .. name; btn.TextColor3 = Colors.TextDim; btn.Font = Colors.Font; btn.TextSize = 12; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.LayoutOrder = order
        btn.MouseButton1Click:Connect(function()
            for _, tb in pairs(tabButtons) do tb.BackgroundTransparency = 0.5; tb.TextColor3 = Colors.TextDim; tb.Text = "[ ] " .. tb:GetAttribute("TabName") end
            btn.BackgroundTransparency = 0; btn.TextColor3 = Colors.Accent; btn.Text = "[x] " .. name
            for pid, pg in pairs(pages) do pg.Visible = (pid == id) end
        end)
        btn:SetAttribute("TabName", name); tabButtons[id] = btn
    end

    local function makePage(id)
        local f = Instance.new("ScrollingFrame", content); f.Size = UDim2.new(1, 0, 1, 0); f.BackgroundTransparency = 1; f.BorderSizePixel = 0; f.ScrollBarThickness = 2; f.CanvasSize = UDim2.new(0, 0, 0, 0); f.AutomaticCanvasSize = Enum.AutomaticSize.Y; f.Visible = false
        local ll = Instance.new("UIListLayout", f); ll.Padding = UDim.new(0, 4); ll.SortOrder = Enum.SortOrder.LayoutOrder; pages[id] = f
    end

    local function addSection(parent, text)
        local l = Instance.new("TextLabel", parent); l.Size = UDim2.new(1, 0, 0, 20); l.BackgroundTransparency = 1; l.Text = "--- " .. text:upper() .. " ---"; l.TextColor3 = Colors.Accent; l.Font = Colors.Font; l.TextSize = 11; l.TextXAlignment = Enum.TextXAlignment.Left
    end

    local function addToggle(parent, label, key, order, callback)
        local b = Instance.new("TextButton", parent); b.Size = UDim2.new(1, 0, 0, 26); b.BackgroundColor3 = Colors.Card; b.BackgroundTransparency = 0.5; b.BorderSizePixel = 1; b.BorderColor3 = CFG[key] and Colors.Accent or Color3.fromRGB(30,30,30)
        b.Text = (CFG[key] and "[+] " or "[-] ") .. label; b.TextColor3 = CFG[key] and Colors.Accent or Colors.Text; b.Font = Colors.Font; b.TextSize = 11; b.TextXAlignment = Enum.TextXAlignment.Left; b.LayoutOrder = order
        b.MouseButton1Click:Connect(function()
            CFG[key] = not CFG[key]; b.Text = (CFG[key] and "[+] " or "[-] ") .. label; b.TextColor3 = CFG[key] and Colors.Accent or Colors.Text; b.BorderColor3 = CFG[key] and Colors.Accent or Color3.fromRGB(30,30,30)
            if callback then callback(CFG[key]) end
        end)
    end

    local function addSegmented(parent, label, key, options, order)
        local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 0, 46); f.BackgroundColor3 = Colors.Card; f.BackgroundTransparency = 0.5; f.BorderSizePixel = 1; f.BorderColor3 = Color3.fromRGB(30,30,30); f.LayoutOrder = order
        local l = Instance.new("TextLabel", f); l.Size = UDim2.new(1, -10, 0, 18); l.Position = UDim2.new(0, 5, 0, 2); l.BackgroundTransparency = 1; l.Text = label; l.TextColor3 = Colors.Text; l.Font = Colors.Font; l.TextSize = 11; l.TextXAlignment = Enum.TextXAlignment.Left
        local container = Instance.new("Frame", f); container.Size = UDim2.new(1, -10, 0, 20); container.Position = UDim2.new(0, 5, 0, 22); container.BackgroundTransparency = 1
        local ll = Instance.new("UIListLayout", container); ll.FillDirection = Enum.FillDirection.Horizontal; ll.Padding = UDim.new(0, 2); ll.SortOrder = Enum.SortOrder.LayoutOrder
        local buttons = {}
        for i, opt in ipairs(options) do
            local btn = Instance.new("TextButton", container); btn.Size = UDim2.new(1/#options, -2, 1, 0); btn.BackgroundColor3 = CFG[key] == opt and Colors.Accent or Colors.Bg; btn.BorderSizePixel = 1; btn.BorderColor3 = CFG[key] == opt and Colors.Accent or Color3.fromRGB(30,30,30)
            btn.Text = opt; btn.TextColor3 = CFG[key] == opt and Color3.fromRGB(0,0,0) or Colors.Text; btn.Font = Colors.Font; btn.TextSize = 10
            btn.MouseButton1Click:Connect(function()
                CFG[key] = opt; for _, b in pairs(buttons) do b.BackgroundColor3 = Colors.Bg; b.BorderColor3 = Color3.fromRGB(30,30,30); b.TextColor3 = Colors.Text end
                btn.BackgroundColor3 = Colors.Accent; btn.BorderColor3 = Colors.Accent; btn.TextColor3 = Color3.fromRGB(0,0,0)
            end)
            table.insert(buttons, btn)
        end
    end
    
    local function addSlider(parent, label, key, min, max, order)
        local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 0, 40); f.BackgroundColor3 = Colors.Card; f.BackgroundTransparency = 0.5; f.BorderSizePixel = 1; f.BorderColor3 = Color3.fromRGB(30,30,30); f.LayoutOrder = order
        local l = Instance.new("TextLabel", f); l.Size = UDim2.new(1, -10, 0, 14); l.Position = UDim2.new(0, 5, 0, 2); l.BackgroundTransparency = 1; l.Text = label .. " : " .. tostring(CFG[key]); l.TextColor3 = Colors.Text; l.Font = Colors.Font; l.TextSize = 11; l.TextXAlignment = Enum.TextXAlignment.Left
        local bar = Instance.new("Frame", f); bar.Size = UDim2.new(1, -10, 0, 8); bar.Position = UDim2.new(0, 5, 0, 22); bar.BackgroundColor3 = Colors.Bg; bar.BorderSizePixel = 1; bar.BorderColor3 = Colors.Accent
        local fill = Instance.new("Frame", bar); fill.Size = UDim2.new((CFG[key]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Colors.Accent; fill.BorderSizePixel = 0
        local dragging = false
        bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true end end)
        bar.InputEnded:Connect(function() dragging = false end)
        UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1); local v = min + rel * (max - min); CFG[key] = v; fill.Size = UDim2.new(rel, 0, 1, 0); l.Text = label .. " : " .. string.format("%.1f", v) end end)
    end

    local function addButton(parent, text, callback, order, color)
        local b = Instance.new("TextButton", parent); b.Size = UDim2.new(1, 0, 0, 26); b.BackgroundColor3 = color or Colors.Card; b.BorderSizePixel = 1; b.BorderColor3 = Colors.Accent; b.Text = "[ " .. text .. " ]"; b.TextColor3 = Colors.Accent; b.Font = Colors.Font; b.TextSize = 11; b.LayoutOrder = order
        b.MouseButton1Click:Connect(callback)
    end

    makeTab("Home", "HOME", 1)
    makeTab("Survivor", "SURVIVOR_", 2)
    makeTab("Killer", "KILLER_", 3)
    makeTab("ESP", "ESP_VISUAL", 4)

    local hm = makePage("Home")
    addSection(hm, "WELCOME")
    local wl = Instance.new("TextLabel", hm); wl.Size = UDim2.new(1, 0, 0, 40); wl.BackgroundTransparency = 1; wl.Text = "SELAMAT MENIKMATI\nJANGAN LUPA JOIN DISCORD KAMI"; wl.TextColor3 = Colors.Accent; wl.Font = Colors.Font; wl.TextSize = 12
    addButton(hm, "COPY LINK DC", function() if DISCORD_LINK == "" then return end; pcall(function() setclipboard(DISCORD_LINK) end) end, 2)
    addToggle(hm, "Streamer Mode (Hide Name)", "StreamerMode", 3)

    local sv = makePage("Survivor")
    addSection(sv, "SKILL CHECK")
    addToggle(sv, "Auto Skill Check", "AutoSkillCheck", 1)
    addToggle(sv, "Gen Boost (Force Perfect)", "GenBoost", 2)
    addSegmented(sv, "Mode", "SkillCheckMode", {"Instant", "Normal", "Legit", "Hybrid"}, 3)
    addSection(sv, "AUTO PARRY")
    addToggle(sv, "Enable Auto Parry", "AutoParry", 4)
    addSegmented(sv, "Parry Mode", "ParryMode", {"Agresif", "Safety", "Legit"}, 5)
    addToggle(sv, "Anti Fake Hit", "AntiFakeHit", 6)
    addToggle(sv, "Frenzy Parry", "FrenzyParry", 7)
    addSlider(sv, "Parry Radius", "ParryRadius", 6, 25, 8)
    addSection(sv, "REVOLVER (TWIST OF FATE)")
    addToggle(sv, "Silent Aim", "RevolverSilent", 9)
    addSegmented(sv, "Target", "RevolverTarget", {"Killer", "Survivor", "SCP"}, 10)
    addToggle(sv, "Auto Predict", "RevolverPredict", 11)
    addToggle(sv, "Bypass ToF", "RevolverBypass", 12)
    addSection(sv, "AUTO FARM")
    addToggle(sv, "Auto Farm", "AutoFarmSurvivor", 13)
    addToggle(sv, "Auto Pumpkin", "AutoPumpkin", 14)
    addToggle(sv, "Auto Unhook", "AutoUnhook", 15)
    addToggle(sv, "Auto Flee", "AutoFlee", 16)
    addSection(sv, "MODIFIERS")
    addToggle(sv, "Instant Heal", "InstantHeal", 17)
    addToggle(sv, "Speed Boost", "SpeedBoost", 18)
    addSlider(sv, "Speed Multiplier", "SpeedMult", 1, 3, 19)
    addToggle(sv, "Auto Crouch", "AutoCrouch", 20)
    addToggle(sv, "Noclip Vaults", "NoclipVP", 21)

    local kl = makePage("Killer")
    addSection(kl, "FITUR KILLER LAINNYA")
    addToggle(kl, "Auto Farm Killer", "AutoFarmKiller", 1)
    addToggle(kl, "Infinite Lunge", "InfiniteLunge", 2)
    addToggle(kl, "Double Tap", "DoubleTap", 3)
    addToggle(kl, "Attack Cooldown", "AttackCooldown", 4)
    addToggle(kl, "Stalker No CD", "StalkerNoCD", 5)
    addToggle(kl, "Hidden No CD", "HiddenNoCD", 6)
    addSection(kl, "SPEAR VEIL")
    addToggle(kl, "Silent Aim", "SpearSilent", 7)
    addToggle(kl, "Spear Trajectory", "SpearTrajectory", 8)
    addToggle(kl, "Auto Predict", "SpearPredict", 9)
    addToggle(kl, "Show FOV Circle", "SpearShowFOV", 10)
    addSegmented(kl, "FOV Color", "SpearFOVColor", {"Red", "Cyan", "Green", "Yellow"}, 11)
    addSlider(kl, "FOV Radius", "SpearFOVRadius", 50, 500, 12)

    local ep = makePage("ESP")
    addSection(ep, "ESP DLL")
    addToggle(ep, "Killer ESP", "KillerESP", 1)
    addToggle(ep, "Survivor ESP", "SurvivorESP", 2)
    addToggle(ep, "Show Name", "ESPName", 3)
    addToggle(ep, "Show Distance", "ESPDistance", 4)
    addToggle(ep, "Generator", "GenESP", 5)
    addToggle(ep, "Gate", "GateESP", 6)
    addToggle(ep, "Hook", "HookESP", 7)
    addToggle(ep, "Pallet", "PalletESP", 8)
    addToggle(ep, "Vault", "VaultESP", 9)
    addToggle(ep, "Pumpkin", "PumpkinESP", 10)
    addSection(ep, "FULLBRIGHT & SKY")
    addToggle(ep, "Full Bright", "FullBright", 11)
    addToggle(ep, "No Fog", "NoFog", 12)
    addToggle(ep, "Clean Sky", "CleanSky", 13)
    addToggle(ep, "Remove DOF", "RemoveDOF", 14)
    addToggle(ep, "RTX Graphics", "RTXGraphics", 15)
    addToggle(ep, "Cinematic DOF", "CinematicDOF", 16)

    local hideBtn = Instance.new("TextButton", sg); hideBtn.Size = UDim2.new(0, 50, 0, 24); hideBtn.Position = UDim2.new(0, 15, 0, 300); hideBtn.BackgroundColor3 = Colors.Bg; hideBtn.BorderSizePixel = 1; hideBtn.BorderColor3 = Colors.Accent; hideBtn.Text = "HIDE"; hideBtn.TextColor3 = Colors.Accent; hideBtn.Font = Colors.Font; hideBtn.TextSize = 11; hideBtn.AutoButtonColor = false; hideBtn.ZIndex = 5
    hideBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

    local dragging, dragStart, startPos
    main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = i.Position; startPos = main.Position end end)
    main.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - dragStart; main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end end)
    main.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)

    tabButtons["Home"].MouseButton1Click:Fire()
end

task.spawn(function()
    while not LP do task.wait(0.5); LP = Players.LocalPlayer end
    task.spawn(function() pcall(setupHooks) end)
    task.wait(1)
    pcall(buildUI)
end)