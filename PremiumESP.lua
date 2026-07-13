-- Premium ESP v3 - Ахуенный дизайн (Studio only)
-- Добавлены: 3D Health Bar над головой + Glow-анимация
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- === НАСТРОЙКИ ===
local ESP_ENABLED = true
local ESP_COLOR_ENEMY = Color3.fromRGB(255, 60, 60)
local ESP_COLOR_FRIEND = Color3.fromRGB(60, 255, 140)
local MAX_DISTANCE = 400
local GLOW_SPEED = 6 -- скорость пульсации glow

-- Переключение F4
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.F4 then
		ESP_ENABLED = not ESP_ENABLED
	end
end)

local playerESPs = {}

local function createPremiumESP(player)
	local esp = { Connections = {}, Adornments = {} }
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	
	-- === HIGHLIGHT (основной glow) ===
	local highlight = Instance.new("Highlight")
	highlight.Adornee = character
	highlight.FillTransparency = 0.88
	highlight.OutlineTransparency = 0
	highlight.OutlineColor = ESP_COLOR_ENEMY
	highlight.FillColor = ESP_COLOR_ENEMY
	highlight.Parent = character
	esp.Highlight = highlight
	
	-- === BILLBOARD С ИМЕНЕМ И ДИСТАНЦИЕЙ ===
	local nameBillboard = Instance.new("BillboardGui")
	nameBillboard.Adornee = root
	nameBillboard.Size = UDim2.new(6, 0, 1.8, 0)
	nameBillboard.StudsOffset = Vector3.new(0, 4.5, 0)
	nameBillboard.AlwaysOnTop = true
	nameBillboard.LightInfluence = 0
	nameBillboard.Parent = character
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.DisplayName
	nameLabel.TextColor3 = Color3.new(1,1,1)
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.TextStrokeColor3 = Color3.new(0,0,0)
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextSize = 22
	nameLabel.Parent = nameBillboard
	
	local distLabel = Instance.new("TextLabel")
	distLabel.Size = UDim2.new(1, 0, 0.45, 0)
	distLabel.Position = UDim2.new(0, 0, 0.55, 0)
	distLabel.BackgroundTransparency = 1
	distLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	distLabel.TextStrokeTransparency = 0.6
	distLabel.Font = Enum.Font.Gotham
	distLabel.TextSize = 16
	distLabel.Parent = nameBillboard
	
	esp.NameBillboard = nameBillboard
	esp.NameLabel = nameLabel
	esp.DistLabel = distLabel
	
	-- === 3D HEALTH BAR НАД ГОЛОВОЙ (премиум) ===
	local healthBillboard = Instance.new("BillboardGui")
	healthBillboard.Adornee = root
	healthBillboard.Size = UDim2.new(4, 0, 0.6, 0)
	healthBillboard.StudsOffset = Vector3.new(0, 3.2, 0)
	healthBillboard.AlwaysOnTop = true
	healthBillboard.LightInfluence = 0
	healthBillboard.Parent = character
	
	-- Фон бара
	local healthBg = Instance.new("Frame")
	healthBg.Size = UDim2.new(1, 0, 1, 0)
	healthBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	healthBg.BorderSizePixel = 0
	healthBg.Parent = healthBillboard
	
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0.5, 0)
	bgCorner.Parent = healthBg
	
	-- Заполнение здоровья
	local healthFill = Instance.new("Frame")
	healthFill.Size = UDim2.new(1, 0, 1, 0)
	healthFill.BackgroundColor3 = ESP_COLOR_ENEMY
	healthFill.BorderSizePixel = 0
	healthFill.AnchorPoint = Vector2.new(0, 0)
	healthFill.Parent = healthBg
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.5, 0)
	fillCorner.Parent = healthFill
	
	-- Лёгкий inner glow эффект
	local glowFrame = Instance.new("Frame")
	glowFrame.Size = UDim2.new(1, 4, 1, 4)
	glowFrame.Position = UDim2.new(0, -2, 0, -2)
	glowFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	glowFrame.BackgroundTransparency = 0.85
	glowFrame.BorderSizePixel = 0
	glowFrame.ZIndex = -1
	glowFrame.Parent = healthBg
	
	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(0.5, 0)
	glowCorner.Parent = glowFrame
	
	esp.HealthBillboard = healthBillboard
	esp.HealthFill = healthFill
	esp.HealthGlow = glowFrame
	
	-- Сохраняем всё
	table.insert(esp.Adornments, nameBillboard)
	table.insert(esp.Adornments, healthBillboard)
	
	return esp
