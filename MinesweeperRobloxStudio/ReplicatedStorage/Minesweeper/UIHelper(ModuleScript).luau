--[[
	UIHelper  (ModuleScript)
	Letak: ReplicatedStorage > Shared > UIHelper

	Pustaka helper code-first. Semua elemen UI dibuat via Instance.new()
	lewat fungsi di bawah. Tidak ada satupun yang dibuat manual di Studio.

	Pola inti:
		UIHelper.frame(
			{ Size = ..., BackgroundColor3 = ... },   -- props
			{ childA, childB, childC }                -- children
		)
	Props di-loop, children ditempel, lalu Parent di-SET PALING AKHIR
	(optimasi render batch — subtree masuk sekaligus).
--]]

local UIHelper = {}

--=========================================================
-- THEME — Single Source of Truth
--=========================================================
UIHelper.Theme = {
	-- Warna (sesuai referensi: dark green + light green)
	Background  = Color3.fromRGB(26, 42, 26),
	Panel       = Color3.fromRGB(34, 54, 34),
	PanelLight  = Color3.fromRGB(46, 70, 46),
	TileIdle    = Color3.fromRGB(119, 192, 70),
	TileFilled  = Color3.fromRGB(242, 201, 76),
	TileLocked  = Color3.fromRGB(70, 96, 66),

	Text        = Color3.fromRGB(240, 246, 236),
	TextDim     = Color3.fromRGB(168, 190, 162),
	Accent      = Color3.fromRGB(119, 192, 70),

	-- Font
	Font        = Enum.Font.GothamBold,
	FontMedium  = Enum.Font.GothamMedium,

	-- Ukuran teks
	FontSize = {
		Small  = 12,
		Normal = 14,
		Large  = 16,
		Title  = 20,
		Huge   = 24,
	},
}

--=========================================================
-- INTERNAL
--=========================================================
local function applyProps(instance, props)
	if not props then return end
	for key, value in pairs(props) do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
end

local function cloneWithParent(props, parent)
	local copy = {}
	if props then
		for k, v in pairs(props) do copy[k] = v end
	end
	copy.Parent = parent
	return copy
end

--=========================================================
-- CORE CREATOR
--=========================================================
--- Membuat instance generik.
--- @param className string
--- @param props table|nil
--- @param children table|nil
function UIHelper.create(className, props, children)
	local inst = Instance.new(className)
	applyProps(inst, props)

	if children then
		for i = 1, #children do
			children[i].Parent = inst
		end
	end

	-- Parent LAST: subtree ter-attach sekaligus (1 render, bukan N).
	inst.Parent = props and props.Parent

	return inst
end

--=========================================================
-- SHORTCUT CREATORS
--=========================================================
function UIHelper.frame(props, children)       return UIHelper.create("Frame", props, children) end
function UIHelper.label(props, children)       return UIHelper.create("TextLabel", props, children) end
function UIHelper.button(props, children)      return UIHelper.create("TextButton", props, children) end
function UIHelper.image(props, children)       return UIHelper.create("ImageLabel", props, children) end
function UIHelper.screenGui(props, children)   return UIHelper.create("ScreenGui", props, children) end

--=========================================================
-- MODIFIER HELPERS
--=========================================================
--- UICorner. Terima number (offset px), UDim, atau nil (default 8px).
function UIHelper.corner(radius, parent)
	if type(radius) == "number" then radius = UDim.new(0, radius) end
	return UIHelper.create("UICorner", cloneWithParent({
		CornerRadius = radius or UDim.new(0, 8),
	}, parent))
end

--- UIPadding uniform. Terima number (px), UDim, atau tabel props lengkap.
function UIHelper.padding(uniform, parent)
	if type(uniform) == "table" then
		return UIHelper.create("UIPadding", cloneWithParent(uniform, parent))
	end
	if type(uniform) == "number" then uniform = UDim.new(0, uniform) end
	local u = uniform or UDim.new(0, 0)
	return UIHelper.create("UIPadding", cloneWithParent({
		PaddingTop = u, PaddingBottom = u,
		PaddingLeft = u, PaddingRight = u,
	}, parent))
end

function UIHelper.listLayout(props, parent)
	return UIHelper.create("UIListLayout", cloneWithParent(props or {}, parent))
end

function UIHelper.gridLayout(props, parent)
	return UIHelper.create("UIGridLayout", cloneWithParent(props or {}, parent))
end

function UIHelper.uiScale(scale, parent)
	return UIHelper.create("UIScale", cloneWithParent({ Scale = scale or 1 }, parent))
end

function UIHelper.aspectRatio(props, parent)
	return UIHelper.create("UIAspectRatioConstraint", cloneWithParent(props or {}, parent))
end

function UIHelper.stroke(props, parent)
	return UIHelper.create("UIStroke", cloneWithParent(props or {}, parent))
end

return UIHelper