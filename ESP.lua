-- Сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
-- Настройки
local ESP_COLOR_ENEMY = Color3.fromRGB(255, 50, 50) -- Враги
local ESP_COLOR_FRIEND = Color3.fromRGB(50, 255, 100) -- Свои
local ESP_ENABLED = true
-- Переключение по F4
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F4 then
        ESP_ENABLED = not ESP_ENABLED
    end
end)
-- Хранилище объектов ESP для каждого игрока
local playerESPs = {}
-- Создание объектов для игрока
local function createESP(player)
    local esp = {}
   
    -- Рамка (внешняя светящаяся)
    esp.OuterBox = Drawing.new("Square")
    esp.OuterBox.Thickness = 3
    esp.OuterBox.Filled = false
    esp.OuterBox.Color = ESP_COLOR_ENEMY
    esp.OuterBox.Transparency = 0.4
    esp.OuterBox.Visible = false
   
    -- Рамка (внутренняя четкая)
    esp.InnerBox = Drawing.new("Square")
    esp.InnerBox.Thickness = 1
    esp.InnerBox.Filled = false
    esp.InnerBox.Color = ESP_COLOR_ENEMY
    esp.InnerBox.Transparency = 0.9
    esp.InnerBox.Visible = false
   
    -- Полоса здоровья (фон)
    esp.HealthBar = Drawing.new("Square")
    esp.HealthBar.Filled = true
    esp.HealthBar.Color = Color3.fromRGB(30, 30, 30)
    esp.HealthBar.Transparency = 0.8
    esp.HealthBar.Visible = false
   
    -- Полоса здоровья (заполнение)
    esp.HealthFill = Drawing.new("Square")
    esp.HealthFill.Filled = true
    esp.HealthFill.Color = ESP_COLOR_ENEMY
    esp.HealthFill.Transparency = 0.9
    esp.HealthFill.Visible = false
   
    -- Имя игрока
    esp.NameText = Drawing.new("Text")
    esp.NameText.Size = 13
    esp.NameText.Center = true
    esp.NameText.Outline = true
    esp.NameText.OutlineColor = Color3.new()
    esp.NameText.Color = Color3.new(1, 1, 1)
    esp.NameText.Visible = false
   
    -- Расстояние
    esp.DistanceText = Drawing.new("Text")
    esp.DistanceText.Size = 12
    esp.DistanceText.Center = true
    esp.DistanceText.Outline = true
    esp.DistanceText.OutlineColor = Color3.new()
    esp.DistanceText.Color = Color3.fromRGB(200, 200, 200)
    esp.DistanceText.Visible = false
   
    return esp
end
-- Удаление ESP для игрока
local function removeESP(player)
    if playerESPs[player] then
        for _, v in pairs(playerESPs[player]) do
            if v.Remove then v:Remove() end
        end
        playerESPs[player] = nil
    end
end
-- Обновление позиций и данных
local function updateESP()
    if not ESP_ENABLED then
        -- Скрываем всё, если выключено
        for _, esp in pairs(playerESPs) do
            for _, v in pairs(esp) do
                v.Visible = false
            end
        end
        return
    end
   
    local localTeam = nil
    if LocalPlayer.Character then
        localTeam = LocalPlayer.Team
    end
   
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
       
        local character = player.Character
        if not character or not character:FindFirstChild("Humanoid") or not character:FindFirstChild("Head") then
            if playerESPs[player] then
                for _, v in pairs(playerESPs[player]) do
                    v.Visible = false
                end
            end
            continue
        end
       
        local humanoid = character.Humanoid
        local head = character.Head
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then continue end
       
        -- Создаём ESP, если ещё нет
        if not playerESPs[player] then
            playerESPs[player] = createESP(player)
        end
        local esp = playerESPs[player]
       
        -- Позиция на экране
        local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        local rootPos = Camera:WorldToViewportPoint(rootPart.Position)
        local legPos = Camera:WorldToViewportPoint((rootPart.CFrame * CFrame.new(0, -3, 0)).Position)
       
        if not onScreen then
            for _, v in pairs(esp) do v.Visible = false end
            continue
        end
       
        -- Расчёт размеров коробки
        local height = (headPos.Y - legPos.Y) * 0.8
        local width = height * 0.55
        local boxX = headPos.X - width / 2
        local boxY = headPos.Y - height * 0.1
       
        -- Определяем цвет (враг/свой)
        local isFriend = localTeam and player.Team == localTeam
        local baseColor = isFriend and ESP_COLOR_FRIEND or ESP_COLOR_ENEMY
        local healthPercent = humanoid.Health / humanoid.MaxHealth
       
        -- Цвет рамки с градиентом по здоровью
        local boxColor = baseColor:Lerp(Color3.fromRGB(255, 255, 255), 0.2):Lerp(
            Color3.fromRGB(255, 255, 0), 0.5 * (1 - healthPercent))
        if healthPercent < 0.3 then
            boxColor = Color3.fromRGB(255, 100, 100)
        end
       
        -- Рамка внешняя (свечение)
        esp.OuterBox.Position = Vector2.new(boxX - 2, boxY - 2)
        esp.OuterBox.Size = Vector2.new(width + 4, height + 4)
        esp.OuterBox.Color = boxColor
        esp.OuterBox.Transparency = 0.4
        esp.OuterBox.Visible = true
       
        -- Рамка внутренняя
        esp.InnerBox.Position = Vector2.new(boxX, boxY)
        esp.InnerBox.Size = Vector2.new(width, height)
        esp.InnerBox.Color = boxColor
        esp.InnerBox.Transparency = 0.9
        esp.InnerBox.Visible = true
       
        -- Health bar (слева от коробки)
        local barWidth = 3
        local barX = boxX - 7
        local barY = boxY + height * (1 - healthPercent)
        local barFullHeight = height
       
        esp.HealthBar.Position = Vector2.new(barX, boxY)
        esp.HealthBar.Size = Vector2.new(barWidth, barFullHeight)
        esp.HealthBar.Visible = true
       
        esp.HealthFill.Position = Vector2.new(barX, barY)
        esp.HealthFill.Size = Vector2.new(barWidth, height * healthPercent)
        esp.HealthFill.Color = boxColor
        esp.HealthFill.Visible = true
       
        -- Имя
        esp.NameText.Text = player.DisplayName
        esp.NameText.Position = Vector2.new(headPos.X, headPos.Y - height * 0.15)
        esp.NameText.Color = Color3.new(1, 1, 1)
        esp.NameText.Visible = true
       
        -- Расстояние
        local distance = math.floor((LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and
            (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude) or 0)
        esp.DistanceText.Text = distance .. "m"
        esp.DistanceText.Position = Vector2.new(headPos.X, headPos.Y + height * 0.7)
        esp.DistanceText.Visible = true
    end
end
-- Обработчики появления/ухода игроков
Players.PlayerRemoving:Connect(removeESP)
-- Главный цикл отрисовки
RunService.RenderStepped:Connect(updateESP)