end

local function removePremiumESP(player)
	if playerESPs[player] then
		local esp = playerESPs[player]
		for _, obj in ipairs(esp.Adornments) do
			if obj and obj.Parent then obj:Destroy() end
		end
		if esp.Highlight and esp.Highlight.Parent then
			esp.Highlight:Destroy()
		end
		playerESPs[player] = nil
	end
end

local function updatePremiumESP()
	if not ESP_ENABLED then
		for _, esp in pairs(playerESPs) do
			for _, obj in ipairs(esp.Adornments) do
				obj.Enabled = false
			end
			if esp.Highlight then esp.Highlight.Enabled = false end
		end
		return
	end

	local localTeam = LocalPlayer.Team
	local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		
		local character = player.Character
		if not character or not character:FindFirstChild("Humanoid") or not character:FindFirstChild("HumanoidRootPart") then
			removePremiumESP(player)
			continue
		end

		local humanoid = character.Humanoid
		local root = character.HumanoidRootPart
		local distance = localRoot and (localRoot.Position - root.Position).Magnitude or 9999

		if distance > MAX_DISTANCE then
			removePremiumESP(player)
			continue
		end

		if not playerESPs[player] then
			playerESPs[player] = createPremiumESP(player)
		end

		local esp = playerESPs[player]
		local isFriend = localTeam and player.Team == localTeam
		local baseColor = isFriend and ESP_COLOR_FRIEND or ESP_COLOR_ENEMY
		
		local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
		
		-- Динамический цвет по здоровью
		local healthColor = baseColor:Lerp(Color3.fromRGB(255, 200, 50), 1 - healthPercent)
		if healthPercent < 0.25 then
			healthColor = Color3.fromRGB(255, 80, 80)
		end
		
		-- === HIGHLIGHT + GLOW АНИМАЦИЯ ===
		esp.Highlight.OutlineColor = healthColor
		esp.Highlight.FillColor = healthColor
		esp.Highlight.Enabled = true
		
		-- Красивая пульсация glow (sin wave)
		local pulse = (math.sin(tick() * GLOW_SPEED) + 1) / 2
		local outlineAlpha = 0.15 + pulse * 0.35
		esp.Highlight.OutlineTransparency = outlineAlpha
		
		-- === 3D HEALTH BAR НАД ГОЛОВОЙ ===
		esp.HealthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
		esp.HealthFill.BackgroundColor3 = healthColor
		
		-- Glow эффект на health bar
		esp.HealthGlow.BackgroundTransparency = 0.7 + pulse * 0.2
		esp.HealthGlow.BackgroundColor3 = healthColor
		
		-- === ИМЯ И ДИСТАНЦИЯ ===
		esp.NameLabel.TextColor3 = healthColor
		esp.DistLabel.Text = string.format("%.0fm", distance)
		
		-- Лёгкое изменение размера при низком ХП (дополнительный визуал)
		if healthPercent < 0.3 then
			esp.HealthBillboard.Size = UDim2.new(4.5, 0, 0.75, 0) -- чуть толще
		else
			esp.HealthBillboard.Size = UDim2.new(4, 0, 0.6, 0)
		end
	end
end

-- Чистка при выходе игрока
Players.PlayerRemoving:Connect(removePremiumESP)

-- Главный цикл
RunService.RenderStepped:Connect(updatePremiumESP)

print("[PremiumESP] Загружено! F4 — вкл/выкл | 3D Health Bar + Glow активны 🔥")