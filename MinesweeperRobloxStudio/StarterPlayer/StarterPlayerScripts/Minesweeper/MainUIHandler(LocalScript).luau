--[[
	MainUIHandler  (LocalScript)
	Letak: StarterPlayer > StarterPlayerScripts > MainUIHandler

	Integrates GridGenerator and GameLogic with an advanced Action Menu interaction system.
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

local UIHelper       = require(ReplicatedStorage:WaitForChild("Minesweeper"):WaitForChild("UIHelper"))
local GridGenerator  = require(ReplicatedStorage:WaitForChild("Minesweeper"):WaitForChild("GridGenerator"))
local GameLogic      = require(ReplicatedStorage:WaitForChild("Minesweeper"):WaitForChild("GameLogic"))

local Theme = UIHelper.Theme

--=========================================================
-- 0. KONSTANTA
--=========================================================
local DESIGN_W, DESIGN_H = 420, 900
local TOP_BAR_H          = 64
local BOTTOM_BAR_H       = 72

local DIFFICULTIES = {
	{ Name = "Easy",   Columns = 8,  Rows = 10, Targets = 10 },
	{ Name = "Medium", Columns = 10, Rows = 15, Targets = 40 },
	{ Name = "Hard",   Columns = 12, Rows = 18, Targets = 60 },
}
local DEFAULT_DIFFICULTY = "Medium"

-- Interaction Settings
local DOUBLE_CLICK_THRESHOLD = 0.3
local LONG_PRESS_THRESHOLD = 0.5

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--=========================================================
-- 1. SCREEN GUI
--=========================================================
local screenGui = UIHelper.screenGui({
	Name = "PuzzleGameUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 10,
	Parent = playerGui,
})

UIHelper.frame({
	Name = "Backdrop",
	Size = UDim2.fromScale(1, 1),
	Position = UDim2.fromScale(0, 0),
	BackgroundColor3 = Theme.Background,
	BorderSizePixel = 0,
	ZIndex = 0,
	Parent = screenGui,
})

--=========================================================
-- 2. CONTENT CANVAS
--=========================================================
local contentCanvas = UIHelper.frame({
	Name = "ContentCanvas",
	Size = UDim2.fromOffset(DESIGN_W, DESIGN_H),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Parent = screenGui,
})

local uiScale = UIHelper.uiScale(1, contentCanvas)

--=========================================================
-- 3. TOP BAR
--=========================================================
local topBar = UIHelper.frame({
	Name = "TopBar",
	Size = UDim2.new(1, 0, 0, TOP_BAR_H),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = Theme.Panel,
	BorderSizePixel = 0,
	Parent = contentCanvas,
})

local difficultyButton = UIHelper.button({
	Name = "DifficultyButton",
	Size = UDim2.new(0, 110, 0, 36),
	Position = UDim2.new(0, 12, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	BackgroundColor3 = Theme.PanelLight,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "",
	Parent = topBar,
})
UIHelper.corner(8, difficultyButton)

local difficultyLabel = UIHelper.label({
	Name = "Label",
	Size = UDim2.new(1, -28, 1, 0),
	Position = UDim2.new(0, 10, 0, 0),
	BackgroundTransparency = 1,
	Text = DEFAULT_DIFFICULTY,
	TextColor3 = Theme.Text,
	TextSize = Theme.FontSize.Normal,
	Font = Theme.FontMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = difficultyButton,
})

UIHelper.label({
	Name = "Chevron",
	Size = UDim2.new(0, 18, 1, 0),
	Position = UDim2.new(1, -22, 0, 0),
	BackgroundTransparency = 1,
	Text = "▾",
	TextColor3 = Theme.TextDim,
	TextSize = 14,
	Font = Theme.Font,
	Parent = difficultyButton,
})

local progressGroup = UIHelper.frame({
	Name = "ProgressGroup",
	Size = UDim2.new(0, 130, 0, 36),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Theme.PanelLight,
	BorderSizePixel = 0,
	Parent = topBar,
})
UIHelper.corner(8, progressGroup)

UIHelper.listLayout({
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, progressGroup)

UIHelper.label({
	Name = "FlagIcon",
	Size = UDim2.new(0, 18, 1, 0),
	BackgroundTransparency = 1,
	Text = "⚑",
	TextColor3 = Theme.Accent,
	TextSize = 18,
	Font = Theme.Font,
	LayoutOrder = 1,
	Parent = progressGroup,
})

local progressLabel = UIHelper.label({
	Name = "ProgressLabel",
	Size = UDim2.new(0, 86, 1, 0),
	BackgroundTransparency = 1,
	Text = "0 / 40",
	TextColor3 = Theme.Text,
	TextSize = Theme.FontSize.Normal,
	Font = Theme.Font,
	TextXAlignment = Enum.TextXAlignment.Left,
	LayoutOrder = 2,
	Parent = progressGroup,
})

local timerGroup = UIHelper.frame({
	Name = "TimerGroup",
	Size = UDim2.new(0, 90, 0, 36),
	Position = UDim2.new(1, -60, 0.5, 0),
	AnchorPoint = Vector2.new(1, 0.5),
	BackgroundColor3 = Theme.PanelLight,
	BorderSizePixel = 0,
	Parent = topBar,
})
UIHelper.corner(8, timerGroup)

UIHelper.listLayout({
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, timerGroup)

UIHelper.label({
	Name = "TimerIcon",
	Size = UDim2.new(0, 16, 1, 0),
	BackgroundTransparency = 1,
	Text = "⏱",
	TextColor3 = Theme.Accent,
	TextSize = 16,
	Font = Theme.Font,
	LayoutOrder = 1,
	Parent = timerGroup,
})

local timerLabel = UIHelper.label({
	Name = "TimerLabel",
	Size = UDim2.new(0, 58, 1, 0),
	BackgroundTransparency = 1,
	Text = "000",
	TextColor3 = Theme.Text,
	TextSize = Theme.FontSize.Normal,
	Font = Theme.Font,
	TextXAlignment = Enum.TextXAlignment.Left,
	LayoutOrder = 2,
	Parent = timerGroup,
})

local soundButton = UIHelper.button({
	Name = "SoundButton",
	Size = UDim2.new(0, 40, 0, 36),
	Position = UDim2.new(1, -12, 0.5, 0),
	AnchorPoint = Vector2.new(1, 0.5),
	BackgroundColor3 = Theme.PanelLight,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "",
	Parent = topBar,
})
UIHelper.corner(8, soundButton)

local soundIcon = UIHelper.label({
	Name = "SoundIcon",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "🔊",
	TextColor3 = Theme.Text,
	TextSize = 18,
	Font = Theme.Font,
	Parent = soundButton,
})

--=========================================================
-- 4. GRID AREA
--=========================================================
local gridFrame = UIHelper.frame({
	Name = "MainGridFrame",
	Size = UDim2.new(0.95, 0, 0.6, 0),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Parent = contentCanvas,
})

local grid = GridGenerator.new(gridFrame)

--=========================================================
-- 5. BOTTOM BAR
--=========================================================
local bottomBar = UIHelper.frame({
	Name = "BottomBar",
	Size = UDim2.new(1, 0, 0, BOTTOM_BAR_H),
	Position = UDim2.new(0, 0, 1, 0),
	AnchorPoint = Vector2.new(0, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Parent = contentCanvas,
})

local menuButton = UIHelper.button({
	Name = "MenuButton",
	Size = UDim2.new(0, 56, 0, 56),
	Position = UDim2.new(1, -16, 0.5, 0),
	AnchorPoint = Vector2.new(1, 0.5),
	BackgroundColor3 = Theme.PanelLight,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "",
	Parent = bottomBar,
})
UIHelper.corner(12, menuButton)

UIHelper.label({
	Name = "Icon",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "☰",
	TextColor3 = Theme.Text,
	TextSize = Theme.FontSize.Huge,
	Font = Theme.Font,
	Parent = menuButton,
})

--=========================================================
-- 6. DROPDOWN
--=========================================================
local dropdownBackdrop = UIHelper.button({
	Name = "DropdownBackdrop",
	Size = UDim2.fromScale(1, 1),
	Position = UDim2.fromScale(0, 0),
	BackgroundTransparency = 1,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
	ZIndex = 6,
	Parent = contentCanvas,
})

local dropdownMenu = UIHelper.frame({
	Name = "DropdownMenu",
	Size = UDim2.new(0, 110, 0, 0),
	Position = UDim2.new(0, 12, 0, 56),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = Theme.PanelLight,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 7,
	Parent = contentCanvas,
})
UIHelper.corner(8, dropdownMenu)
UIHelper.padding(4, dropdownMenu)

UIHelper.listLayout({
	FillDirection = Enum.FillDirection.Vertical,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 2),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
}, dropdownMenu)

for i, data in ipairs(DIFFICULTIES) do
	UIHelper.button({
		Name = "Option_" .. data.Name,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Theme.PanelLight,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = data.Name,
		TextColor3 = Theme.Text,
		TextSize = Theme.FontSize.Normal,
		Font = Theme.FontMedium,
		LayoutOrder = i,
		ZIndex = 7,
		Parent = dropdownMenu,
	})
end

--=========================================================
-- 7. RESPONSIVE UISCALE
--=========================================================
local camera = workspace.CurrentCamera
local function updateUIScale()
	local vp = camera.ViewportSize
	uiScale.Scale = math.min(vp.X / DESIGN_W, vp.Y / DESIGN_H)
end
updateUIScale()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateUIScale)

--=========================================================
-- 8. GAME STATE
--=========================================================
local state = {
	currentDifficulty = DEFAULT_DIFFICULTY,
	muted   = false,
	target  = 40,
	filled  = 0,
	-- Minefield data
	minefield   = nil, 
	revealedSet = {},
	gameStarted = false,
	gameEnded   = false,
	
	elapsed = 0,
	dropdownOpen = false,
	timerConn = nil,
	lastSecond = -1,
	completed = false,
}

local SoundService = game:GetService("SoundService")
local sfxGroup = Instance.new("SoundGroup")
sfxGroup.Name = "PuzzleSFX"
sfxGroup.Volume = 0.6
sfxGroup.Parent = SoundService

local function playSfx(soundId)
	if state.muted then return end
	local s = Instance.new("Sound")
	s.SoundId = soundId or "rbxassetid://6895079853"
	s.SoundGroup = sfxGroup
	s.Parent = SoundService
	s:Play()
	task.delay(2, function() s:Destroy() end)
end

--=========================================================
-- 9. TIMER
--=========================================================
local function formatTime(sec)
	return string.format("%03d", math.floor(sec))
end

local function startTimer()
	if state.timerConn then state.timerConn:Disconnect() end
	state.elapsed = 0
	state.lastSecond = -1
	state.timerConn = RunService.Heartbeat:Connect(function(dt)
		state.elapsed += dt
		local s = math.floor(state.elapsed)
		if s ~= state.lastSecond then
			state.lastSecond = s
			timerLabel.Text = formatTime(s)
		end
	end)
end

local function stopTimer()
	if state.timerConn then
		state.timerConn:Disconnect()
		state.timerConn = nil
	end
end

--=========================================================
-- 10. PROGRESS
--=========================================================
local function updateProgress()
	local flaggedCount = grid:CountState(GridGenerator.State.Flagged)
	progressLabel.Text = string.format("%d / %d", flaggedCount, state.target)
end

--=========================================================
-- 11. GAME MECHANICS
--=========================================================

local function endGame(won)
	state.gameEnded = true
	stopTimer()
	
	if won then
		print("[Game] You Win!")
	else
		print("[Game] Game Over!")
		grid:ForEachCell(function(cell)
			local row, col = cell.Row, cell.Column
			if state.minefield[row][col] then
				grid:SetCellState(row, col, GridGenerator.State.Bomb, true)
				grid:SetCellIndicator(row, col, "💣")
			end
		end)
	end
end

local function revealCell(row, col)
	local cell = grid:GetCell(row, col)
	if not cell or cell.State ~= GridGenerator.State.Empty then return end
	
	if state.minefield[row][col] then
		grid:SetCellState(row, col, GridGenerator.State.Bomb, true)
		grid:SetCellIndicator(row, col, "💣")
		endGame(false)
		return
	end
	
	local cols, rows = grid:GetDimensions()
	GameLogic.floodFill({row = row, col = col}, 
		rows, 
		cols, 
		state.minefield, 
		state.revealedSet, 
		function(pos, proximity)
			local r, c = pos.row, pos.col
			grid:SetCellState(r, c, GridGenerator.State.Revealed, true)
			if proximity > 0 then
				grid:SetCellIndicator(r, c, tostring(proximity))
			end
		end
	)
	
	local colsW, rowsW = grid:GetDimensions()
	if GameLogic.checkWin(rowsW, colsW, state.minefield, state.revealedSet) then
		endGame(true)
	end
end

local function toggleFlag(row, col)
	local cell = grid:GetCell(row, col)
	if not cell or cell.State ~= GridGenerator.State.Empty then return end
	
	local newState = (cell.State == GridGenerator.State.Flagged) 
		and GridGenerator.State.Empty 
		or GridGenerator.State.Flagged
	
	grid:SetCellState(row, col, newState, true)
	grid:SetCellIndicator(row, col, newState == GridGenerator.State.Flagged and "⚑" or "")
	updateProgress()
	playSfx()
end

--=========================================================
-- 12. ACTION MENU SYSTEM
--=========================================================

local currentActionMenu = nil

local function closeActionMenu()
	if currentActionMenu then
		currentActionMenu:Destroy()
		currentActionMenu = nil
	end
end

local function createActionMenu(cell)
	closeActionMenu()
	
	-- Calculate center position of the cell
	-- We use the Button's AbsolutePosition to place the menu accurately
	local absPos = cell.Button.AbsolutePosition
	local absSize = cell.Button.AbsoluteSize
	local center = Vector2.new(absPos.X + absSize.X/2, absPos.Y + absSize.Y/2)

	-- Action Menu Container (Capsule)
	local menu = UIHelper.frame({
		Name = "ActionMenu",
		Size = UDim2.fromOffset(120, 40),
		Position = UDim2.fromOffset(center.X, center.Y),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		ZIndex = 100,
		Parent = screenGui,
	})
	UIHelper.corner(20, menu)
	
	UIHelper.listLayout({
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, menu)

	-- Helper to create circular buttons
	local function createCircleButton(text, color, callback)
		local btn = UIHelper.button({
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = color,
			Text = text,
			TextColor3 = Theme.Text,
			TextSize = 16,
			Font = Theme.FontBold,
			AutoButtonColor = true,
			Parent = menu,
		})
		UIHelper.corner(15, btn)
		btn.Activated:Connect(function()
			callback()
			closeActionMenu()
		end)
		return btn
	end

	-- Button 1: Cancel (X)
	createCircleButton("X", Color3.fromRGB(180, 50, 50), function()
		playSfx()
	end)

	-- Button 2: Dig (Shovel)
	createCircleButton("⛏", Theme.Accent, function()
		playSfx()
		-- First click safety logic
		if not state.gameStarted then
			local cols, rows = grid:GetDimensions()
			state.minefield = GameLogic.generateMinefield({row = cell.Row, col = cell.Column}, rows, cols, state.target)
			state.gameStarted = true
			startTimer()
		end
		revealCell(cell.Row, cell.Column)
	end)

	-- Button 3: Flag
	createCircleButton("⚑", Theme.PanelLight, function()
		playSfx()
		toggleFlag(cell.Row, cell.Column)
	end)

	currentActionMenu = menu
end

--=========================================================
-- 13. INPUT DETECTION
--=========================================================

local lastClickTime = 0
local lastClickedCell = nil
local pressStartTime = 0
local pressCell = nil

-- We use a custom handler for clicks because TextButton.Activated 
-- doesn't provide precise timing for long-press/double-click.
-- We will connect to the Grid's interaction signals but handle logic here.

grid:OnCellClicked(function(cell)
	-- This is triggered by .Activated. 
	-- To implement long-press and double-click accurately, 
	-- we'll shift to using InputBegan/InputEnded.
end)

-- The GridGenerator's buttons already have .Activated. 
-- Since we want to intercept those, let's overwrite the handler.

-- Redefine interaction flow:
local function onCellInputBegan(cell)
	pressStartTime = tick()
	pressCell = cell
end

local function onCellInputEnded(cell)
	local duration = tick() - pressStartTime
	local now = tick()
	
	if duration >= LONG_PRESS_THRESHOLD then
		-- LONG PRESS -> FLAG
		toggleFlag(cell.Row, cell.Column)
		playSfx()
	elseif now - lastClickTime <= DOUBLE_CLICK_THRESHOLD and lastClickedCell == cell then
		-- DOUBLE CLICK -> REVEAL
		if not state.gameStarted then
			local cols, rows = grid:GetDimensions()
			state.minefield = GameLogic.generateMinefield({row = cell.Row, col = cell.Column}, rows, cols, state.target)
			state.gameStarted = true
			startTimer()
		end
		revealCell(cell.Row, cell.Column)
		playSfx()
	else
		-- SINGLE CLICK -> ACTION MENU
		createActionMenu(cell)
	end
	
	lastClickTime = now
	lastClickedCell = cell
end

-- To integrate this with GridGenerator, we need to connect to 
-- individual buttons since they are created dynamically.
-- We will add a method to GridGenerator to connect these.
grid:ForEachCell(function(cell)
	cell.Button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			onCellInputBegan(cell)
		end
	end)
	cell.Button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			onCellInputEnded(cell)
		end
	end)
end)

--=========================================================
-- 14. WIRING: SOUND BUTTON
--=========================================================
soundButton.Activated:Connect(function()
	state.muted = not state.muted
	soundIcon.Text = state.muted and "🔇" or "🔊"
	soundIcon.TextColor3 = state.muted and Theme.TextDim or Theme.Text
	soundButton.BackgroundTransparency = state.muted and 0.4 or 0
	if not state.muted then playSfx() end
end)

--=========================================================
-- 15. WIRING: MENU BUTTON (placeholder)
--=========================================================
menuButton.Activated:Connect(function()
	playSfx()
	print("[UI] Menu hamburger ditekan — TODO: buka pause panel")
end)

--=========================================================
-- 16. WIRING: DROPDOWN
--=========================================================
local dropdownOptionButtons = {}
for _, child in ipairs(dropdownMenu:GetChildren()) do
	if child:IsA("TextButton") then
		dropdownOptionButtons[child.Name:gsub("^Option_", "")] = child
	end
end

local function openDropdown()
	state.dropdownOpen = true
	dropdownBackdrop.Visible = true
	dropdownMenu.Visible = true
end

local function closeDropdown()
	state.dropdownOpen = false
	dropdownBackdrop.Visible = false
	dropdownMenu.Visible = false
end

difficultyButton.Activated:Connect(function()
	if state.dropdownOpen then closeDropdown() else openDropdown() end
end)

dropdownBackdrop.Activated:Connect(closeDropdown)

--=========================================================
-- 17. GAME FLOW
--=========================================================
local function findDifficulty(name)
	for _, d in ipairs(DIFFICULTIES) do
		if d.Name == name then return d end
	end
	return DIFFICULTIES[1]
end

local function startGame(difficultyData)
	grid:Build(difficultyData.Columns, difficultyData.Rows, 2)
	state.currentDifficulty = difficultyData.Name
	state.target = difficultyData.Targets
	state.filled = 0
	state.completed = false
	state.gameStarted = false
	state.gameEnded = false
	state.minefield = nil
	state.revealedSet = {}
	difficultyLabel.Text = difficultyData.Name
	progressLabel.Text = string.format("0 / %d", difficultyData.Targets)
	timerLabel.Text = "000"
	for name, btn in pairs(dropdownOptionButtons) do
		btn.BackgroundTransparency = (name == difficultyData.Name) and 0 or 0.35
	end
	stopTimer()
end

for name, btn in pairs(dropdownOptionButtons) do
	btn.Activated:Connect(function()
		closeDropdown()
		playSfx()
		startGame(findDifficulty(name))
	end)
end

--=========================================================
-- 18. MULAI GAME
--=========================================================
startGame(findDifficulty(DEFAULT_DIFFICULTY))

(End of file - total 519 lines)
</content>