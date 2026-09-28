local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local StartCFrame
do
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart", 10)
    if hrp then StartCFrame = hrp.CFrame end
end

local IslandPositions = {
    ["Forest"] = Vector3.new(596,68,-328), ["Lake"] = Vector3.new(744,68.5,-408),
    ["Desert"] = Vector3.new(948,69.5,-323), ["Jungle"] = Vector3.new(1188,68.5,-408),
    ["Snow"] = Vector3.new(1492,69,-315), ["Volcano"] = Vector3.new(1882,68,-398),
    ["Abyss Ocean"] = Vector3.new(2280,68,-326), ["Prehistoric"] = Vector3.new(2812,69,-398),
    ["Cosmic"] = Vector3.new(3390,68,-324), ["Cherry Blossom"] = Vector3.new(4028,68.5,-396),
    ["Titan Temple"] = Vector3.new(4796,69.5,-328), ["Light Dark"] = Vector3.new(5660,70,-331)
}
local IslandOrder = {"Forest","Lake","Desert","Jungle","Snow","Volcano","Abyss Ocean","Prehistoric","Cosmic","Cherry Blossom","Titan Temple","Light Dark"}
local SelectedIsland = "Forest"

local Bypass = {
    Enabled=true, InProgress=false, LastChar=nil, OriginalHumanoid=nil, CloneHumanoid=nil,
    _conn=nil, _statusCallback=nil
}
local PROPS_TO_COPY = {
    "WalkSpeed","JumpPower","JumpHeight","UseJumpPower","MaxHealth","Health","AutoRotate",
    "AutoJumpEnabled","BreakJointsOnDeath","CameraOffset","DisplayDistanceType",
    "HealthDisplayDistance","HealthDisplayType","NameDisplayDistance","NameOcclusion",
    "RequiresNeck","WalkJumpPower","HipHeight","RigType","WalkSpeedCheck",
    "EvaluateStateMachine","MaxSlopeAngle","AutomaticScalingEnabled"
}
local STATE_ENUMS = {
    Enum.HumanoidStateType.FallingDown,Enum.HumanoidStateType.Ragdoll,Enum.HumanoidStateType.GettingUp,
    Enum.HumanoidStateType.Landed,Enum.HumanoidStateType.Flying,Enum.HumanoidStateType.Freefall,
    Enum.HumanoidStateType.Seated,Enum.HumanoidStateType.PlatformStanding,Enum.HumanoidStateType.Dead,
    Enum.HumanoidStateType.Physics,Enum.HumanoidStateType.Climbing,Enum.HumanoidStateType.Swimming,
    Enum.HumanoidStateType.Running,Enum.HumanoidStateType.RunningNoPhysics,
    Enum.HumanoidStateType.StrafingNoPhysics,Enum.HumanoidStateType.Jumping
}

local function log(ok,msg)
    warn(string.format("[BYPASS] %s %s",ok and "OK:" or "FAIL:",msg))
    if Bypass._statusCallback then pcall(Bypass._statusCallback,ok,msg) end
end

local function copyProperties(orig,clone)
    for _,prop in ipairs(PROPS_TO_COPY) do
        pcall(function()
            local ok,value=pcall(function() return orig[prop] end)
            if ok and value~=nil then pcall(function() clone[prop]=value end) end
        end)
    end
    pcall(function()
        for k,v in pairs(orig:GetAttributes()) do pcall(function() clone:SetAttribute(k,v) end) end
    end)
    pcall(function()
        local desc=orig:FindFirstChildOfClass("HumanoidDescription")
        if desc then desc:Clone().Parent=clone end
    end)
end

local function captureStates(hum)
    local states={}
    for _,s in ipairs(STATE_ENUMS) do
        local ok,enabled=pcall(function() return hum:GetStateEnabled(s) end)
        if ok then states[s]=enabled end
    end
    local curState
    pcall(function() curState=hum:GetState() end)
    return states,curState
end

local function reapplyStates(hum,states,curState)
    for s,enabled in pairs(states or {}) do pcall(function() hum:SetStateEnabled(s,enabled) end) end
    if curState then pcall(function() hum:ChangeState(curState) end) end
end

