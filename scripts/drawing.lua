local xcloneref = function(v) return v end
local xclonefunction = function(v) return v end

-- // Variables
local TextService = xcloneref(game:GetService("TextService"))
local HttpService = xcloneref(game:GetService("HttpService"))

local HttpGet = xclonefunction(senv.httpget)
local GetTextBoundsAsync = xclonefunction(TextService.GetTextBoundsAsync)

-- // Drawing
local Drawing = {}

Drawing.__CLASSES = {}
Drawing.__OBJECT_CACHE = {}
Drawing.__IMAGE_CACHE = {}

Drawing.Font = {
    Count = 0,
    Fonts = {},
    Enums = {}
}

function Drawing.new(class)
    if not Drawing.__CLASSES[class] then
        error(`Invalid argument #1, expected a valid drawing type`, 2)
    end

    return Drawing.__CLASSES[class].new()
end

function Drawing.Font.new(FontName, FontData)

    local FontID = Drawing.Font.Count
    local FontObject

    Drawing.Font.Count += 1
    Drawing.Font.Fonts[FontName] = FontID

    if string.sub(FontData, 1, 11) == "rbxasset://" then
        FontObject = Font.new(FontData, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    else
        --[[ lets not use custom fonts, they're too resourceful. sorryyy ]]
        FontObject = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        --[[
        local TempPath = HttpService:GenerateGUID(false)

        if not senv.isfile(FontData) then
            senv.writefile(`DrawingFontCache/{FontName}.ttf`, senv.crypt.base64.decode(FontData))
            FontData = `DrawingFontCache/{FontName}.ttf`
        end
    
        senv.writefile(TempPath, HttpService:JSONEncode({
            ["name"] = FontName,
            ["faces"] = {
                {
                    ["name"] = "Regular",
                    ["weight"] = 100,
                    ["style"] = "normal",
                    ["assetId"] = senv.getcustomasset(FontData)
                }
            }
        }))

        FontObject = Font.new(senv.getcustomasset(TempPath), Enum.FontWeight.Regular, Enum.FontStyle.Normal)

        senv.delfile(TempPath)
        ]]
    end

    if not FontObject then
        error("Internal Error while creating new font.", 2)
    end

    Drawing.__TEXT_BOUND_PARAMS.Text = "Text"
    Drawing.__TEXT_BOUND_PARAMS.Size = 12
    Drawing.__TEXT_BOUND_PARAMS.Font = FontObject
    Drawing.__TEXT_BOUND_PARAMS.Width = math.huge

    GetTextBoundsAsync(TextService, Drawing.__TEXT_BOUND_PARAMS) -- Preload/Cache font for GetTextBoundsAsync to avoid yielding across metamethods

    Drawing.Font.Enums[FontID] = FontObject

    return FontObject
end

function Drawing.CreateInstance(class, properties, children)
    local object = Instance.new(class)

    for property, value in properties or {} do
        object[property] = value
    end

    for idx, child in children or {} do
        child.Parent = object
    end

    return object
end

function Drawing.ClearCache()
    for idx, object in Drawing.__OBJECT_CACHE do
        if rawget(object, "__OBJECT_EXISTS") then
            object:Remove()
        end
    end
end

function Drawing.UpdatePosition(object, from, to, thickness)
    local center = (from + to) / 2
    local offset = to - from

    object.Position = UDim2.fromOffset(center.X, center.Y)
    object.Size = UDim2.fromOffset(offset.Magnitude, thickness)
    object.Rotation = math.atan2(offset.Y, offset.X) * 180 / math.pi
end

Drawing.__ROOT = Drawing.CreateInstance("ScreenGui", {
    IgnoreGuiInset = true,
    DisplayOrder = 10,
    Name = HttpService:GenerateGUID(false),
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = senv.gethui()
})

Drawing.__TEXT_BOUND_PARAMS = Drawing.CreateInstance("GetTextBoundsParams", { Width = math.huge })

--#region Line
local Line = {}

Drawing.__CLASSES["Line"] = Line

function Line.new()
    local LineObject = setmetatable({
        __OBJECT_EXISTS = true,
        __PROPERTIES = {
            Color = Color3.new(0, 0, 0),
            From = Vector2.zero,
            To = Vector2.zero,
            Thickness = 1,
            Transparency = 1,
            ZIndex = 0,
            Visible = false
        },
        __OBJECT = Drawing.CreateInstance("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.new(0, 0, 0),
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 0, 0, 0),
            BorderSizePixel = 0,
            ZIndex = 0,
            Visible = false,
            Parent = Drawing.__ROOT
        })
    }, Line)

    table.insert(Drawing.__OBJECT_CACHE, LineObject)

    return LineObject
end

function Line:__index(property)
    local value = self.__PROPERTIES[property]

    if value ~= nil then
        return value
    end

    return Line[property]
end

function Line:__newindex(property, value)
    if not self.__OBJECT_EXISTS then
        return error("Attempt to modify drawing that no longer exists!", 2)
    end

    local Properties = self.__PROPERTIES

    Properties[property] = value

    if property == "Color" then
        self.__OBJECT.BackgroundColor3 = value
    elseif property == "From" then
        Drawing.UpdatePosition(self.__OBJECT, Properties.From, Properties.To, Properties.Thickness)
    elseif property == "To" then
        Drawing.UpdatePosition(self.__OBJECT, Properties.From, Properties.To, Properties.Thickness)
    elseif property == "Thickness" then
        self.__OBJECT.Size = UDim2.fromOffset(self.__OBJECT.AbsoluteSize.X, math.max(value, 1))
    elseif property == "Transparency" then
        self.__OBJECT.Transparency = math.clamp(1 - value, 0, 1)
    elseif property == "Visible" then
        self.__OBJECT.Visible = value
    elseif property == "ZIndex" then
        self.__OBJECT.ZIndex = value
    end
end

function Line:__iter()
    return next, self.__PROPERTIES
end

function Line:__tostring()
    return "Drawing"
end

function Line:Remove()
    self.__OBJECT_EXISTS = false
    self.__OBJECT.Destroy(self.__OBJECT)
    table.remove(Drawing.__OBJECT_CACHE, table.find(Drawing.__OBJECT_CACHE, self))
end

function Line:Destroy()
    self:Remove()
end
--#endregion

--#region Circle
local Circle = {}

Drawing.__CLASSES["Circle"] = Circle

function Circle.new()
    local CircleObject = setmetatable({
        __OBJECT_EXISTS = true,
        __PROPERTIES = {
            Color = Color3.new(0, 0, 0),
            Position = Vector2.new(0, 0),
            NumSides = 0,
            Radius = 0,
            Thickness = 1,
            Transparency = 1,
            ZIndex = 0,
            Filled = false,
            Visible = false
        },
        __OBJECT = Drawing.CreateInstance("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.new(0, 0, 0),
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 0, 0, 0),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            ZIndex = 0,
            Visible = false,
            Parent = Drawing.__ROOT
        }, {
            Drawing.CreateInstance("UICorner", {
                Name = "_CORNER",
                CornerRadius = UDim.new(1, 0)
            }),
            Drawing.CreateInstance("UIStroke", {
                Name = "_STROKE",
                Color = Color3.new(0, 0, 0),
                Thickness = 1
            })
        }),
    }, Circle)

    table.insert(Drawing.__OBJECT_CACHE, CircleObject)

    return CircleObject
