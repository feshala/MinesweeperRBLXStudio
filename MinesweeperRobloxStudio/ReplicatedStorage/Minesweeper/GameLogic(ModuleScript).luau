--[[
	GameLogic (ModuleScript)
	Path: ReplicatedStorage > Minesweeper > GameLogic

	Handles the core Minesweeper game mechanics:
	- Bomb generation (guaranteeing first click safety)
	- Proximity calculation
	- Flood fill reveal logic
	- Win/Loss condition checking
--]]

local GameLogic = {}

--=========================================================
-- TYPES & CONSTANTS
--=========================================================
-- We use a coordinate system {row, col}
type Pos = { row: number, col: number }

local DIRECTIONS = {
	{ -1, -1 }, { -1, 0 }, { -1, 1 },
	{ 0, -1 },           { 0, 1 },
	{ 1, -1 },  { 1, 0 },  { 1, 1 },
}

--=========================================================
-- PRIVATE HELPERS
--=========================================================

-- Check if coordinates are within the grid boundaries
local function isValidPos(pos, rows, cols)
	return pos.row >= 1 and pos.row <= rows and pos.col >= 1 and pos.col <= cols
end

-- Get all valid neighboring positions
local function getNeighbors(pos, rows, cols)
	local neighbors = {}
	for _, dir in ipairs(DIRECTIONS) do
		local neighborPos = { row = pos.row + dir[1], col = pos.col + dir[2] }
		if isValidPos(neighborPos, rows, cols) then
			table.insert(neighbors, neighborPos)
		end
	end
	return neighbors
end

--=========================================================
-- PUBLIC API
--=========================================================

--- Generates the minefield
--- @param firstClick Pos The position of the first click to ensure it's not a bomb
--- @param rows number
--- @param cols number
--- @param mineCount number
function GameLogic.generateMinefield(firstClick, rows, cols, mineCount)
	local minefield = {}
	for r = 1, rows do
		minefield[r] = table.create(cols, false)
	end

	local placedMines = 0
	while placedMines < mineCount do
		local r = math.random(1, rows)
		local c = math.random(1, cols)

		-- Rule: No mine at first click, and no duplicate mines
		if (r ~= firstClick.row or c ~= firstClick.col) and not minefield[r][c] then
			minefield[r][c] = true
			placedMines += 1
		end
	end

	return minefield
end

--- Calculates how many mines are adjacent to a specific cell
--- @param pos Pos
--- @param minefield table 2D array of booleans
function GameLogic.calculateProximity(pos, minefield)
	local count = 0
	-- We only need to check the 8 neighbors
	for _, dir in ipairs(DIRECTIONS) do
		local r, c = pos.row + dir[1], pos.col + dir[2]
		-- CRITICAL FIX: Boundary check. 
		-- Ensure the row index exists and the column index is within bounds.
		if minefield[r] and minefield[r][c] ~= nil then
			if minefield[r][c] == true then
				count += 1
			end
		end
	end
	return count
end

--- Recursive Flood Fill for revealing empty cells
--- @param pos Pos
--- @param rows number
--- @param cols number
--- @param minefield table
--- @param revealedSet table A set tracking already revealed cells to prevent infinite recursion
--- @param callback function(pos, proximity) Called for every cell that needs to be revealed
function GameLogic.floodFill(pos, rows, cols, minefield, revealedSet, callback)
	-- Use a key for the set to track visited cells
	local key = pos.row .. "_" .. pos.col
	if revealedSet[key] then return end
	revealedSet[key] = true

	-- Calculate proximity for current cell
	local proximity = GameLogic.calculateProximity(pos, minefield)
	
	-- Trigger the callback to reveal this cell visually
	callback(pos, proximity)

	-- If the cell is "empty" (0 neighboring bombs), recursively reveal neighbors
	if proximity == 0 then
		local neighbors = getNeighbors(pos, rows, cols)
		for _, neighbor in ipairs(neighbors) do
			GameLogic.floodFill(neighbor, rows, cols, minefield, revealedSet, callback)
		end
	end
end

--- Checks if the player has won the game
--- @param rows number
--- @param cols number
--- @param minefield table
--- @param revealedSet table
function GameLogic.checkWin(rows, cols, minefield, revealedSet)
	local totalCells = rows * cols
	local mineCount = 0
	for r = 1, rows do
		for c = 1, cols do
			if minefield[r][c] then mineCount += 1 end
		end
	end

	-- Player wins if all non-mine cells are revealed
	local revealedCount = 0
	for _ in pairs(revealedSet) do revealedCount += 1 end

	return revealedCount == (totalCells - mineCount)
end

return GameLogic