function Bypass.Apply(character)
    if not Bypass.Enabled then log(false,"Bypass desabilitado."); return false end
    if Bypass.InProgress then log(false,"Já existe uma execução em andamento."); return false end
    Bypass.InProgress=true
    character=character or LocalPlayer.Character
    if not character then Bypass.InProgress=false; log(false,"Personagem não encontrado."); return false end
    local origHum=character:FindFirstChildOfClass("Humanoid")
    if not origHum then
        local ok=pcall(function() origHum=character:WaitForChild("Humanoid",10) end)
        if not ok or not origHum then Bypass.InProgress=false; log(false,"Humanoid não encontrado (timeout)."); return false end
    end
    local cloneHum
    local okClone=pcall(function() cloneHum=origHum:Clone() end)
    if not okClone or not cloneHum then Bypass.InProgress=false; log(false,"Falha ao clonar Humanoid."); return false end
    local animatorMoved=false
    local animator=origHum:FindFirstChildOfClass("Animator")
    if animator then animatorMoved=pcall(function() animator.Parent=cloneHum end) end
    copyProperties(origHum,cloneHum)
    local states,curState=captureStates(origHum)
    pcall(function() cloneHum.Name="Humanoid" end)
    local okParent=pcall(function() cloneHum.Parent=character end)
    if not okParent then
        if animatorMoved and animator and animator.Parent~=origHum then pcall(function() animator.Parent=origHum end) end
        Bypass.InProgress=false; log(false,"Falha ao parentear clone. Estado restaurado."); return false
    end
    task.wait(.05)
    local okDestroy=pcall(function() origHum:Destroy() end)
    if not okDestroy then
        pcall(function() cloneHum:Destroy() end)
        if animatorMoved and animator and animator.Parent~=origHum then pcall(function() animator.Parent=origHum end) end
        Bypass.InProgress=false; log(false,"Falha ao destruir Humanoid original. Rollback."); return false
    end
    task.wait(.05)
    pcall(function() if Workspace.CurrentCamera then Workspace.CurrentCamera.CameraSubject=cloneHum end end)
    reapplyStates(cloneHum,states,curState)
    Bypass.LastChar=character; Bypass.OriginalHumanoid=origHum; Bypass.CloneHumanoid=cloneHum; Bypass.InProgress=false
    log(true,"Bypass aplicado com sucesso.")
    return true
end
function Bypass.Restore()
    Bypass.LastChar=nil; Bypass.OriginalHumanoid=nil; Bypass.CloneHumanoid=nil
    log(true,"Estado interno limpo.")
end
function Bypass.IsActive()
    return Bypass.CloneHumanoid~=nil and Bypass.CloneHumanoid.Parent~=nil and Bypass.CloneHumanoid.Health>0
end
local function hookCharacter(char) task.wait(.3); if Bypass.Enabled then Bypass.Apply(char) end end
if LocalPlayer.Character then task.spawn(hookCharacter,LocalPlayer.Character) end
Bypass._conn=LocalPlayer.CharacterAdded:Connect(hookCharacter)

local IslandTeleportInProgress=false
local WaitingForIslandPrompt=false
local EmergencyStopped=false
local TeleportRevision=0
local ActiveTeleportThread=nil
local function waitForAnyPromptCompletion()
    local completed=false
    local finished=Instance.new("BindableEvent")
    local connections={}
    local function cleanup()
        for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        table.clear(connections); pcall(function() finished:Destroy() end)
    end
    local function connectPrompt(prompt)
        if not prompt:IsA("ProximityPrompt") then return end
        table.insert(connections,prompt.Triggered:Connect(function(player)
            if not completed and player==LocalPlayer then completed=true; finished:Fire() end
        end))
    end
    for _,object in ipairs(Workspace:GetDescendants()) do connectPrompt(object) end
    table.insert(connections,Workspace.DescendantAdded:Connect(connectPrompt))
    finished.Event:Wait()
    cleanup()
end