end

function Circle:__index(property)
    local value = self.__PROPERTIES[property]

    if value ~= nil then
        return value
    end

    return Circle[property]
end

function Circle:__newindex(property, value)
    if not self.__OBJECT_EXISTS then
        return error("Attempt to modify drawing that no longer exists!", 2)
    end

    local Properties = self.__PROPERTIES

    Properties[property] = value

    if property == "Color" then
        self.__OBJECT.BackgroundColor3 = value
        self.__OBJECT._STROKE.Color = value
    elseif property == "Filled" then
        self.__OBJECT.BackgroundTransparency = value and 1 - Properties.Transparency or 1
    elseif property == "Position" then
        self.__OBJECT.Position = UDim2.fromOffset(value.X, value.Y)
    elseif property == "Radius" then
        self:__UPDATE_RADIUS()
    elseif property == "Thickness" then
        self:__UPDATE_RADIUS()
    elseif property == "Transparency" then
        self.__OBJECT._STROKE.Transparency = math.clamp(1 - value, 0, 1)
        self.__OBJECT.Transparency = Properties.Filled and math.clamp(1 - value, 0, 1) or self.__OBJECT.Transparency
    elseif property == "Visible" then
        self.__OBJECT.Visible = value
    elseif property == "ZIndex" then
        self.__OBJECT.ZIndex = value
    end
