--// AUTO BAT STANDALONE
--// Native GUI | Draggable | No UI Library

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- CONFIG / ESTADO
--==================================================

local Enabled = false

local SwingCounter = 0
local LastSwing = 0
local LastEquip = 0

local SwingConnection = nil
local BatRemote = nil

local BatRange = 17
local BatAttribute = "IsBat"

--==================================================
-- BUSCAR MODULES DENTRO DE SHARED
--==================================================

local function GetSharedModule(path)
    local Current = ReplicatedStorage:FindFirstChild("Shared")

    if not Current then
        return nil
    end

    for _, Name in ipairs(path) do
        Current = Current:FindFirstChild(Name)

        if not Current then
            return nil
        end
    end

    if Current:IsA("ModuleScript") then
        local Success, Result = pcall(require, Current)

        if Success then
            return Result
        end
    end

    return nil
end

--==================================================
-- CONFIG DO BAT
--==================================================

pcall(function()
    local Config = GetSharedModule({
        "Modules",
        "BatController",
        "Config"
    })

    if type(Config) == "table" then
        BatRange =
            (tonumber(Config.Range) or 15)
            + (tonumber(Config.HitTolerance) or 2)

        if type(Config.GetHitboxScalar) == "function" then
            local Success, Scalar = pcall(Config.GetHitboxScalar)

            if Success and type(Scalar) == "number" and Scalar > 0 then
                BatRange *= Scalar
            end
        end
    end
end)

--==================================================
-- ATRIBUTO DO BAT
--==================================================

pcall(function()
    local Sakura = require(ReplicatedStorage.Data.Sakura)

    if type(Sakura) == "table"
        and type(Sakura.BatToolAttribute) == "string" then

        BatAttribute = Sakura.BatToolAttribute
    end
end)

--==================================================
-- PLAYER / CHARACTER
--==================================================

local function GetCharacterInfo(Player)
    if not Player then
        return nil
    end

    local Character = Player.Character

    if not Character then
        return nil
    end

    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")

    if RootPart and Humanoid and Humanoid.Health > 0 then
        return RootPart, Humanoid, Character
    end

    return nil
end

--==================================================
-- ENCONTRAR BAT
--==================================================

local function FindBat(Container)
    if not Container then
        return nil
    end

    for _, Child in ipairs(Container:GetChildren()) do
        if Child:IsA("Tool") then
            local Success, IsBat = pcall(function()
                return Child:GetAttribute(BatAttribute)
            end)

            if Success and IsBat == true then
                return Child
            end
        end
    end

    return nil
end

local function GetEquippedBat()
    return FindBat(LocalPlayer.Character)
end

--==================================================
-- EQUIPAR BAT
--==================================================

local function EquipBat()
    local Equipped = FindBat(LocalPlayer.Character)

    if Equipped then
        return Equipped
    end

    local Now = os.clock()

    if Now - LastEquip < 0.35 then
        return nil
    end

    LastEquip = Now

    local Backpack = LocalPlayer:FindFirstChild("Backpack")

    if not Backpack then
        return nil
    end

    local Bat = FindBat(Backpack)

    if not Bat then
        return nil
    end

    local Character = LocalPlayer.Character

    if not Character then
        return nil
    end

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")

    if not Humanoid then
        return nil
    end

    pcall(function()
        Humanoid:EquipTool(Bat)
    end)

    return FindBat(LocalPlayer.Character)
end

--==================================================
-- TOKEN ORIGINAL DO SWING
--==================================================

local function CreateSwingToken()
    SwingCounter += 1

    return string.format(
        "%d:%d:%d",
        LocalPlayer.UserId,
        SwingCounter,
        math.floor(workspace:GetServerTimeNow() * 1000)
    )
end

--==================================================
-- ENCONTRAR BAT SWING
--==================================================

local function GetBatRemote()
    if BatRemote and BatRemote.Parent then
        return BatRemote
    end

    local Remotes = GetSharedModule({
        "Remotes"
    })

    if type(Remotes) == "table" then
        local BatSwing = Remotes.BatSwing

        if BatSwing then
            local Remote =
                BatSwing.Trigger
                or BatSwing.Remote
                or BatSwing.remote
                or BatSwing.Instance
                or BatSwing._remote
                or BatSwing._instance
                or BatSwing.Event

            if typeof(Remote) == "Instance" then
                BatRemote = Remote
                return BatRemote
            end
        end
    end

    -- Fallback direto no ReplicatedStorage
    local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")

    if RemotesFolder then
        local BatSwing = RemotesFolder:FindFirstChild("BatSwing")

        if BatSwing then
            local Trigger = BatSwing:FindFirstChild("Trigger")

            if Trigger and Trigger:IsA("RemoteEvent") then
                BatRemote = Trigger
                return BatRemote
            end
        end
    end

    return nil