local function runIslandTeleport(selectedIsland)
    if EmergencyStopped then return end
    if IslandTeleportInProgress then log(false,"Um teleporte de ilha já está em andamento."); return end
    local destination=IslandPositions[selectedIsland]
    if not destination then log(false,"Posição da ilha não encontrada."); return end
    local character=LocalPlayer.Character
    if not character then log(false,"Personagem não encontrado."); return end
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    local hrp=character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then log(false,"Humanoid ou HumanoidRootPart não encontrado."); return end

    IslandTeleportInProgress=true
    TeleportRevision+=1
    local revision=TeleportRevision

    ActiveTeleportThread=task.spawn(function()
        local success,err=pcall(function()
            local function cancelled()
                return EmergencyStopped or TeleportRevision~=revision
            end

            if not StartCFrame then error("Posição inicial não encontrada.") end
            humanoid:MoveTo(StartCFrame.Position)

            local reached=false
            local moveConnection=humanoid.MoveToFinished:Connect(function(ok) reached=ok end)
            local startTime=os.clock()

            while not reached and os.clock()-startTime<15 do
                if cancelled() then
                    pcall(function() moveConnection:Disconnect() end)
                    return
                end
                task.wait(.1)
                if not character.Parent then break end
                hrp=character:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position-StartCFrame.Position).Magnitude<=6 then reached=true; break end
            end

            pcall(function() moveConnection:Disconnect() end)
            if cancelled() then return end
            if not reached then error("Não foi possível chegar ao início.") end

            task.wait(.15)
            if cancelled() then return end

            hrp=character:FindFirstChild("HumanoidRootPart")
            if not hrp then error("HumanoidRootPart desapareceu.") end
            hrp.CFrame=CFrame.new(IslandPositions.Forest)

            WaitingForIslandPrompt=true
            waitForAnyPromptCompletion()
            WaitingForIslandPrompt=false

            if cancelled() then return end
            task.wait(1.5)
            if cancelled() then return end

            character=LocalPlayer.Character
            hrp=character and character:FindFirstChild("HumanoidRootPart")
            if not hrp then error("HumanoidRootPart não encontrado após o Prompt.") end
            hrp.CFrame=CFrame.new(destination)
            log(true,"Teleportado para "..selectedIsland..".")
        end)

        WaitingForIslandPrompt=false
        if not success and not EmergencyStopped and TeleportRevision==revision then
            log(false,tostring(err))
        end
        if TeleportRevision==revision then
            IslandTeleportInProgress=false
        end
        ActiveTeleportThread=nil
    end)
end


-- Anti-Hit integrado, sem criar uma segunda interface.
local AntiHitEnabled=false
local IsAntiHitTeleporting=false
local AntiHitTeleportPoints={
    Vector3.new(500.62,241.28,-366.64),
    Vector3.new(504.45,155.80,-366.35),
    Vector3.new(508.30,70.28,-366.03),
    Vector3.new(513.86,70.28,-366.25),
    Vector3.new(519.43,70.28,-366.47),
    Vector3.new(524.32,70.28,-366.59),
    Vector3.new(529.22,70.28,-366.71),
    Vector3.new(538.01,70.28,-365.55),
    Vector3.new(546.80,70.28,-364.40)
}

local function runAntiHitRoute(character)
    if not AntiHitEnabled or IsAntiHitTeleporting then return end
    if not character or not character.Parent then return end

    IsAntiHitTeleporting=true
    task.spawn(function()
        for _,position in ipairs(AntiHitTeleportPoints) do
            if not AntiHitEnabled then break end
            if not character.Parent then break end
            pcall(function() character:PivotTo(CFrame.new(position)) end)
            RunService.Heartbeat:Wait()
        end
        task.wait(.25)
        IsAntiHitTeleporting=false
    end)
end

ProximityPromptService.PromptTriggered:Connect(function(prompt,triggeredPlayer)
    if triggeredPlayer~=LocalPlayer then return end
    if not AntiHitEnabled or IsAntiHitTeleporting then return end
    local character=LocalPlayer.Character
    if not character then return end
    runAntiHitRoute(character)
end)

local PromptReturnEnabled=false
local PromptReturnMoving=false
local PromptConnections={}
local ScriptExecutionCFrame=StartCFrame
local function disconnectPromptConnections()
    for _,c in ipairs(PromptConnections) do pcall(function() c:Disconnect() end) end
    table.clear(PromptConnections)
end
local function returnToExecutionPosition()
    if PromptReturnMoving or not ScriptExecutionCFrame then return end
    PromptReturnMoving=true
    task.spawn(function()
        local character=LocalPlayer.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local hrp=character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not hrp then PromptReturnMoving=false; return end
        hrp.CFrame=ScriptExecutionCFrame
        task.wait(.7)
        character=LocalPlayer.Character
        humanoid=character and character:FindFirstChildOfClass("Humanoid")
        hrp=character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not hrp then PromptReturnMoving=false; return end
        humanoid:MoveTo(ScriptExecutionCFrame.Position)
        local startTime=os.clock()
        while PromptReturnMoving and os.clock()-startTime<15 do
            hrp=character:FindFirstChild("HumanoidRootPart")
            if not hrp or (hrp.Position-ScriptExecutionCFrame.Position).Magnitude<=6 then break end
            humanoid.Jump=true
            task.wait(.15)
        end
        PromptReturnMoving=false
    end)
end
local function handlePromptReturn(player)
    if player~=LocalPlayer or not PromptReturnEnabled or WaitingForIslandPrompt or IslandTeleportInProgress or PromptReturnMoving then return end
    task.spawn(function()
        task.wait(.5)
        if PromptReturnEnabled and not WaitingForIslandPrompt and not IslandTeleportInProgress then returnToExecutionPosition() end
    end)