end

function Circle:__iter()
    return next, self.__PROPERTIES
end

function Circle:__tostring()
    return "Drawing"
end

function Circle:__UPDATE_RADIUS()
    local diameter = (self.__PROPERTIES.Radius * 2) - (self.__PROPERTIES.Thickness * 2)
    self.__OBJECT.Size = UDim2.fromOffset(diameter, diameter)
end

function Circle:Remove()
    self.__OBJECT_EXISTS = false
    self.__OBJECT.Destroy(self.__OBJECT)
    table.remove(Drawing.__OBJECT_CACHE, table.find(Drawing.__OBJECT_CACHE, self))
end

function Circle:Destroy()
    self:Remove()
end
--#endregion

--#region Text
local Text = {}

Drawing.__CLASSES["Text"] = Text

function Text.new()
    local TextObject = setmetatable({
        __OBJECT_EXISTS = true,
        __PROPERTIES = {
            Color = Color3.new(1, 1, 1),
            OutlineColor = Color3.new(0, 0, 0),
            Position = Vector2.new(0, 0),
            TextBounds = Vector2.new(0, 0),
            Text = "",
            Font = Drawing.Font.Enums[2],
            Size = 13,
            Transparency = 1,
            ZIndex = 0,
            Center = false,
            Outline = false,
            Visible = false
        },
        __OBJECT = Drawing.CreateInstance("TextLabel", {
            TextColor3 = Color3.new(1, 1, 1),
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 0, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            FontFace = Drawing.Font.Enums[1],
            TextSize = 12,
            BackgroundTransparency = 1,
            ZIndex = 0,
            Visible = false,
            Parent = Drawing.__ROOT
        }, {
            Drawing.CreateInstance("UIStroke", {
                Name = "_STROKE",
                Color = Color3.new(0, 0, 0),
                LineJoinMode = Enum.LineJoinMode.Miter,
                Enabled = false,
                Thickness = 1
            })
        })
    }, Text)

    table.insert(Drawing.__OBJECT_CACHE, TextObject)

    return TextObject
end

function Text:__index(property)
    local value = self.__PROPERTIES[property]

    if value ~= nil then
        return value
    end

    return Text[property]
end

function Text:__newindex(property, value)
    if not self.__OBJECT_EXISTS then
        return error("Attempt to modify drawing that no longer exists!", 2)
    end

    if value == "TextBounds" then
        error("Attempt to modify read-only property", 2)
    end

    local Properties = self.__PROPERTIES

    Properties[property] = value

    if property == "Color" then
        self.__OBJECT.TextColor3 = value
    elseif property == "Position" then
        self.__OBJECT.Position = UDim2.fromOffset(value.X, value.Y)
    elseif property == "Size" then
        self.__OBJECT.TextSize = value - 1
        self:_UPDATE_TEXT_BOUNDS()
    elseif property == "Text" then
        self.__OBJECT.Text = value
        self:_UPDATE_TEXT_BOUNDS()
    elseif property == "Font" then
        if type(value) == "string" then
            value = Drawing.Font.Enums[Drawing.Font.Fonts[value]]
        elseif type(value) == "number" then
            value = Drawing.Font.Enums[value]
        end

        Properties.Font = value

        self.__OBJECT.FontFace = value
        self:_UPDATE_TEXT_BOUNDS()
    elseif property == "Outline" then
        self.__OBJECT._STROKE.Enabled = value
    elseif property == "OutlineColor" then
        self.__OBJECT._STROKE.Color = value
    elseif property == "Center" then
        self.__OBJECT.TextXAlignment = value and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
    elseif property == "Transparency" then
        self.__OBJECT.Transparency = math.clamp(1 - value, 0, 1)
    elseif property == "Visible" then
        self.__OBJECT.Visible = value
    elseif property == "ZIndex" then
        self.__OBJECT.ZIndex = value
    end