end

--==================================================
-- SWING NO PLAYER
--==================================================

local function SwingAt(Target)
    if not Enabled then
        return false
    end

    if not Target or Target == LocalPlayer then
        return false
    end

    local Now = os.clock()

    if Now - LastSwing < 0.7 then
        return false
    end

    local MyRoot = select(1, GetCharacterInfo(LocalPlayer))
    local TargetRoot = select(1, GetCharacterInfo(Target))

    if not MyRoot or not TargetRoot then
        return false
    end

    local Distance =
        (MyRoot.Position - TargetRoot.Position).Magnitude

    if Distance > BatRange then
        return false
    end

    if not EquipBat() and not GetEquippedBat() then
        return false
    end

    local Remote = GetBatRemote()

    if not Remote then
        return false
    end

    LastSwing = Now

    pcall(function()
        Remote:FireServer(
            Target,
            CreateSwingToken()
        )
    end)

    return true
end

--==================================================
-- ENCONTRAR PLAYER MAIS PRÓXIMO
--==================================================

local function GetClosestTarget(Position)
    local ClosestPlayer = nil
    local ClosestDistance = nil

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then

            local RootPart = select(
                1,
                GetCharacterInfo(Player)
            )

            if RootPart then
                local Distance =
                    (RootPart.Position - Position).Magnitude

                if Distance <= BatRange then

                    if not ClosestDistance
                        or Distance < ClosestDistance then

                        ClosestPlayer = Player
                        ClosestDistance = Distance
                    end
                end
            end
        end
    end

    return ClosestPlayer
end

--==================================================
-- AUTO BAT
--==================================================

local function AutoBatTick()
    if not Enabled then
        return
    end

    local MyRoot = select(
        1,
        GetCharacterInfo(LocalPlayer)
    )

    if not MyRoot then
        return
    end

    local Target = GetClosestTarget(MyRoot.Position)

    if Target then
        SwingAt(Target)
    end
end

--==================================================
-- LIGAR / DESLIGAR
--==================================================

local function SetAutoBat(State)
    Enabled = State == true

    if Enabled then

        if not SwingConnection then
            SwingConnection = RunService.Heartbeat:Connect(function()
                pcall(AutoBatTick)
            end)
        end

    else

        if SwingConnection then
            SwingConnection:Disconnect()
            SwingConnection = nil
        end
    end
end

--==================================================
-- GUI NATIVA
--==================================================

pcall(function()
    local Old = PlayerGui:FindFirstChild("AutoBatNativeGUI")

    if Old then
        Old:Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoBatNativeGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Button = Instance.new("TextButton")
Button.Name = "AutoBatButton"
Button.Size = UDim2.fromOffset(155, 48)
Button.Position = UDim2.new(0, 25, 0.5, -24)
Button.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Button.BorderSizePixel = 0
Button.Text = "AUTO BAT: OFF"
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.TextSize = 14
Button.Font = Enum.Font.GothamBold
Button.AutoButtonColor = false
Button.Active = true
Button.Selectable = true
Button.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Button

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 1.5
Stroke.Transparency = 0.25
Stroke.Color = Color3.fromRGB(100, 100, 110)
Stroke.Parent = Button

--==================================================
-- ATUALIZAR VISUAL
--==================================================

local function UpdateButton()
    if Enabled then
        Button.Text = "AUTO BAT: ON"
        Button.BackgroundColor3 = Color3.fromRGB(35, 120, 65)
    else
        Button.Text = "AUTO BAT: OFF"
        Button.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    end
end

--==================================================
-- CLICK
--==================================================

Button.MouseButton1Click:Connect(function()
    SetAutoBat(not Enabled)
    UpdateButton()
end)

--==================================================
-- SISTEMA DE ARRASTAR
--==================================================

local Dragging = false
local DragStart
local StartPosition
local DragInput

local function UpdateDrag(Input)
    local Delta = Input.Position - DragStart

    Button.Position = UDim2.new(
        StartPosition.X.Scale,
        StartPosition.X.Offset + Delta.X,
        StartPosition.Y.Scale,
        StartPosition.Y.Offset + Delta.Y
    )
end

Button.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch then

        Dragging = true
        DragStart = Input.Position
        StartPosition = Button.Position

        Input.Changed:Connect(function()
            if Input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

Button.InputChanged:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseMovement
        or Input.UserInputType == Enum.UserInputType.Touch then

        DragInput = Input
    end
end)

UserInputService.InputChanged:Connect(function(Input)
    if Input == DragInput and Dragging then
        UpdateDrag(Input)
    end
end)

--==================================================
-- INICIAL
--==================================================

UpdateButton()

print("[Auto Bat] Loaded")
print("[Auto Bat] Range:", BatRange)
