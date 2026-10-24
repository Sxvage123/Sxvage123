-- Shows a brainrot character inside UI (a ViewportFrame with a framed camera).
local BrainrotModels = require(script.Parent.BrainrotModels)

local ModelView = {}

-- First word of a display name -> model id, so any game can show a figure from just a name.
local KEYWORDS = {
	noobini = "noobini", pizzanini = "noobini", lirili = "lirili", tim = "tim_cheese", fluriflura = "fluri",
	talpa = "talpa", svinina = "svinina", pipi = "pipi_kiwi", trippi = "trippi", tung = "tung", sahur = "tung",
	gangster = "gangster", brr = "patapim", patapim = "patapim", chimpanzini = "chimpanzini", ballerina = "ballerina",
	cappuccino = "cappuccino", frigo = "frigo", bombardiro = "bombardiro", orangutini = "orangutini",
	cocofanto = "cocofanto", tralalero = "tralalero", odin = "odin_din", la = "la_vacca", vacca = "la_vacca",
	garama = "garama", madundung = "garama", skibidi = "skibidi", rizzler = "skibidi", sigma = "skibidi",
	golden = "tung", rainbow = "tralalero", void = "skibidi", gyatt = "trippi",
}

-- Returns a model id for an id or display name, or nil.
function ModelView.Resolve(idOrName: string): string?
	if BrainrotModels.Has(idOrName) then
		return BrainrotModels.Resolve(idOrName)
	end
	for word in string.gmatch(string.lower(idOrName), "%a+") do
		local id = KEYWORDS[word]
		if id then
			return id
		end
	end
	return nil
end

-- Creates a ViewportFrame showing the character (or nil if there is no model for it).
function ModelView.new(idOrName: string, props: { [string]: any }?, tint: Color3?): ViewportFrame?
	local id = ModelView.Resolve(idOrName)
	if not id then
		return nil
	end
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(170, 170, 180)
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.LightDirection = Vector3.new(-1, -1.5, 1)
	vp.Size = UDim2.fromScale(1, 1)
	local model, root = BrainrotModels.Build(id, { Tint = tint })
	model.Parent = vp
	local size = root.Size
	local radius = math.max(size.X, size.Y, size.Z)
	local center = root.Position
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.lookAt(center + Vector3.new(radius * 0.9, radius * 0.35, -radius * 1.6), center)
	camera.Parent = vp
	vp.CurrentCamera = camera
	if props then
		for k, v in props do
			(vp :: any)[k] = v
		end
	end
	return vp
end

return ModelView