end

function Text:__iter()
    return next, self.__PROPERTIES
end

function Text:__tostring()
    return "Drawing"
end

function Text:_UPDATE_TEXT_BOUNDS()
    local Properties = self.__PROPERTIES

    Drawing.__TEXT_BOUND_PARAMS.Text = Properties.Text
    Drawing.__TEXT_BOUND_PARAMS.Size = Properties.Size - 1
    Drawing.__TEXT_BOUND_PARAMS.Font = Properties.Font
    Drawing.__TEXT_BOUND_PARAMS.Width = math.huge

    Properties.TextBounds = GetTextBoundsAsync(TextService, Drawing.__TEXT_BOUND_PARAMS)
end

function Text:Remove()
    self.__OBJECT_EXISTS = false
    self.__OBJECT.Destroy(self.__OBJECT)
    table.remove(Drawing.__OBJECT_CACHE, table.find(Drawing.__OBJECT_CACHE, self))
end

function Text:Destroy()
    self:Remove()
end
--#endregion

--#region Square
local Square = {}

Drawing.__CLASSES["Square"] = Square

function Square.new()
    local SquareObject = setmetatable({
        __OBJECT_EXISTS = true,
        __PROPERTIES = {
            Color = Color3.new(0, 0, 0),
            Position = Vector2.new(0, 0),
            Size = Vector2.new(0, 0),
            Rounding = 0,
            Thickness = 0,
            Transparency = 1,
            ZIndex = 0,
            Filled = false,
            Visible = false
        },
        __OBJECT = Drawing.CreateInstance("Frame", {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 0,
            Visible = false,
            Parent = Drawing.__ROOT
        }, {
            Drawing.CreateInstance("UIStroke", {
                Name = "_STROKE",
                Color = Color3.new(0, 0, 0),
                LineJoinMode = Enum.LineJoinMode.Miter,
                Thickness = 1
            }),
            Drawing.CreateInstance("UICorner", {
                Name = "_CORNER",
                CornerRadius = UDim.new(0, 0)
            })
        })
    }, Square)

    table.insert(Drawing.__OBJECT_CACHE, SquareObject)

    return SquareObject
end

function Square:__index(property)
    local value = self.__PROPERTIES[property]

    if value ~= nil then
        return value
    end

    return Square[property]
end

function Square:__newindex(property, value)
    if not self.__OBJECT_EXISTS then
        return error("Attempt to modify drawing that no longer exists!", 2)
    end

    local Properties = self.__PROPERTIES

    Properties[property] = value

    if property == "Color" then
        self.__OBJECT.BackgroundColor3 = value
        self.__OBJECT._STROKE.Color = value
    elseif property == "Position" then
        self:__UPDATE_SCALE()
    elseif property == "Size" then
        self:__UPDATE_SCALE()
    elseif property == "Thickness" then
        self.__OBJECT._STROKE.Thickness = value
        self.__OBJECT._STROKE.Enabled = not Properties.Filled
        self:__UPDATE_SCALE()
    elseif property == "Rounding" then
        self.__OBJECT._CORNER.CornerRadius = UDim.new(0, value)
    elseif property == "Filled" then
        self.__OBJECT._STROKE.Enabled = not value
        self.__OBJECT.BackgroundTransparency = value and 1 - Properties.Transparency or 1
    elseif property == "Transparency" then
        self.__OBJECT.Transparency = math.clamp(1 - value, 0, 1)
    elseif property == "Visible" then
        self.__OBJECT.Visible = value
    elseif property == "ZIndex" then
        self.__OBJECT.ZIndex = value
    end
end

function Square:__iter()
    return next, self.__PROPERTIES
end

function Square:__tostring()
    return "Drawing"
end

function Square:__UPDATE_SCALE()
    local Properties = self.__PROPERTIES

    self.__OBJECT.Position = UDim2.fromOffset(Properties.Position.X + Properties.Thickness, Properties.Position.Y + Properties.Thickness)
    self.__OBJECT.Size = UDim2.fromOffset(Properties.Size.X - Properties.Thickness * 2, Properties.Size.Y - Properties.Thickness * 2)
