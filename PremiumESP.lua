-- Premium ESP v5 - Улучшенный дизайн, Глубокие цвета и Много плавных анимаций (Studio safe)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- === НАСТРОЙКИ И ОФОРМЛЕНИЕ ===
local ESP_GLOBAL_ENABLED = true -- Текущее глобальное состояние (видно/скрыто)
local MAX_DISTANCE = 400
local FADE_TIME = 0.5 -- Время плавного исчезновения/появления

-- Палитра
local PULSE_SPEED_HIGHLIGHT = 4 -- Скорость пульсации Highlight
local PULSE_SPEED_GLOW = 6 -- Скорость пульсации Health Bar Glow

local COLOR_ENEMY = Color3.fromRGB(150, 60, 255) -- Deep Indigo
local COLOR_FRIEND = Color3.fromRGB(60, 255, 180) -- Soft Aqua
local COLOR_BACKGROUND = Color3.fromRGB(10, 10, 12)
local COLOR_STROKE = Color3.fromRGB(0, 0, 0)
local COLOR_TEXT_DIM = Color3.fromRGB(220, 220, 220)
local COLOR_TEXT_BRIGHT = Color3.fromRGB(255, 255, 255)

-- Градиенты для Health Bar
local COLOR_HEALTH_FULL = Color3.fromRGB(100, 255, 120) -- Зеленый
local COLOR_HEALTH_MID = Color3.fromRGB(255, 220, 50) -- Желто-оранжевый
local COLOR_HEALTH_LOW = Color3.fromRGB(255, 80, 80) -- Красный

local playerESPs = {}
local globalFadeValue = 0 -- 0 - полностью видно, 1 - полностью скрыто
local currentGlobalTween = nil

-- === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===

local function fadeESPs(enabled)
	local targetTrans = enabled and 0 or 1
	local tweenInfo = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	if currentGlobalTween then currentGlobalTween:Cancel() end
	-- Твиним глобальную прозрачность (используем прокси-значение)
	if not _G.ESP_FADE_PROXY then
		_G.ESP_FADE_PROXY = Instance.new("NumberValue")
		_G.ESP_FADE_PROXY.Value = globalFadeValue
		_G.ESP_FADE_PROXY.Changed:Connect(function(newVal)
			globalFadeValue = newVal
			-- В updateRender мы будем использовать это значение для Transparency
		end)
	end
	currentGlobalTween = TweenService:Create(_G.ESP_FADE_PROXY, tweenInfo, {Value = targetTrans})
	currentGlobalTween:Play()
end

-- Переключение F4 с анимацией
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.F4 then
		ESP_GLOBAL_ENABLED = not ESP_GLOBAL_ENABLED
		fadeESPs(ESP_GLOBAL_ENABLED)
	end
end)

