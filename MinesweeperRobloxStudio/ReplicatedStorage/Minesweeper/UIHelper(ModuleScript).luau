--[[
	UIHelper (ModuleScript)
	Letak: ReplicatedStorage > Minesweeper > UIHelper

	Pustaka helper untuk pembuatan UI secara programatik (code-first).
	Menghindari pembuatan manual di Studio untuk konsistensi dan kemudahan modifikasi.
--]]

local UIHelper = {}

--=========================================================
-- THEME
--=========================================================
UIHelper.Theme = {
	-- Colors
	Background  = Color3.fromRGB(26, 42, 26),
	Panel       = Color3.fromRGB(34, 54, 34),
	PanelLight  = Color3.fromRGB(46, 70, 46),
	TileIdle    = Color3.fromRGB(119, 192, 70),
	TileFilled  = Color3.fromRGB(242, 201, 76),
	TileLocked  = Color3.fromRGB(70, 96, 66),
	Text        = Color3.fromRGB(240, 246, 236),
	TextDim     = Color3.fromRGB(168, 190, 162),
	Accent      = Color3.fromRGB(119, 192, 70),

	-- Fonts
	Font        = Enum.Font.GothamBold,
	FontMedium  = Enum.Font.GothamMedium,

	-- Font Sizes
	FontSize = {
		Small  = 12,
		Normal = 14,
		Large  = 16,
		Title  = 20,
		Huge   = 24,
	},
}

--=========================================================
-- PRIVATE HELPERS
--=========================================================

local function applyProperties(instance, props)
	if not props then return end
	for key, value in props do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
end

local function createParentProps(props, parent)
	local newProps = table.clone(props or {})
	newProps.Parent = parent
	return newProps
end

--=========================================================
-- CORE CREATOR
--=========================================================

--- Membuat instance UI secara generik.
--- @param className string Nama kelas Instance (e.g. "Frame")
--- @param props table Properti yang akan diterapkan
--- @param children table Daftar child Instance
function UIHelper.create(className, props, children)
	local instance = Instance.new(className)
	applyProperties(instance, props)

	if children then
		for _, child in children do
			child.Parent = instance
		end
	end

	-- Set Parent terakhir untuk optimasi rendering
	if props and props.Parent then
		instance.Parent = props.Parent
	end

	return instance
end

--=========================================================
-- SHORTCUTS
--=========================================================
function UIHelper.frame(props, children)       return UIHelper.create("Frame", props, children) end
function UIHelper.label(props, children)       return UIHelper.create("TextLabel", props, children) end
function UIHelper.button(props, children)      return UIHelper.create("TextButton", props, children) end
function UIHelper.image(props, children)       return UIHelper.create("ImageLabel", props, children) end
function UIHelper.screenGui(props, children)   return UIHelper.create("ScreenGui", props, children) end

--=========================================================
-- MODIFIERS
--=========================================================

function UIHelper.corner(radius, parent)
	local cornerRadius = type(radius) == "number" and UDim.new(0, radius) or radius or UDim.new(0, 8)
	return UIHelper.create("UICorner", createParentProps({ CornerRadius = cornerRadius }, parent))
end

function UIHelper.padding(uniform, parent)
	if type(uniform) == "table" then 
		return UIHelper.create("UIPadding", createParentProps(uniform, parent)) 
	end
	
	local p = type(uniform) == "number" and UDim.new(0, uniform) or uniform or UDim.new(0, 0)
	return UIHelper.create("UIPadding", createParentProps({
		PaddingTop = p, PaddingBottom = p,
		PaddingLeft = p, PaddingRight = p,
	}, parent))
end

function UIHelper.listLayout(props, parent)
	return UIHelper.create("UIListLayout", createParentProps(props or {}, parent))
end

function UIHelper.gridLayout(props, parent)
	return UIHelper.create("UIGridLayout", createParentProps(props or {}, parent))
end

function UIHelper.uiScale(scale, parent)
	return UIHelper.create("UIScale", createParentProps({ Scale = scale or 1 }, parent))
end

function UIHelper.aspectRatio(props, parent)
	return UIHelper.create("UIAspectRatioConstraint", createParentProps(props or {}, parent))
end

function UIHelper.stroke(props, parent)
	return UIHelper.create("UIStroke", createParentProps(props or {}, parent))
end

return UIHelper