end

function Square:Remove()
    self.__OBJECT_EXISTS = false
    self.__OBJECT.Destroy(self.__OBJECT)
    table.remove(Drawing.__OBJECT_CACHE, table.find(Drawing.__OBJECT_CACHE, self))
end

function Square:Destroy()
    self:Remove()
end
--#endregion


--#region Image
local Image = {}

Drawing.__CLASSES["Image"] = Image

function Image.new()
    local ImageObject = setmetatable({
        __OBJECT_EXISTS = true,
        __PROPERTIES = {
            Color = Color3.new(0, 0, 0),
            Position = Vector2.new(0, 0),
            Size = Vector2.new(0, 0),
            Data = "",
            Uri = "",
            Thickness = 0,
            Transparency = 1,
            ZIndex = 0,
            Filled = false,
            Visible = false
        },
        __OBJECT = Drawing.CreateInstance("ImageLabel", {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            Image = "",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 0,
            Visible = false,
            Parent = Drawing.__ROOT
        }, {
            Drawing.CreateInstance("UICorner", {
                Name = "_CORNER",
                CornerRadius = UDim.new(0, 0)
            })
        })
    }, Image)

    table.insert(Drawing.__OBJECT_CACHE, ImageObject)

    return ImageObject
end

function Image:__index(property)
    local value = self.__PROPERTIES[property]

    if value ~= nil then
        return value
    end

    return Image[property]
end

function Image:__newindex(property, value)
    if not self.__OBJECT_EXISTS then
        return error("Attempt to modify drawing that no longer exists!", 2)
    end

    local Properties = self.__PROPERTIES

    Properties[property] = value

    if property == "Data" then
        self:__SET_IMAGE(value)
    elseif property == "Uri" then
        self:__SET_IMAGE(value, true)
    elseif property == "Rounding" then
        self.__OBJECT._CORNER.CornerRadius = UDim.new(0, value)
    elseif property == "Color" then
        self.__OBJECT.ImageColor3 = value
    elseif property == "Position" then
        self.__OBJECT.Position = UDim2.fromOffset(value.X, value.Y)
    elseif property == "Size" then
        self.__OBJECT.Size = UDim2.fromOffset(value.X, value.Y)
    elseif property == "Transparency" then
        self.__OBJECT.ImageTransparency = math.clamp(1 - value, 0, 1)
    elseif property == "Visible" then
        self.__OBJECT.Visible = value
    elseif property == "ZIndex" then
        self.__OBJECT.ZIndex = value
    end
end

function Image:__iter()
    return next, self.__PROPERTIES
end

function Image:__tostring()
    return "Drawing"
end

function Image:__SET_IMAGE(data, isUri)
    task.spawn(function()
        if isUri then
            data = HttpGet(game, data, true)
        end

        if not Drawing.__IMAGE_CACHE[data] then
            local TempPath = HttpService:GenerateGUID(false)

            senv.writefile(TempPath, data)
            Drawing.__IMAGE_CACHE[data] = senv.getcustomasset(TempPath)
            senv.delfile(TempPath)
        end

        self.__PROPERTIES.Data = Drawing.__IMAGE_CACHE[data]
        self.__OBJECT.Image = Drawing.__IMAGE_CACHE[data]
    end)
end

function Image:Remove()
    self.__OBJECT_EXISTS = false
    self.__OBJECT.Destroy(self.__OBJECT)
    table.remove(Drawing.__OBJECT_CACHE, table.find(Drawing.__OBJECT_CACHE, self))
end

function Image:Destroy()
    self:Remove()
end
--#endregion

--#region Triangle
local Triangle = {}

Drawing.__CLASSES["Triangle"] = Triangle