end
local function connectPromptForReturn(prompt)
    if prompt:IsA("ProximityPrompt") then table.insert(PromptConnections,prompt.Triggered:Connect(handlePromptReturn)) end
end
local function setPromptReturnEnabled(enabled)
    PromptReturnEnabled=enabled
    disconnectPromptConnections()
    if not enabled then return end
    for _,object in ipairs(Workspace:GetDescendants()) do connectPromptForReturn(object) end
    table.insert(PromptConnections,Workspace.DescendantAdded:Connect(function(object) if PromptReturnEnabled then connectPromptForReturn(object) end end))
end

local Optimizer={Enabled=false,Busy=false,Revision=0,Slice=.003,Queue={},Connections={},Saved={},Originals=setmetatable({}, {__mode="k"})}

local function saveGlobal(obj,key,value)
    local ok,old=pcall(function() return obj[key] end)
    if ok then
        table.insert(Optimizer.Saved,{Setter=function(v) obj[key]=v end,Value=old})
        pcall(function() obj[key]=value end)
    end
end
local function saveProp(obj,key,value)
    local store=Optimizer.Originals[obj]
    if not store then store={}; Optimizer.Originals[obj]=store end
    if store[key]==nil then
        local ok,old=pcall(function() return obj[key] end)
        if not ok then return end
        store[key]=old
    end
    pcall(function() obj[key]=value end)
end
local function optimizeObject(obj)
    if not Optimizer.Enabled or not obj.Parent then return end
    if obj:IsA("ParticleEmitter") then saveProp(obj,"Enabled",false); saveProp(obj,"Rate",0)
    elseif obj:IsA("Trail") or obj:IsA("Beam") then saveProp(obj,"Enabled",false)
    elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then saveProp(obj,"Enabled",false); saveProp(obj,"Brightness",0)
    elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then saveProp(obj,"Enabled",false)
    elseif obj:IsA("Explosion") then saveProp(obj,"Visible",false)
    elseif obj:IsA("SpecialMesh") then saveProp(obj,"TextureId","")
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        if not (obj.Name=="face" and obj.Parent and obj.Parent.Name=="Head") then saveProp(obj,"Transparency",1) end
    elseif obj:IsA("MeshPart") then
        saveProp(obj,"RenderFidelity",Enum.RenderFidelity.Performance); saveProp(obj,"TextureID",""); saveProp(obj,"CastShadow",false); saveProp(obj,"Reflectance",0); saveProp(obj,"Material",Enum.Material.SmoothPlastic)
    elseif obj:IsA("BasePart") then saveProp(obj,"CastShadow",false); saveProp(obj,"Reflectance",0); saveProp(obj,"Material",Enum.Material.SmoothPlastic)
    elseif obj:IsA("PostEffect") then saveProp(obj,"Enabled",false)
    elseif obj:IsA("Clouds") then saveProp(obj,"Cover",0); saveProp(obj,"Density",0)
    elseif obj:IsA("Atmosphere") then saveProp(obj,"Density",0); saveProp(obj,"Haze",0); saveProp(obj,"Glare",0)
    end
end
local function disconnectOptimizer()
    for _,c in ipairs(Optimizer.Connections) do pcall(function() c:Disconnect() end) end
    table.clear(Optimizer.Connections)
    if Optimizer.Heartbeat then pcall(function() Optimizer.Heartbeat:Disconnect() end); Optimizer.Heartbeat=nil end
end
local function restoreOptimizer()
    if not Optimizer.Enabled then return end
    Optimizer.Enabled=false; Optimizer.Revision+=1; disconnectOptimizer(); table.clear(Optimizer.Queue)
    for obj,props in pairs(Optimizer.Originals) do
        if obj.Parent then for key,value in pairs(props) do pcall(function() obj[key]=value end) end end
        Optimizer.Originals[obj]=nil
    end
    for i=#Optimizer.Saved,1,-1 do pcall(Optimizer.Saved[i].Setter,Optimizer.Saved[i].Value) end
    table.clear(Optimizer.Saved)
