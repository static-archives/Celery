
local DrawingDict = Instance.new("ScreenGui", game:GetService("CoreGui")) -- For drawing.new
local Drawings = {} -- for cleardrawcache
local Fonts = { -- Drawing.Fonts
 [0] = Enum.Font.Arial,
 [1] = Enum.Font.BuilderSans,
 [2] = Enum.Font.Gotham,
 [3] = Enum.Font.RobotoMono
}
local Drawing = {};
Drawing.Fonts = {
  ['UI'] = 0,
  ['System'] = 1,
  ['Plex'] = 2,
  ['Monospace'] = 3
}
local function cleardrawcache()
    for _, v in pairs(Drawings) do
        v:Remove()
    end
    table.clear(Drawings)
end
local function isrenderobj(thing)
    return Drawings[thing] ~= nil
end
Drawing.new = function(Type) -- Drawing.new
    local baseProps = {
     Visible = false,
     Color = Color3.new(0,0,0),
     ClassName = nil
    }
    if Type == 'Line' then
        local a = Instance.new("Frame", Instance.new("ScreenGui", DrawingDict))
        a.Visible = false
        a.Size = UDim2.new(0, 0, 0, 0)
        a.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        a.BackgroundTransparency = 1
        a.BorderSizePixel = 0

        local meta = baseProps
        meta.ClassName = Type
        meta.__index = {
            Thickness = 1,
            From = Vector2.new(0, 0),
            To = Vector2.new(0, 0),
            Transparency = 0,
            Remove = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            Destroy = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            updateLine = function(self)
             if not a then return end
             local from = self.From
             local to = self.To
             local distance = (to - from).Magnitude
             local angle = math.deg(math.atan2(to.Y - from.Y, to.X - from.X))

             a.Size = UDim2.new(0, distance, 0, self.Thickness)
             a.Position = UDim2.new(0, from.X, 0, from.Y)
             a.Rotation = angle
            end
        }

        meta.__newindex = function(self, key, value)
            if not self then return end
            if key == 'Thickness' and typeof(value) == 'number' then
                rawset(self, key, value)
                a.Size = UDim2.new(0, (self.To - self.From).Magnitude, 0, value)
            elseif key == 'Visible' and typeof(value) == 'boolean' then
                rawset(self, key, value)
                a.Visible = value
            elseif key == 'Color' and typeof(value) == 'Color3' then
                pcall(function() rawset(self, key, value) end)
                a.BackgroundColor3 = value
            elseif key == 'Transparency' and typeof(value) == 'number' and value <= 1 then
                rawset(self, key, value)
                a.BackgroundTransparency = 1 - value
            elseif key == 'From' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
                self:updateLine()
            elseif key == 'To' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
                self:updateLine()
            end
        end
        local meta1 = setmetatable({}, meta)
        Drawings[meta1] = meta1
        return meta1
    elseif Type == 'Square' then
        local a = Instance.new("Frame", DrawingDict)
        a.Visible = false
        a.Size = UDim2.new(0, 0, 0, 0)
        a.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        a.BackgroundTransparency = 1
        a.BorderSizePixel = 0
        local b = Instance.new("UIStroke", a)
        b.Color = Color3.fromRGB(255, 255, 255)
        b.Enabled = true

        local meta = baseProps
        meta.ClassName = Type
        meta.__index = {
            Size = Vector2.new(0,0),
            Position = Vector2.new(0, 0),
            Remove = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            Destroy = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            updateSquare = function(self)
             if not a then return end
             a.Size = UDim2.new(0, self.Size.X, 0, self.Size.Y)
             a.Position = UDim2.new(0, self.Position.X, 0, self.Position.Y)
            end
        }

        meta.__newindex = function(self, key, value)
            if not self then return end
            if key == 'Filled' and typeof(value) == 'boolean' then
                rawset(self, key, value)
                b.Enabled = not value
                a.BackgroundTransparency = value and 0 or 1
            elseif key == 'Visible' and typeof(value) == 'boolean' then
                rawset(self, key, value)
                a.Visible = value
            elseif key == 'Color' and typeof(value) == 'Color3' then
                pcall(function() rawset(self, key, value) end)
                a.BackgroundColor3 = value
                pcall(function() b.Color = value end)
            elseif key == 'Position' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
                self:updateSquare()
            elseif key == 'Size' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
                self:updateSquare()
            end
        end
        local meta1 = setmetatable({}, meta)
        Drawings[meta1] = meta1
        return meta1
    elseif Type == 'Circle' then
        local a = Instance.new("Frame", Instance.new("ScreenGui", DrawingDict))
        a.Visible = false
        a.Size = UDim2.new(0, 0, 0, 0)
        a.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        a.BackgroundTransparency = 1
        a.BorderSizePixel = 0
        local b = Instance.new("UIStroke", a)
        b.Color = Color3.fromRGB(255, 255, 255)
        b.Enabled = false
        b.Thickness = 1
        local c = Instance.new("UICorner", a)
        c.CornerRadius = UDim.new(1, 0)

        local meta = baseProps
        meta.ClassName = Type
        meta.__index = {
            Thickness = 1,
            Filled = false,
            NumSides = 0,
            Radius = 1,
            Position = Vector2.new(0, 0),
            Transparency = 0,
            Remove = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            Destroy = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            updateCircle = function(self)
             if not b or not a then return end
             a.Size = UDim2.new(0, self.Radius, 0, self.Radius)
             a.Position = UDim2.new(0, self.Position.X, 0, self.Position.Y)
             b.Enabled = not self
             b.Color = self.Color
            end
        }

        meta.__newindex = function(self, key, value)
            if not self then return end
            if key == 'Thickness' and typeof(value) == 'number' then
                rawset(self, key, value)
                b.Thickness = value
            elseif key == 'Visible' and typeof(value) == 'boolean' then
                rawset(self, key, value)
                a.Visible = value
            elseif key == 'Color' and typeof(value) == 'Color3' then
                pcall(function() rawset(self, key, value) end)
                a.BackgroundColor3 = value
                pcall(function() a.Color = value end)
            elseif key == 'Transparency' and typeof(value) == 'number' then
                rawset(self, key, value)
                a.BackgroundTransparency = 1 - value
            elseif key == 'Position' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
                self:updateCircle()
            elseif key == 'Radius' and typeof(value) == 'number' then
                rawset(self, key, value)
                self:updateCircle()
            elseif key == 'NumSides' and typeof(value) == 'number' then
                rawset(self, key, value)
            elseif key == 'Filled' and typeof(value) == 'boolean' then
                rawset(self, key, value)
                self:updateCircle()
            end
        end
        local meta1 = setmetatable({}, meta)
        Drawings[meta1] = meta1
        return meta1
    elseif Type == 'Text' then
        local a = Instance.new("TextLabel", DrawingDict)
        a.Visible = false
        a.Size = UDim2.new(0, 0, 0, 0)
        a.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        a.BackgroundTransparency = 1
        a.BorderSizePixel = 0
        a.TextStrokeColor3 = Color3.new(0,0,0)
        a.TextStrokeTransparency = 1

        local meta = baseProps
        meta.ClassName = Type
        meta.__index = {
            Text = '',
            Transparency = 0,
            Size = 0,
            Center = false,
            Outline = false,
            OutlineColor = Color3.new(0,0,0),
            Position = Vector2.new(0,0),
            Font = 3,
            Remove = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            Destroy = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy() 
            end,
            updateText = function(self)
             if not a then return end
             a.TextScaled = true
             a.Size = UDim2.new(0, self.Size * 3, 0, self.Size / 2)
             a.Position = UDim2.new(0, self.Position.X, 0, self.Position.Y)
             a.Text = self.Text
             a.Font = Fonts[self.Font]
             a.Visible = self.Visible
             a.TextColor3 = self.Color or Color3.new(0, 0, 0)
             a.TextTransparency = 1 - self.Transparency
             a.BorderSizePixel = self.Outline and 1 or 0
             if self.Center then
              a.TextXAlignment = Enum.TextXAlignment.Center
              a.TextYAlignment = Enum.TextYAlignment.Center
             else
              a.TextXAlignment = Enum.TextXAlignment.Left
              a.TextYAlignment = Enum.TextYAlignment.Top
             end
             a.TextStrokeTransparency = self.Outline and 0 or 1
             a.TextStrokeColor3 = self.OutlineColor
            end
        }

        meta.__newindex = function(self, key, value)
            if not self then return end
            if key == 'Text' and typeof(value) == 'string' then
                rawset(self, key, value)
            elseif key == 'Visible' and typeof(value) == 'boolean' then
                rawset(self, key, value)
                a.Visible = value
            elseif key == 'Color' and typeof(value) == 'Color3' then
                pcall(function() rawset(self, key, value) end)
            elseif key == 'Transparency' and typeof(value) == 'number' then
                rawset(self, key, value)
            elseif key == 'Position' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
            elseif key == 'Size' and typeof(value) == 'number' then
                rawset(self, key, value)
            elseif key == 'Outline' and typeof(value) == 'boolean' then
                rawset(self, key, value)
            elseif key == 'Center' and typeof(value) == 'boolean' then
                rawset(self, key, value)
            elseif key == 'OutlineColor' and typeof(value) == 'Color3' then
                rawset(self, key, value)
            elseif key == 'Font' and typeof(value) == 'number' then
                rawset(self, key, value)
            end
            self:updateText()
        end

        local meta1 = setmetatable({}, meta)
        Drawings[meta1] = meta1
        return meta1
    elseif Type == 'Image' then
        local a = Instance.new("ImageLabel", DrawingDict)
        a.Visible = false
        a.Size = UDim2.new(0, 0, 0, 0)
        a.ImageColor3 = Color3.fromRGB(255,255,255)
        a.BackgroundTransparency = 1
        a.BorderSizePixel = 0

        local meta = baseProps
        meta.ClassName = 'Image'
        meta.__index = {
            Text = '',
            Transparency = 0,
            Size = Vector2.new(0, 0),
            Position = Vector2.new(0,0),
            Color = Color3.fromRGB(255, 255, 255),
            Image = '',
            Remove = function()
               for i, v in pairs(Drawings) do if v == meta then Drawings[i] = nil end end
               a:Destroy()
            end,
            Destroy = function()
               for i, v in pairs(Drawings) do
                if v == meta then Drawings[i] = nil end
               end
               a:Destroy()
            end,
            updateImage = function(self)
             if not a then return end
             a.Size = UDim2.new(0, self.Size.X, 0, self.Size.Y)
             a.Position = UDim2.new(0, self.Position.X, 0, self.Position.Y)
             a.Visible = self.Visible
             a.ImageColor3 = self.Color
             a.ImageTransparency = 1 - self.Transparency
             a.BorderSizePixel = self.Outline and 1 or 0
             a.Image = self.Image
            end
        }

        meta.__newindex = function(self, key, value)
            if not self then return end
            if key == 'Visible' and typeof(value) == 'boolean' then
                rawset(self, key, value)
            elseif key == 'Color' and typeof(value) == 'Color3' then
                pcall(function() rawset(self, key, value) end)
            elseif key == 'Transparency' and typeof(value) == 'number' then
                rawset(self, key, value)
            elseif key == 'Position' and typeof(value) == 'Vector2' then
                rawset(self, key, value)
            elseif key == 'Size' and typeof(value) == 'number' then
                rawset(self, key, value)
            elseif key == 'Image' and typeof(value) == 'string' then
                rawset(self, key, value)
            else
             return
            end
            self:updateImage()
        end

        local meta1 = setmetatable({}, meta)
        Drawings[meta1] = meta1
        return meta1
    end
end