function Triangle.new()
    local TriangleObject = setmetatable({
        __OBJECT_EXISTS = true,
        __PROPERTIES = {
            Color = Color3.new(0, 0, 0),
            PointA = Vector2.new(0, 0),
            PointB = Vector2.new(0, 0),
            PointC = Vector2.new(0, 0),
            Thickness = 1,
            Transparency = 1,
            ZIndex = 0,
            Filled = false,
            Visible = false
        },
        __OBJECT = Drawing.CreateInstance("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ZIndex = 0,
            Visible = false,
            Parent = Drawing.__ROOT
        }, {
            Drawing.CreateInstance("Frame", {
                Name = "_A",
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 0, 0, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 0
            }),
            Drawing.CreateInstance("Frame", {
                Name = "_B",
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 0, 0, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 0
            }),
            Drawing.CreateInstance("Frame", {
                Name = "_C",
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 0, 0, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 0
            })
        })
    }, Triangle)

    table.insert(Drawing.__OBJECT_CACHE, TriangleObject)

    return TriangleObject
end

function Triangle:__index(property)
    local value = self.__PROPERTIES[property]

    if value ~= nil then
        return value
    end

    return Triangle[property]
end

function Triangle:__newindex(property, value)
    if not self.__OBJECT_EXISTS then
        return error("Attempt to modify drawing that no longer exists!", 2)
    end

    local Properties, Object = self.__PROPERTIES, self.__OBJECT

    Properties[property] = value

    if property == "Color" then
        Object._A.BackgroundColor3 = value
        Object._B.BackgroundColor3 = value
        Object._C.BackgroundColor3 = value
    elseif property == "Transparency" then
        Object._A.BackgroundTransparency = 1 - values
        Object._B.BackgroundTransparency = 1 - values
        Object._C.BackgroundTransparency = 1 - values
    elseif property == "Thickness" then
        Object._A.BackgroundColor3 = UDim2.fromOffset(Object._A.AbsoluteSize.X, math.max(value, 1));
        Object._B.BackgroundColor3 = UDim2.fromOffset(Object._B.AbsoluteSize.X, math.max(value, 1));
        Object._C.BackgroundColor3 = UDim2.fromOffset(Object._C.AbsoluteSize.X, math.max(value, 1));
    elseif property == "PointA" then
        self:__UPDATE_VERTICIES({
            { Object._A, Properties.PointA, Properties.PointB },
            { Object._C, Properties.PointC, Properties.PointA }
        })
    elseif property == "PointB" then
        self:__UPDATE_VERTICIES({
            { Object._A, Properties.PointA, Properties.PointB },
            { Object._B, Properties.PointB, Properties.PointC }
        })
    elseif property == "PointC" then
        self:__UPDATE_VERTICIES({
            { Object._B, Properties.PointB, Properties.PointC },
            { Object._C, Properties.PointC, Properties.PointA }
        })
    elseif property == "Visible" then
        Object.Visible = value
    elseif property == "ZIndex" then
        Object.ZIndex = value
    end
end

function Triangle:__iter()
    return next, self.__PROPERTIES
end

function Triangle:__tostring()
    return "Drawing"
end

function Triangle:__UPDATE_VERTICIES(verticies)
    local thickness = self.__PROPERTIES.Thickness

    for idx, verticy in verticies do
        Drawing.UpdatePosition(verticy[1], verticy[2], verticy[3], thickness)
    end
end

function Triangle:Remove()
    self.__OBJECT_EXISTS = false
    self.__OBJECT.Destroy(self.__OBJECT)
    table.remove(Drawing.__OBJECT_CACHE, table.find(Drawing.__OBJECT_CACHE, self))
end

function Triangle:Destroy()
    self:Remove()
end
--#endregion

--#region Quad
local Quad = {}

Drawing.__CLASSES["Quad"] = Quad

function Quad.new()
    local QuadObject = setmetatable({
        __OBJECT_EXISTS = true,
        __PROPERTIES = {
            Color = Color3.new(0, 0, 0),
            PointA = Vector2.new(0, 0),
            PointB = Vector2.new(0, 0),
            PointC = Vector2.new(0, 0),
            PointD = Vector2.new(0, 0),
            Thickness = 1,
            Transparency = 1,
            ZIndex = 0,
            Filled = false,
            Visible = false
        },
        __OBJECT = Drawing.CreateInstance("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ZIndex = 0,
            Visible = false,
            Parent = Drawing.__ROOT
        }, {
            Drawing.CreateInstance("Frame", {
                Name = "_A",
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 0, 0, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 0
            }),
            Drawing.CreateInstance("Frame", {
                Name = "_B",
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 0, 0, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 0
            }),
            Drawing.CreateInstance("Frame", {
                Name = "_C",
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 0, 0, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 0
            }),
            Drawing.CreateInstance("Frame", {
                Name = "_D",
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 0, 0, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 0
            })
        })
    }, Quad)

    table.insert(Drawing.__OBJECT_CACHE, QuadObject)

    return QuadObject