end
local function optimizeGlobals()
    local rendering=settings().Rendering
    saveGlobal(rendering,"QualityLevel",Enum.QualityLevel.Level01)
    saveGlobal(rendering,"MeshPartDetailLevel",Enum.MeshPartDetailLevel.Level01)
    saveGlobal(rendering,"EditQualityLevel",Enum.QualityLevel.Level01)
    local ok,ugs=pcall(function() return UserSettings():GetService("UserGameSettings") end)
    if ok and ugs then saveGlobal(ugs,"SavedQualityLevel",Enum.SavedQualitySetting.QualityLevel1) end
    saveGlobal(Lighting,"GlobalShadows",false); saveGlobal(Lighting,"ShadowSoftness",0)
    saveGlobal(Lighting,"FogEnd",9000000000); saveGlobal(Lighting,"Technology",Enum.Technology.Legacy)
    saveGlobal(Lighting,"EnvironmentDiffuseScale",0); saveGlobal(Lighting,"EnvironmentSpecularScale",0)
    local terrain=Workspace.Terrain
    saveGlobal(terrain,"Decoration",false); saveGlobal(terrain,"WaterWaveSize",0); saveGlobal(terrain,"WaterWaveSpeed",0)
    saveGlobal(terrain,"WaterReflectance",0); saveGlobal(terrain,"WaterTransparency",1)
end
local function enableOptimizer()
    if Optimizer.Enabled or Optimizer.Busy then return end
    Optimizer.Busy=true; Optimizer.Enabled=true; Optimizer.Revision+=1
    local rev=Optimizer.Revision
    optimizeGlobals()
    local function watch(root)
        table.insert(Optimizer.Connections,root.DescendantAdded:Connect(function(obj)
            if Optimizer.Enabled and Optimizer.Revision==rev then table.insert(Optimizer.Queue,obj) end
        end))
    end
    watch(Workspace); watch(Lighting)
    Optimizer.Heartbeat=RunService.Heartbeat:Connect(function()
        if not Optimizer.Enabled or Optimizer.Revision~=rev then return end
        local start=os.clock()
        while #Optimizer.Queue>0 and os.clock()-start<Optimizer.Slice do optimizeObject(table.remove(Optimizer.Queue)) end
    end)
    task.spawn(function()
        for _,obj in ipairs(Workspace:GetDescendants()) do
            if not Optimizer.Enabled or Optimizer.Revision~=rev then Optimizer.Busy=false; return end
            optimizeObject(obj)
            if os.clock()%1 < .001 then RunService.Heartbeat:Wait() end
        end
        for _,obj in ipairs(Lighting:GetDescendants()) do
            if not Optimizer.Enabled or Optimizer.Revision~=rev then Optimizer.Busy=false; return end
            optimizeObject(obj)
            if os.clock()%1 < .001 then RunService.Heartbeat:Wait() end
        end
        Optimizer.Busy=false
    end)
end
local function emergencyStop()
    if EmergencyStopped then return end
    EmergencyStopped=true
    TeleportRevision+=1
    IslandTeleportInProgress=false
    WaitingForIslandPrompt=false
    AntiHitEnabled=false
    IsAntiHitTeleporting=false

    -- Cancel any active teleport task, including one waiting for a ProximityPrompt.
    if ActiveTeleportThread then
        pcall(task.cancel, ActiveTeleportThread)
        ActiveTeleportThread=nil
    end

    -- Stop prompt return.
    PromptReturnEnabled=false
    PromptReturnMoving=false
    disconnectPromptConnections()

    -- Stop optimizer and restore everything it changed.
    pcall(restoreOptimizer)

    -- Disable the bypass before respawning so CharacterAdded cannot reapply it.
    Bypass.Enabled=false
    Bypass.InProgress=false
    pcall(function()
        if Bypass._conn then
            Bypass._conn:Disconnect()
            Bypass._conn=nil
        end
    end)
    pcall(Bypass.Restore)

    -- Stop movement controlled by this script.
    pcall(function()
        local character=LocalPlayer.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:Move(Vector3.zero,false)
            humanoid.WalkSpeed=16
            humanoid.Jump=false
        end
    end)

    -- Respawn is the final hard reset.
    pcall(function()
        LocalPlayer:LoadCharacter()
    end)
end


