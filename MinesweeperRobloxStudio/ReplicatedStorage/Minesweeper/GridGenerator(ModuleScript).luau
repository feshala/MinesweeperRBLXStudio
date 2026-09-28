--[[
	GridGenerator  (ModuleScript)
	Letak: ReplicatedStorage > Shared > GridGenerator

	Membuat grid cell secara otomatis ke dalam frame target, menyimpan
	state 2D array, dan menyediakan API untuk game logic.
--]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIHelper = require(ReplicatedStorage:WaitForChild("Minesweeper"):WaitForChild("UIHelper"))
local Theme = UIHelper.Theme

local GridGenerator = {}
GridGenerator.__index = GridGenerator

GridGenerator.State = {
	Empty     = "Empty",     -- Hidden
	Revealed  = "Revealed",  -- Opened (shows number or empty)
	Flagged   = "Flagged",   -- Marked with flag
	Bomb      = "Bomb",      -- Game Over bomb
}

local COLOR_TWEEN = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--=========================================================
-- CONSTRUCTOR
--=========================================================
function GridGenerator.new(gridFrame)
	local self = setmetatable({}, GridGenerator)

	self._frame    = gridFrame
	self._columns  = 0
	self._rows     = 0
	self._cells    = {}
	self._callbacks = {}
	self._rightClickCallbacks = {}

	self._layout = gridFrame:FindFirstChildOfClass("UIGridLayout")
	if not self._layout then
		self._layout = UIHelper.gridLayout({
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			StartCorner = Enum.StartCorner.TopLeft,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			CellPadding = UDim2.new(0, 0, 0, 0),
		}, gridFrame)
	end

	self._aspect = gridFrame:FindFirstChildOfClass("UIAspectRatioConstraint")
	if not self._aspect then
		self._aspect = UIHelper.aspectRatio({
			AspectType = Enum.AspectType.FitWithinMaxSize,
			DominantAxis = Enum.DominantAxis.Width,
		}, gridFrame)
	end

	return self
end

--=========================================================
-- PRIVATE
--=========================================================
function GridGenerator:_clear()
	for _, child in ipairs(self._frame:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	table.clear(self._cells)
	table.clear(self._callbacks)
	table.clear(self._rightClickCallbacks)
end

function GridGenerator:_fireCellClicked(cellData)
	for i = 1, #self._callbacks do
		self._callbacks[i](cellData)
	end
end

function GridGenerator:_fireCellRightClicked(cellData)
	for i = 1, #self._rightClickCallbacks do
		self._rightClickCallbacks[i](cellData)
	end
end

function GridGenerator:_createCell(row, col, cellPadding)
	local button = Instance.new("TextButton")
	button.Name = string.format("Cell_%d_%d", row, col)
	button.Size = UDim2.fromScale(1 / self._columns, 1 / self._rows)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.AutoButtonColor = false
	button.LayoutOrder = (row - 1) * self._columns + col
	button.ZIndex = 1

	local pad = Instance.new("UIPadding")
	pad.PaddingTop    = UDim.new(0, cellPadding)
	pad.PaddingBottom = UDim.new(0, cellPadding)
	pad.PaddingLeft   = UDim.new(0, cellPadding)
	pad.PaddingRight  = UDim.new(0, cellPadding)
	pad.Parent = button

	local tile = Instance.new("Frame")
	tile.Name = "Tile"
	tile.Size = UDim2.fromScale(1, 1)
	tile.BackgroundColor3 = Theme.TileIdle
	tile.BorderSizePixel = 0
	tile.Parent = button

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = tile

	-- Indicator for numbers, bombs, flags
	local indicator = UIHelper.label({
		Name = "Indicator",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Theme.Text,
		TextSize = Theme.FontSize.Normal,
		Font = Theme.FontBold,
		ZIndex = 2,
		Parent = tile,
	})

	button.Parent = self._frame

	local cellData = {
		Row = row,
		Column = col,
		Button = button,
		Tile = tile,
		Indicator = indicator,
		State = GridGenerator.State.Empty,
		Tween = nil,
	}

	button.Activated:Connect(function()
		self:_fireCellClicked(cellData)
	end)

	button.MouseButton2Click:Connect(function()
		self:_fireCellRightClicked(cellData)
	end)

	return cellData
end

function GridGenerator:_colorForState(state)
	if state == GridGenerator.State.Revealed then return Theme.PanelLight end
	if state == GridGenerator.State.Bomb then return Color3.fromRGB(200, 50, 50) end
	return Theme.TileIdle
end

function GridGenerator:_applyVisual(cellData, animate)
	local targetColor = self:_colorForState(cellData.State)

	if cellData.Tween then
		cellData.Tween:Cancel()
		cellData.Tween = nil
	end

	if animate then
		cellData.Tween = TweenService:Create(cellData.Tile, COLOR_TWEEN, {
			BackgroundColor3 = targetColor,
		})
		cellData.Tween:Play()
	else
		cellData.Tile.BackgroundColor3 = targetColor
	end
end

--=========================================================
-- PUBLIC API
--=========================================================
function GridGenerator:Build(columns, rows, cellPadding)
	columns = columns or 10
	rows = rows or 15
	cellPadding = cellPadding or 2
	assert(columns > 0 and rows > 0, "Dimensi grid harus > 0")

	self:_clear()
	self._columns = columns
	self._rows = rows

	self._layout.CellSize = UDim2.fromScale(1 / columns, 1 / rows)
	self._layout.FillDirectionMaxCells = columns
	self._aspect.AspectRatio = columns / rows

	self._cells = table.create(rows)
	for row = 1, rows do
		local rowCells = table.create(columns)
		for col = 1, columns do
			rowCells[col] = self:_createCell(row, col, cellPadding)
		end
		self._cells[row] = rowCells
	end
end

function GridGenerator:OnCellClicked(callback)
	table.insert(self._callbacks, callback)
	return function()
		local i = table.find(self._callbacks, callback)
		if i then table.remove(self._callbacks, i) end
	end
end

function GridGenerator:OnCellRightClicked(callback)
	table.insert(self._rightClickCallbacks, callback)
	return function()
		local i = table.find(self._rightClickCallbacks, callback)
		if i then table.remove(self._rightClickCallbacks, i) end
	end
end

function GridGenerator:GetCell(row, col)
	local rowCells = self._cells[row]
	return rowCells and rowCells[col] or nil
end

function GridGenerator:SetCellState(row, col, state, animate)
	local cellData = self:GetCell(row, col)
	if not cellData then return end
	cellData.State = state
	self:_applyVisual(cellData, animate)
end

--- Update the indicator text (number, bomb, flag)
function GridGenerator:SetCellIndicator(row, col, text)
	local cellData = self:GetCell(row, col)
	if cellData then
		cellData.Indicator.Text = text
	end
end

function GridGenerator:GetCellState(row, col)
	local cellData = self:GetCell(row, col)
	return cellData and cellData.State or nil
end

function GridGenerator:ForEachCell(callback)
	for row = 1, self._rows do
		local rowCells = self._cells[row]
		for col = 1, self._columns do
			callback(rowCells[col])
		end
	end
end

function GridGenerator:CountState(state)
	local total = 0
	for row = 1, self._rows do
		local rowCells = self._cells[row]
		for col = 1, self._columns do
			if rowCells[col].State == state then
				total += 1
			end
		end
	end
	return total
end

function GridGenerator:Reset(animate)
	self:ForEachCell(function(cellData)
		cellData.State = GridGenerator.State.Empty
		self:_applyVisual(cellData, animate)
		cellData.Indicator.Text = ""
	end)
end

function GridGenerator:GetDimensions()
	return self._columns, self._rows
end

function GridGenerator:Destroy()
	self:_clear()
	setmetatable(self, nil)
end

return GridGenerator