end

function Quad:__index(property)
    local value = self.__PROPERTIES[property]

    if value ~= nil then
        return value
    end

    return Quad[property]
end

function Quad:__newindex(property, value)
    if not self.__OBJECT_EXISTS then
        return error("Attempt to modify drawing that no longer exists!", 2)
    end

    local Properties, Object = self.__PROPERTIES, self.__OBJECT

    Properties[property] = value

    if property == "Color" then
        Object._A.BackgroundColor3 = value
        Object._B.BackgroundColor3 = value
        Object._C.BackgroundColor3 = value
        Object._D.BackgroundColor3 = value
    elseif property == "Transparency" then
        Object._A.BackgroundTransparency = 1 - values
        Object._B.BackgroundTransparency = 1 - values
        Object._C.BackgroundTransparency = 1 - values
        Object._D.BackgroundTransparency = 1 - values
    elseif property == "Thickness" then
        Object._A.BackgroundColor3 = UDim2.fromOffset(Object._A.AbsoluteSize.X, math.max(value, 1));
        Object._B.BackgroundColor3 = UDim2.fromOffset(Object._B.AbsoluteSize.X, math.max(value, 1));
        Object._C.BackgroundColor3 = UDim2.fromOffset(Object._C.AbsoluteSize.X, math.max(value, 1));
        Object._D.BackgroundColor3 = UDim2.fromOffset(Object._D.AbsoluteSize.X, math.max(value, 1));
    elseif property == "PointA" then
        self:__UPDATE_VERTICIES({
            { Object._A, Properties.PointA, Properties.PointB },
            { Object._D, Properties.PointD, Properties.PointA }
        })
    elseif property == "PointB" then
        self:__UPDATE_VERTICIES({
            { Object._A, Properties.PointA, Properties.PointB },
            { Object._B, Properties.PointB, Properties.PointC }
        })
    elseif property == "PointC" then
        self:__UPDATE_VERTICIES({
            { Object._B, Properties.PointB, Properties.PointC },
            { Object._C, Properties.PointC, Properties.PointD }
        })
    elseif property == "PointD" then
        self:__UPDATE_VERTICIES({
            { Object._C, Properties.PointC, Properties.PointD },
            { Object._D, Properties.PointD, Properties.PointA }
        })
    elseif property == "Visible" then
        Object.Visible = value
    elseif property == "ZIndex" then
        Object.ZIndex = value
    end
end

function Quad:__iter()
    return next, self.__PROPERTIES
end

function Quad:__tostring()
    return "Drawing"
end

function Quad:__UPDATE_VERTICIES(verticies)
    local thickness = self.__PROPERTIES.Thickness

    for idx, verticy in verticies do
        Drawing.UpdatePosition(verticy[1], verticy[2], verticy[3], thickness)
    end
end

function Quad:Remove()
    self.__OBJECT_EXISTS = false
    self.__OBJECT.Destroy(self.__OBJECT)
    table.remove(Drawing.__OBJECT_CACHE, table.find(Drawing.__OBJECT_CACHE, self))
end

function Quad:Destroy()
    self:Remove()
end
--#endregion

if not senv.isfolder("DrawingFontCache") then
    senv.makefolder("DrawingFontCache")
end

Drawing.Font.new("UI", "rbxasset://fonts/families/Arial.json")
Drawing.Font.new("System", "rbxasset://fonts/families/HighwayGothic.json")
Drawing.Font.new("Plex", "rbxasset://fonts/families/Arial.json")
Drawing.Font.new("Monospace", "rbxasset://fonts/families/RobotoMono.json")
Drawing.Font.new("Pixel", "rbxasset://fonts/families/Arial.json")

local cleardrawcache = Drawing.ClearCache