local function createUI()
    local gui=Instance.new("ScreenGui")
    gui.Name="HumanoidBypassFloatingUI"
    gui.ResetOnSpawn=false
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    gui.Parent=PlayerGui

    -- Segunda interface: somente a janela flutuante.
    local floating=Instance.new("Frame")
    floating.Size=UDim2.fromOffset(235,470)
    floating.Position=UDim2.new(0,350,0,80)
    floating.BackgroundColor3=Color3.fromRGB(16,17,22)
    floating.BorderSizePixel=0
    floating.Visible=true
    floating.Active=true
    floating.Parent=gui
    Instance.new("UICorner",floating).CornerRadius=UDim.new(0,16)

    local fs=Instance.new("UIStroke",floating)
    fs.Color=Color3.fromRGB(55,58,70)
    fs.Thickness=1.1

    local ftitle=Instance.new("TextLabel")
    ftitle.Size=UDim2.new(1,-20,0,34)
    ftitle.Position=UDim2.fromOffset(10,8)
    ftitle.BackgroundTransparency=1
    ftitle.Text="island controls"
    ftitle.TextColor3=Color3.fromRGB(235,238,245)
    ftitle.Font=Enum.Font.GothamBold
    ftitle.TextSize=12
    ftitle.TextXAlignment=Enum.TextXAlignment.Left
    ftitle.Parent=floating

    local status=Instance.new("TextLabel")
    status.Position=UDim2.fromOffset(10,42)
    status.Size=UDim2.new(1,-20,0,28)
    status.BackgroundColor3=Color3.fromRGB(25,27,34)
    status.BorderSizePixel=0
    status.Text="  initializing..."
    status.TextColor3=Color3.fromRGB(150,155,165)
    status.Font=Enum.Font.GothamMedium
    status.TextSize=10
    status.TextXAlignment=Enum.TextXAlignment.Left
    status.Parent=floating
    Instance.new("UICorner",status).CornerRadius=UDim.new(0,8)

    local selectedLabel=Instance.new("TextLabel")
    selectedLabel.Position=UDim2.fromOffset(10,76)
    selectedLabel.Size=UDim2.new(1,-20,0,20)
    selectedLabel.BackgroundTransparency=1
    selectedLabel.Text="selected: "..string.lower(SelectedIsland)
    selectedLabel.TextColor3=Color3.fromRGB(205,208,216)
    selectedLabel.Font=Enum.Font.Gotham
    selectedLabel.TextSize=10
    selectedLabel.TextXAlignment=Enum.TextXAlignment.Left
    selectedLabel.Parent=floating

    local fscroll=Instance.new("ScrollingFrame")
    fscroll.Position=UDim2.fromOffset(8,100)
    fscroll.Size=UDim2.new(1,-16,0,145)
    fscroll.BackgroundTransparency=1
    fscroll.BorderSizePixel=0
    fscroll.ScrollBarThickness=3
    fscroll.CanvasSize=UDim2.new(0,0,0,math.ceil(#IslandOrder/2)*34)
    fscroll.Parent=floating

    local grid=Instance.new("UIGridLayout",fscroll)
    grid.CellSize=UDim2.fromOffset(101,30)
    grid.CellPadding=UDim2.fromOffset(6,4)

    local function islandButton(name)
        local b=Instance.new("TextButton")
        b.BackgroundColor3=Color3.fromRGB(29,31,39)
        b.BorderSizePixel=0
        b.Text=string.lower(name)
        b.TextColor3=Color3.fromRGB(220,223,230)
        b.Font=Enum.Font.GothamMedium
        b.TextSize=9
        b.AutoButtonColor=false
        b.Parent=fscroll
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
        b.MouseButton1Click:Connect(function()
            if EmergencyStopped then return end
            SelectedIsland=name
            selectedLabel.Text="selected: "..string.lower(name)
            runIslandTeleport(name)
        end)
    end

    for _,name in ipairs(IslandOrder) do
        islandButton(name)
    end

    local function toggleButton(textOff, y)
        local b=Instance.new("TextButton")
        b.Position=UDim2.fromOffset(10,y)
        b.Size=UDim2.new(1,-20,0,30)
        b.BackgroundColor3=Color3.fromRGB(29,31,39)
        b.BorderSizePixel=0
        b.Text=textOff
        b.TextColor3=Color3.fromRGB(225,228,235)
        b.Font=Enum.Font.GothamMedium
        b.TextSize=10
        b.AutoButtonColor=false
        b.Parent=floating
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
        return b
    end

    -- Auto Prompt / Prompt Return
    local prompt=toggleButton("auto prompt  •  off",253)
    prompt.MouseButton1Click:Connect(function()
        if EmergencyStopped then return end
        setPromptReturnEnabled(not PromptReturnEnabled)
        prompt.Text="auto prompt  •  "..(PromptReturnEnabled and "on" or "off")
        prompt.TextColor3=PromptReturnEnabled and Color3.fromRGB(120,255,165) or Color3.fromRGB(225,228,235)
    end)

    -- Anti-Hit
    local antiHitBtn=toggleButton("anti hit  •  off",289)
    antiHitBtn.MouseButton1Click:Connect(function()
        if EmergencyStopped then return end
        AntiHitEnabled=not AntiHitEnabled
        antiHitBtn.Text="anti hit  •  "..(AntiHitEnabled and "on" or "off")
        antiHitBtn.TextColor3=AntiHitEnabled and Color3.fromRGB(120,255,165) or Color3.fromRGB(225,228,235)
    end)

    -- FPS Boost is automatic. There is intentionally no ON/OFF button.
    if not Optimizer.Enabled and not EmergencyStopped then
        task.spawn(function()
            enableOptimizer()
        end)
    end

    -- Speed Bypass
    local SpeedBypassEnabled = false
    local SpeedBypassValue = 350
    local SpeedBypassActive = false
    local SpeedBypassConnection = nil

    local speedBypassBtn=toggleButton("speed bypass  •  off",326)
    speedBypassBtn.MouseButton1Click:Connect(function()
        if EmergencyStopped then return end

        SpeedBypassEnabled = not SpeedBypassEnabled

        if SpeedBypassEnabled then
            speedBypassBtn.Text="speed bypass  •  on"
            speedBypassBtn.TextColor3=Color3.fromRGB(120,255,165)
        else
            speedBypassBtn.Text="speed bypass  •  off"
            speedBypassBtn.TextColor3=Color3.fromRGB(225,228,235)
        end
    end)

    local speedLabel=Instance.new("TextLabel")
    speedLabel.Position=UDim2.fromOffset(12,362)
    speedLabel.Size=UDim2.new(1,-24,0,18)
    speedLabel.BackgroundTransparency=1
    speedLabel.Text="speed bypass  •  350 studs/s"
    speedLabel.TextColor3=Color3.fromRGB(190,194,203)
    speedLabel.Font=Enum.Font.GothamMedium
    speedLabel.TextSize=10
    speedLabel.TextXAlignment=Enum.TextXAlignment.Left
    speedLabel.Parent=floating

    local bar=Instance.new("Frame")
    bar.Position=UDim2.fromOffset(12,387)
    bar.Size=UDim2.new(1,-24,0,6)
    bar.BackgroundColor3=Color3.fromRGB(40,42,51)
    bar.BorderSizePixel=0
    bar.Active=true
    bar.Parent=floating
    Instance.new("UICorner",bar).CornerRadius=UDim.new(1,0)

    local knob=Instance.new("Frame")
    knob.Size=UDim2.fromOffset(14,14)
    knob.AnchorPoint=Vector2.new(.5,.5)
    knob.Position=UDim2.new((SpeedBypassValue-50)/950,0,.5,0)
    knob.BackgroundColor3=Color3.fromRGB(220,223,230)
    knob.BorderSizePixel=0
    knob.Active=true
    knob.Parent=bar
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local draggingSpeed=false

    local function setSpeedBypassFromX(x)
        local alpha=math.clamp(
            (x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,
            0,1
        )

        SpeedBypassValue=math.floor(50+alpha*950+0.5)
        knob.Position=UDim2.new(alpha,0,.5,0)
        speedLabel.Text="speed bypass  •  "..SpeedBypassValue.." studs/s"
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1
            or input.UserInputType==Enum.UserInputType.Touch then
            draggingSpeed=true
            setSpeedBypassFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingSpeed
            and (input.UserInputType==Enum.UserInputType.MouseMovement
            or input.UserInputType==Enum.UserInputType.Touch) then
            setSpeedBypassFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1
            or input.UserInputType==Enum.UserInputType.Touch then
            draggingSpeed=false
        end
    end)

    local function getSpeedBypassCharacter()
        local character=LocalPlayer.Character
        local hrp=character and character:FindFirstChild("HumanoidRootPart")
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")

        if hrp and humanoid and humanoid.Health>0 then
            return hrp,humanoid
        end

        return nil,nil
    end

    local function restoreSpeedBypassVelocity()
        if not SpeedBypassActive then return end
        SpeedBypassActive=false

        local hrp,humanoid=getSpeedBypassCharacter()
        if not hrp or not humanoid then return end

        local currentVelocity=hrp.AssemblyLinearVelocity
        local moveDirection=humanoid.MoveDirection
        local horizontal=Vector3.new(moveDirection.X,0,moveDirection.Z)
        local normalVelocity=horizontal.Magnitude>0.001
            and horizontal.Unit*humanoid.WalkSpeed
            or Vector3.new(0,0,0)

        pcall(function()
            hrp.AssemblyLinearVelocity=Vector3.new(
                normalVelocity.X,
                currentVelocity.Y,
                normalVelocity.Z
            )
        end)
    end

    local function stopSpeedBypass()
        if SpeedBypassConnection then
            SpeedBypassConnection:Disconnect()
            SpeedBypassConnection=nil
        end

        restoreSpeedBypassVelocity()
    end

    local function startSpeedBypass()
        if SpeedBypassConnection then return end

        SpeedBypassConnection=RunService.Heartbeat:Connect(function()
            if EmergencyStopped or not SpeedBypassEnabled then
                restoreSpeedBypassVelocity()
                return
            end

            local hrp,humanoid=getSpeedBypassCharacter()

            if not hrp
                or humanoid.Sit
                or humanoid.PlatformStand then
                SpeedBypassActive=false
                return
            end

            local ragdollEndTime=tonumber(
                LocalPlayer:GetAttribute("RagdollEndTime")
            )

            if ragdollEndTime
                and ragdollEndTime>Workspace:GetServerTimeNow() then
                SpeedBypassActive=false
                return
            end

            local moveDirection=humanoid.MoveDirection
            local horizontal=Vector3.new(moveDirection.X,0,moveDirection.Z)

            if horizontal.Magnitude<=0.001 then
                restoreSpeedBypassVelocity()
                return
            end

            local targetVelocity=horizontal.Unit*SpeedBypassValue
            local currentVelocity=hrp.AssemblyLinearVelocity

            pcall(function()
                hrp.AssemblyLinearVelocity=Vector3.new(
                    targetVelocity.X,
                    currentVelocity.Y,
                    targetVelocity.Z
                )
            end)

            SpeedBypassActive=true
        end)
    end

    task.spawn(function()
        while gui.Parent do
            if EmergencyStopped then
                stopSpeedBypass()
                break
            end

            if SpeedBypassEnabled then
                startSpeedBypass()
            else
                stopSpeedBypass()
            end

            task.wait(0.05)
        end
    end)

    local emergency=Instance.new("TextButton")
    emergency.Position=UDim2.fromOffset(10,411)
    emergency.Size=UDim2.new(1,-20,0,38)
    emergency.BackgroundColor3=Color3.fromRGB(52,25,30)
    emergency.BorderSizePixel=0
    emergency.Text="emergency  •  stop everything"
    emergency.TextColor3=Color3.fromRGB(255,110,120)
    emergency.Font=Enum.Font.GothamMedium
    emergency.TextSize=10
    emergency.Parent=floating
    Instance.new("UICorner",emergency).CornerRadius=UDim.new(0,8)
    emergency.MouseButton1Click:Connect(emergencyStop)

    -- Fixed keybinds only: F = island teleport, Q = safe area.
    UserInputService.InputBegan:Connect(function(input,gameProcessed)
        if gameProcessed or EmergencyStopped then return end
        if input.UserInputType~=Enum.UserInputType.Keyboard then return end

        if input.KeyCode==Enum.KeyCode.F then
            runIslandTeleport(SelectedIsland)
        elseif input.KeyCode==Enum.KeyCode.Q then
            if StartCFrame then
                local c=LocalPlayer.Character
                local h=c and c:FindFirstChild("HumanoidRootPart")
                if h then h.CFrame=StartCFrame end
            end
        end
    end)

    local function drag(handle,object)
        local dragging=false
        local startPos
        local startInput

        handle.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                dragging=true
                startInput=input.Position
                startPos=object.Position
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
                local delta=input.Position-startInput
                object.Position=UDim2.new(
                    startPos.X.Scale,startPos.X.Offset+delta.X,
                    startPos.Y.Scale,startPos.Y.Offset+delta.Y
                )
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                dragging=false
            end
        end)
    end

    drag(ftitle,floating)

    Bypass._statusCallback=function(ok,msg)
        if EmergencyStopped then return end
        status.Text="  "..(ok and "● " or "× ")..tostring(msg)
        status.TextColor3=ok and Color3.fromRGB(120,255,165) or Color3.fromRGB(255,130,140)
    end

    task.spawn(function()
        while gui.Parent do
            if EmergencyStopped then
                status.Text="  script  •  emergency stopped"
                status.TextColor3=Color3.fromRGB(255,100,110)
                break
            end
            local active=Bypass.IsActive()
            if active then
                status.Text="  bypass  •  active"
                status.TextColor3=Color3.fromRGB(120,255,165)
            else
                status.Text="  bypass  •  inactive"
                status.TextColor3=Color3.fromRGB(255,120,130)
            end
            task.wait(.5)
        end
    end)

    return gui
end

createUI()
if not EmergencyStopped then
    task.spawn(enableOptimizer)
end
log(true,"Painel carregado. Aplicando bypass automaticamente...")
