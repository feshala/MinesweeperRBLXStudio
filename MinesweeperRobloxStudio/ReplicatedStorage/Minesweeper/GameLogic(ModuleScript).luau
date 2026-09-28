--[[
	GameLogic (ModuleScript)
	Path: ReplicatedStorage > Minesweeper > GameLogic

	Menangani logika inti permainan Minesweeper:
	- Generasi bom dengan jaminan klik pertama aman.
	- Kalkulasi jumlah bom di sekitar sel.
	- Algoritma Reveal (Flood Fill).
	- Pengecekan kondisi menang/kalah.
--]]

local GameLogic = {}

--=========================================================
-- CONSTANTS
--=========================================================
type Position = { row: number, col: number }

local DIRECTIONS = {
	{ -1, -1 }, { -1, 0 }, { -1, 1 },
	{ 0, -1 },           { 0, 1 },
	{ 1, -1 },  { 1, 0 },  { 1, 1 },
}

--=========================================================
-- PRIVATE HELPERS
--=========================================================

local function isWithinBounds(pos, rows, cols)
	return pos.row >= 1 and pos.row <= rows and pos.col >= 1 and pos.col <= cols
end

local function getValidNeighbors(pos, rows, cols)
	local neighbors = {}
	for _, dir in DIRECTIONS do
		local neighborPos = { row = pos.row + dir[1], col = pos.col + dir[2] }
		if isWithinBounds(neighborPos, rows, cols) then
			table.insert(neighbors, neighborPos)
		end
	end
	return neighbors
end

--=========================================================
-- PUBLIC API
--=========================================================

--- Membuat peta bom secara acak.
--- @param firstClick Position Posisi klik pertama (dijamin bukan bom).
--- @param rows number Jumlah baris.
--- @param cols number Jumlah kolom.
--- @param mineCount number Jumlah bom yang harus diletakkan.
function GameLogic.generateMinefield(firstClick, rows, cols, mineCount)
	local minefield = table.create(rows)
	for r = 1, rows do
		minefield[r] = table.create(cols, false)
	end

	local placedMines = 0
	while placedMines < mineCount do
		local r = math.random(1, rows)
		local c = math.random(1, cols)

		local isFirstClick = (r == firstClick.row and c == firstClick.col)
		if not isFirstClick and not minefield[r][c] then
			minefield[r][c] = true
			placedMines += 1
		end
	end

	return minefield
end

--- Menghitung jumlah bom di sekitar sel tertentu.
--- @param pos Position
--- @param minefield table Array 2D boolean.
function GameLogic.calculateProximity(pos, minefield)
	local count = 0
	for _, dir in DIRECTIONS do
		local r, c = pos.row + dir[1], pos.col + dir[2]
		if minefield[r] and minefield[r][c] == true then
			count += 1
		end
	end
	return count
end

--- Algoritma Flood Fill untuk membuka sel kosong secara rekursif.
--- @param pos Position
--- @param rows number
--- @param cols number
--- @param minefield table
--- @param revealedSet table Set untuk melacak sel yang sudah dibuka.
--- @param callback function Callback visual untuk setiap sel yang terbuka.
function GameLogic.floodFill(pos, rows, cols, minefield, revealedSet, callback)
	local key = string.format("%d_%d", pos.row, pos.col)
	if revealedSet[key] then return end
	revealedSet[key] = true

	local proximity = GameLogic.calculateProximity(pos, minefield)
	callback(pos, proximity)

	if proximity == 0 then
		for _, neighbor in getValidNeighbors(pos, rows, cols) do
			GameLogic.floodFill(neighbor, rows, cols, minefield, revealedSet, callback)
		end
	end
end

--- Mengecek apakah pemain telah memenangkan permainan.
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

	local revealedCount = 0
	for _ in revealedSet do revealedCount += 1 end

	return revealedCount == (totalCells - mineCount)
end

return GameLogic