-- Создание UI один раз
local function createPremiumESP(player, character)
	local esp = { Adornments = {} }
	
	local humanoid = character:WaitForChild("Humanoid", 5)
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoid or not root then return nil end
	
	-- Кешируем начальные значения для пульсации
	esp.BaseHighlightOutlineTrans = 0.15
	esp.BaseHighlightFillTrans = 0.88
	
	-- === HIGHLIGHT (Основной Глоу) ===
	local highlight = Instance.new("Highlight")
	highlight.Adornee = character
	highlight.FillTransparency = esp.BaseHighlightFillTrans
	highlight.OutlineTransparency = esp.BaseHighlightOutlineTrans
	highlight.OutlineColor = COLOR_ENEMY
	highlight.FillColor = COLOR_ENEMY
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character
	esp.Highlight = highlight
	
	-- === BILLBOARD GUI С CANVASGROUP (Для плавного Fade) ===
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Adornee = root
	billboardGui.Size = UDim2.new(6, 0, 3.5, 0) -- Чуть больше для текста ХП
	billboardGui.StudsOffset = Vector3.new(0, 3.8, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.LightInfluence = 0
	billboardGui.Parent = character
	
	-- CanvasGroup - ключ к плавности Fade всего UI
	local canvasGroup = Instance.new("CanvasGroup")
	canvasGroup.Size = UDim2.new(1, 0, 1, 0)
	canvasGroup.BackgroundTransparency = 1
	canvasGroup.Parent = billboardGui
	esp.CanvasGroup = canvasGroup
	
	-- === ИМЯ И ДИСТАНЦИЯ ===
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.DisplayName
	nameLabel.TextColor3 = COLOR_TEXT_BRIGHT
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.TextStrokeColor3 = COLOR_STROKE
	nameLabel.Font = Enum.Font.GothamBold -- Улучшенный шрифт
	nameLabel.TextSize = 22
	nameLabel.ZIndex = 2
	nameLabel.Parent = canvasGroup
	
	local distLabel = Instance.new("TextLabel")
	distLabel.Size = UDim2.new(1, 0, 0.25, 0)
	distLabel.Position = UDim2.new(0, 0, 0.35, 0)
	distLabel.BackgroundTransparency = 1
	distLabel.TextColor3 = COLOR_TEXT_DIM
	distLabel.TextStrokeTransparency = 0.5
	distLabel.Font = Enum.Font.Gotham
	distLabel.TextSize = 16
	distLabel.ZIndex = 2
	distLabel.Parent = canvasGroup
	
	esp.NameLabel = nameLabel
	esp.DistLabel = distLabel
	
	-- === 3D HEALTH BAR НАД ГОЛОВОЙ ===
	local healthBarFrame = Instance.new("Frame")
	healthBarFrame.Size = UDim2.new(4, 0, 0.55, 0)
	healthBarFrame.Position = UDim2.new(0, 0, 0.65, 0)
	healthBarFrame.BackgroundTransparency = 1
	healthBarFrame.AnchorPoint = Vector2.new(0.5, 0) -- Центрируем
	healthBarFrame.Position = UDim2.new(0.5, 0, 0.65, 0)
	healthBarFrame.Parent = canvasGroup
	
	-- Фон бара (с очертанием)
	local healthBg = Instance.new("Frame")
	healthBg.Size = UDim2.new(1, 0, 1, 0)
	healthBg.BackgroundColor3 = COLOR_BACKGROUND
	healthBg.BorderSizePixel = 0
	healthBg.Parent = healthBarFrame
	
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0.5, 0)
	bgCorner.Parent = healthBg
	
	-- Заполнение здоровья (Градиент)
	local healthFill = Instance.new("Frame")
	healthFill.Size = UDim2.new(1, 0, 1, 0)
	healthFill.BackgroundColor3 = COLOR_ENEMY -- Базовый цвет, меняем градиентом
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthBg
	esp.HealthFill = healthFill
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.5, 0)
	fillCorner.Parent = healthFill
	
	-- UIGradient для HealthFill
	local healthGradient = Instance.new("UIGradient")
	healthGradient.Color = ColorSequence.new(COLOR_HEALTH_LOW, COLOR_HEALTH_FULL)
	healthGradient.Rotation = 0
	healthGradient.Parent = healthFill
	esp.HealthGradient = healthGradient
	
	-- Текст точного количества ХП
	local healthTextLabel = Instance.new("TextLabel")
	healthTextLabel.Size = UDim2.new(1, 0, 1, 0)
	healthTextLabel.BackgroundTransparency = 1
	healthTextLabel.TextColor3 = COLOR_TEXT_BRIGHT
	healthTextLabel.TextStrokeTransparency = 0.3
	healthTextLabel.TextStrokeColor3 = COLOR_STROKE
	healthTextLabel.Font = Enum.Font.GothamMedium
	healthTextLabel.TextSize = 14
	healthTextLabel.ZIndex = 3
	healthTextLabel.Parent = healthBg
	esp.HealthTextLabel = healthTextLabel
	
	-- Внутренняя тень (innerShadow)
	local innerShadow = Instance.new("Frame")
	innerShadow.Size = UDim2.new(1, 2, 1, 2)
	innerShadow.Position = UDim2.new(0, -1, 0, -1)
	innerShadow.BackgroundColor3 = COLOR_STROKE
	innerShadow.BackgroundTransparency = 0.5
	innerShadow.BorderSizePixel = 0
	innerShadow.ZIndex = -2
	innerShadow.Parent = healthBg
	
	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0.5, 0)
	shadowCorner.Parent = innerShadow
	
	-- Глубокое пульсирующее свечение (Outer Glow layers)
	local glowFrame = Instance.new("Frame")
	glowFrame.Size = UDim2.new(1, 6, 1, 6)
	glowFrame.Position = UDim2.new(0, -3, 0, -3)
	glowFrame.BackgroundColor3 = COLOR_TEXT_BRIGHT -- Базовый
	glowFrame.BackgroundTransparency = 0.8
	glowFrame.BorderSizePixel = 0
	glowFrame.ZIndex = -1
	glowFrame.Parent = healthBg
	esp.HealthGlow = glowFrame
	
	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(0.5, 0)
	glowCorner.Parent = glowFrame
	
	esp.HealthBarFrame = healthBarFrame
	esp.HealthBg = healthBg
	
	table.insert(esp.Adornments, billboardGui)
	
	-- Сразу применяем глобальную прозрачность при создании
	canvasGroup.GroupTransparency = globalFadeValue
	
	return esp
end

local function removePremiumESP(player)
	if playerESPs[player] then
		for _, obj in ipairs(playerESPs[player].Adornments) do
			if obj and obj.Parent then obj:Destroy() end
		end
		if playerESPs[player].Highlight and playerESPs[player].Highlight.Parent then
			playerESPs[player].Highlight:Destroy()
		end
		playerESPs[player] = nil
	end
end

-- Инициализация отслеживания игрока
local function onPlayerAdded(player)
	if player == LocalPlayer then return end
	
	local function onCharacterAdded(character)
		removePremiumESP(player)
		local esp = createPremiumESP(player, character)
		if esp then
			playerESPs[player] = esp
		end
	end
	
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
end

-- Подключаем всех текущих и будущих игроков
Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end
Players.PlayerRemoving:Connect(removePremiumESP)

-- Рендер и анимации (0 тяжелых вызовов Instance.new)
local function updatePremiumESP()
	local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local localTeam = LocalPlayer.Team
	local timeTick = os.clock()
	
	-- Глобальные пульсации
	local pulseHighlight = (math.sin(timeTick * PULSE_SPEED_HIGHLIGHT) + 1) / 2
	local pulseGlow = (math.sin(timeTick * PULSE_SPEED_GLOW) + 1) / 2

	for player, esp in pairs(playerESPs) do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChild("Humanoid")
		
		-- Если игрок мертв или выключен глобальный ESP
		if not root or not hum or hum.Health <= 0 then
			for _, obj in ipairs(esp.Adornments) do obj.Enabled = false end
			if esp.Highlight then esp.Highlight.Enabled = false end
			continue
		end

		-- Проверка дистанции
		local distance = localRoot and (localRoot.Position - root.Position).Magnitude or 9999
		if distance > MAX_DISTANCE then
			for _, obj in ipairs(esp.Adornments) do obj.Enabled = false end
			if esp.Highlight then esp.Highlight.Enabled = false end
			continue
		end

		-- Плавное исчезновение при Fade F4
		if globalFadeValue >= 1 then -- Если полностью скрыто
			for _, obj in ipairs(esp.Adornments) do obj.Enabled = false end
			if esp.Highlight then esp.Highlight.Enabled = false end
			continue
		else
			-- Если все проверки пройдены, включаем элементы
			for _, obj in ipairs(esp.Adornments) do obj.Enabled = true end
			if esp.Highlight then esp.Highlight.Enabled = true end
		end

		-- Применяем глобальный Fade Transparency к UI
		esp.CanvasGroup.GroupTransparency = globalFadeValue

		-- Цвета и расчеты
		local isFriend = localTeam and player.Team == localTeam
		local baseColor = isFriend and COLOR_FRIEND or COLOR_ENEMY
		local humMaxHealth = hum.MaxHealth > 0 and hum.MaxHealth or 100 -- Защита от 0 MaxHealth
		local healthPercent = math.clamp(hum.Health / humMaxHealth, 0, 1)
		
		-- Анимация Highlight (с учетом глобального Fade)
		local currentOutlineTrans = esp.BaseHighlightOutlineTrans + pulseHighlight * 0.35
		local currentFillTrans = esp.BaseHighlightFillTrans
		
		-- Твиним прозрачность Highlight отдельно от UI
		esp.Highlight.OutlineTransparency = math.clamp(globalFadeValue * 0.85 + currentOutlineTrans, 0, 1)
		esp.Highlight.FillTransparency = math.clamp(globalFadeValue * 0.95 + currentFillTrans, 0, 1)
		
		-- Обновление ХП и Текста
		esp.HealthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
		esp.HealthTextLabel.Text = string.format("%d/%d", hum.Health, humMaxHealth)
		
		-- Цвета Health Bar (заполнения и свечения)
		local healthColor = baseColor:Lerp(COLOR_HEALTH_LOW, 1 - healthPercent) -- Враг -> Красный
		
		-- Анимация цвета градиента
		esp.HealthGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, healthColor:Lerp(COLOR_HEALTH_FULL, 0.15)), -- Более светлый в начале
			ColorSequenceKeypoint.new(1, healthColor)
		})
		
		esp.HealthGlow.BackgroundTransparency = 0.65 + pulseGlow * 0.2
		esp.HealthGlow.BackgroundColor3 = healthColor
		
		-- Текст Имени
		esp.NameLabel.TextColor3 = healthColor
		esp.DistLabel.Text = string.format("%.0fm", distance)
		
		-- === ДИНАМИЧЕСКИЕ АНИМАЦИИ ХП ===
		
		-- 1. Анимация жизни (всегда): Небольшая, медленная пульсация всего бара
		local lifePulse = (math.sin(timeTick * 2) + 1) / 2
		local baseSize = isFriend and UDim2.new(4, 0, 0.55, 0) or UDim2.new(4, 0, 0.55, 0)
		
		-- 2. При низком ХП: Плавно увеличиваем и пульсируем красным
		if healthPercent < 0.3 then
			local humHealthInt = math.floor(hum.Health)
			-- Быстрая пульсация размера
			local lowHpPulse = (math.sin(timeTick * 10) + 1) / 2
			esp.HealthBarFrame.Size = UDim2.new(4.5 + lowHpPulse * 0.5, 0, 0.75 + lowHpPulse * 0.15, 0)
			
			-- Быстрая пульсация цвета Highlights красным
			esp.Highlight.OutlineColor = humHealthInt % 2 == 0 and COLOR_HEALTH_LOW or COLOR_STROKE
			esp.Highlight.FillColor = COLOR_HEALTH_LOW
			esp.HealthTextLabel.TextColor3 = COLOR_HEALTH_LOW
		else
			-- Обычное состояние (с легкой анимацией жизни)
			esp.HealthBarFrame.Size = UDim2.new(4 + lifePulse * 0.15, 0, 0.55 + lifePulse * 0.05, 0)
			esp.Highlight.OutlineColor = healthColor
			esp.Highlight.FillColor = healthColor
			esp.HealthTextLabel.TextColor3 = COLOR_TEXT_BRIGHT
		end
	end
end

RunService.RenderStepped:Connect(updatePremiumESP)
print("[PremiumESP v5] Успешно инициализирован! Новый дизайн, градиенты и Fade F4 активны.")
