--[[
    Standalone GUI Library (extracted)
    -----------------------------------
    A reusable, Instance-based Roblox UI toolkit. NO Drawing objects are used,
    so there is no 200-object Drawing limit risk.

    Components:
      Window (draggable, tabbed, themed, close/help buttons)
      Tab (two-column layout w/ headers + optional warning modal)
      CollapsibleGroup
      Toggle, Button, Slider, Keybind, Dropdown, ColorPicker (HSV wheel)
      Notifications (stacked, animated)
      TopLabels (transient banners)
      Theme engine (built-in palettes + live re-theming)
      DropShadow helper
      Optional config persistence (readfile/writefile) — degrades gracefully

    USAGE
    -----
    local UI  = loadstring(readfile("UILibrary.lua"))()      -- or however you load it
    local win = UI.new({ Title = "My Menu", Theme = "Your Desire" })

    local tab = win:AddTab("Visuals", { Left = "General", Right = "Advanced" })

    local grp = win:Group(tab.LeftCol, "Player Visuals", false)
    local t   = win:Toggle(grp.Body, "Chams", "tooltip text")
    t.OnChanged = function(state) print("chams", state) end

    local s = win:Slider(tab.RightCol, "Intensity", 0, 100, 50)
    s.OnChanged = function(v) print(v) end

    local cp = win:ColorPicker(tab.RightCol, "Color", Color3.fromRGB(0,255,0))
    local kb = win:Keybind(tab.LeftCol, "Hotkey", Enum.KeyCode.P)
    local dd = win:Dropdown(tab.LeftCol, "Mode", {"A","B","C"}, 1)
    local b  = win:Button(tab.LeftCol, "Run");  b.OnClick = function() end

    win:Notify("Loaded!", 4)
    win:SetTheme("Blue Hour")
    win:Toast("Heads up")        -- transient top-center label
    win:Destroy()
--]]

local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local HttpService        = game:GetService("HttpService")
local UserInputService   = game:GetService("UserInputService")
local TextService        = game:GetService("TextService")

local Library = {}
Library.__index = Library

----------------------------------------------------------------------
-- Theme palette + built-in themes
----------------------------------------------------------------------

local BASE_COLORS = {
    bg          = Color3.fromRGB(20,18,30),
    panel       = Color3.fromRGB(28,24,38),
    panelAlt    = Color3.fromRGB(38,30,50),
    panelDark   = Color3.fromRGB(18,16,25),
    divider     = Color3.fromRGB(70,50,80),
    accent      = Color3.fromRGB(200,80,180),
    accentHover = Color3.fromRGB(220,100,200),
    text        = Color3.fromRGB(240,240,245),
    textDim     = Color3.fromRGB(180,170,190),
    tabText     = Color3.fromRGB(220,200,230),
    highlight   = Color3.fromRGB(90,70,100),
    white       = Color3.fromRGB(255,255,255),
    close       = Color3.fromRGB(255,200,200),
    closeHover  = Color3.fromRGB(255,120,150),
}

local function shallowCopy(t)
    local o = {}
    for k,v in pairs(t) do o[k] = v end
    return o
end

local THEMES = {
    ["Your Desire"]   = shallowCopy(BASE_COLORS),
    ["Gilded Crown"]  = {
        bg=Color3.fromRGB(18,16,20), panel=Color3.fromRGB(34,28,24), panelAlt=Color3.fromRGB(46,40,36),
        panelDark=Color3.fromRGB(14,12,10), divider=Color3.fromRGB(120,90,50), accent=Color3.fromRGB(220,180,80),
        accentHover=Color3.fromRGB(240,200,120), text=Color3.fromRGB(250,245,235), textDim=Color3.fromRGB(190,170,150),
        tabText=Color3.fromRGB(230,210,190), highlight=Color3.fromRGB(100,90,70), white=Color3.fromRGB(255,255,255),
        close=Color3.fromRGB(255,220,200), closeHover=Color3.fromRGB(255,160,120),
    },
    ["Blue Hour"]     = {
        bg=Color3.fromRGB(12,18,30), panel=Color3.fromRGB(20,28,42), panelAlt=Color3.fromRGB(28,36,52),
        panelDark=Color3.fromRGB(8,10,16), divider=Color3.fromRGB(60,80,110), accent=Color3.fromRGB(80,160,220),
        accentHover=Color3.fromRGB(110,190,240), text=Color3.fromRGB(235,245,255), textDim=Color3.fromRGB(170,190,210),
        tabText=Color3.fromRGB(200,220,240), highlight=Color3.fromRGB(40,60,80), white=Color3.fromRGB(255,255,255),
        close=Color3.fromRGB(255,200,200), closeHover=Color3.fromRGB(255,120,150),
    },
    ["Verdant Pulse"] = {
        bg=Color3.fromRGB(14,28,20), panel=Color3.fromRGB(24,44,34), panelAlt=Color3.fromRGB(32,56,42),
        panelDark=Color3.fromRGB(10,18,12), divider=Color3.fromRGB(50,100,70), accent=Color3.fromRGB(80,200,120),
        accentHover=Color3.fromRGB(110,230,150), text=Color3.fromRGB(235,250,240), textDim=Color3.fromRGB(170,200,180),
        tabText=Color3.fromRGB(200,230,210), highlight=Color3.fromRGB(40,70,50), white=Color3.fromRGB(255,255,255),
        close=Color3.fromRGB(255,200,200), closeHover=Color3.fromRGB(255,120,150),
    },
    ["Crimson Dusk"]  = {
        bg=Color3.fromRGB(30,16,18), panel=Color3.fromRGB(45,24,28), panelAlt=Color3.fromRGB(56,32,38),
        panelDark=Color3.fromRGB(20,10,12), divider=Color3.fromRGB(100,60,70), accent=Color3.fromRGB(220,80,100),
        accentHover=Color3.fromRGB(240,120,140), text=Color3.fromRGB(250,235,240), textDim=Color3.fromRGB(200,170,180),
        tabText=Color3.fromRGB(230,200,210), highlight=Color3.fromRGB(80,40,50), white=Color3.fromRGB(255,255,255),
        close=Color3.fromRGB(255,200,200), closeHover=Color3.fromRGB(255,120,150),
    },
    ["Slate Steel"]   = {
        bg=Color3.fromRGB(20,24,28), panel=Color3.fromRGB(32,38,46), panelAlt=Color3.fromRGB(42,50,60),
        panelDark=Color3.fromRGB(16,18,22), divider=Color3.fromRGB(70,85,100), accent=Color3.fromRGB(140,180,220),
        accentHover=Color3.fromRGB(170,210,255), text=Color3.fromRGB(235,240,245), textDim=Color3.fromRGB(170,185,200),
        tabText=Color3.fromRGB(200,215,230), highlight=Color3.fromRGB(50,70,90), white=Color3.fromRGB(255,255,255),
        close=Color3.fromRGB(255,200,200), closeHover=Color3.fromRGB(255,120,150),
    },
}

Library.Themes = THEMES

----------------------------------------------------------------------
-- Construction
----------------------------------------------------------------------

local function parentGui(inst)
    local ok = pcall(function() inst.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not ok then
        local lp = Players.LocalPlayer
        if lp then inst.Parent = lp:WaitForChild("PlayerGui") end
    end
end

-- opts: { Title, Theme, Size, ConfigFile, ShowHelp }
function Library.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Library)

    self.COLORS        = shallowCopy(THEMES[opts.Theme] or THEMES["Your Desire"])
    self.LAST_THEME    = nil
    self.THEME_REGISTRY = {}

    -- component API registries (weak-keyed by frame)
    self.ToggleAPI      = setmetatable({}, { __mode = "k" })
    self.DropdownAPI    = setmetatable({}, { __mode = "k" })
    self.KeybindAPI     = setmetatable({}, { __mode = "k" })
    self.SliderAPI      = setmetatable({}, { __mode = "k" })
    self.ButtonAPI      = setmetatable({}, { __mode = "k" })
    self.ColorPickerAPI = setmetatable({}, { __mode = "k" })
    self.DisabledKeybinds = {}

    self.TAB_WARNING_HANDLERS = {}
    self.FIRST_TAB = nil
    self._tabs = {}
    self._dragConnections = {}   -- shared InputChanged handlers (sliders/pickers/drag)

    -- optional config persistence
    self.ConfigFile = opts.ConfigFile
    self.Config = {}
    if self.ConfigFile then self:_loadConfig() end

    -- root ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = opts.Name or "UILibrary"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    parentGui(gui)
    self.gui = gui

    self:_buildWindow(opts)

    -- single global pointer-move pump for drag-style controls
    self._inputChangedConn = UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        for fn in pairs(self._dragConnections) do
            pcall(fn, input)
        end
    end)

    return self
end

----------------------------------------------------------------------
-- Config (optional, tolerant of missing executor file API)
----------------------------------------------------------------------

function Library:_loadConfig()
    local ok, contents = pcall(function() return readfile(self.ConfigFile) end)
    if ok and contents then
        local okd, decoded = pcall(function() return HttpService:JSONDecode(contents) end)
        if okd and type(decoded) == "table" then self.Config = decoded end
    end
end

function Library:_saveConfig()
    if not self.ConfigFile then return end
    pcall(function() writefile(self.ConfigFile, HttpService:JSONEncode(self.Config)) end)
end

function Library:Get(key, default)
    if self.Config[key] == nil then return default end
    return self.Config[key]
end

function Library:Set(key, value)
    self.Config[key] = value
    self:_saveConfig()
end

----------------------------------------------------------------------
-- Themed registry
----------------------------------------------------------------------

local function snapshotColors(obj)
    local t = {}
    pcall(function()
        if obj:IsA("GuiObject") then
            if obj.BackgroundColor3 ~= nil then t.bg = obj.BackgroundColor3 end
            if obj.TextColor3 ~= nil then t.text = obj.TextColor3 end
        end
        for _,c in ipairs(obj:GetChildren()) do
            if c:IsA("UIStroke") then
                t.stroke = t.stroke or {}
                table.insert(t.stroke, c.Color)
            end
        end
    end)
    return t
end

function Library:_register(obj, refreshFn)
    if not obj or typeof(obj) ~= "Instance" then return end
    local entry = { obj = obj, snapshot = snapshotColors(obj), refresh = (type(refreshFn)=="function") and refreshFn or nil }
    table.insert(self.THEME_REGISTRY, entry)
    return entry
end

function Library:_refreshThemed()
    if #self.THEME_REGISTRY == 0 then return end
    local prev = self.LAST_THEME or {}
    local cur  = self.COLORS or {}
    local map = {}
    for k,v in pairs(prev) do if cur[k] then map[v] = cur[k] end end

    local function colorDist(a,b)
        local dr,dg,db = a.r-b.r, a.g-b.g, a.b-b.b
        return dr*dr + dg*dg + db*db
    end
    local function findMapped(col)
        if not col or typeof(col) ~= "Color3" then return nil end
        for old,new in pairs(map) do if old == col then return new end end
        local best, bestd = nil, 1e9
        for old,new in pairs(map) do
            local d = colorDist(old, col)
            if d < bestd then bestd = d; best = new end
        end
        if best and bestd < 0.006 then return best end
        return nil
    end

    for _,e in ipairs(self.THEME_REGISTRY) do
        local o, s = e.obj, e.snapshot
        if o and o.Parent then
            pcall(function()
                if s.bg then local m = findMapped(s.bg); if m then o.BackgroundColor3 = m end end
                if s.text then local m = findMapped(s.text); if m then o.TextColor3 = m end end
            end)
            if s.stroke and #s.stroke > 0 then
                local strokes = {}
                for _,c in ipairs(o:GetChildren()) do if c:IsA("UIStroke") then table.insert(strokes, c) end end
                for i,old in ipairs(s.stroke) do
                    local target = strokes[i]
                    if target then local m = findMapped(old); if m then pcall(function() target.Color = m end) end end
                end
            end
            if type(e.refresh) == "function" then pcall(e.refresh) end
        end
    end
end

function Library:SetTheme(name)
    local theme = THEMES[name] or THEMES["Your Desire"]
    self.LAST_THEME = shallowCopy(self.COLORS)
    self.COLORS = shallowCopy(theme)
    pcall(function() self:_refreshThemed() end)
    -- re-apply visual state on stateful controls
    for _,api in pairs(self.ToggleAPI) do
        if type(api)=="table" and api.Set and api.Get then
            local on = api.OnToggle; api.OnToggle = nil; pcall(api.Set, api.Get()); api.OnToggle = on
        end
    end
    if self.ConfigFile then self:Set("ui.theme", name) end
end

----------------------------------------------------------------------
-- Drop shadow helper
----------------------------------------------------------------------

function Library:DropShadow(target, offsetX, offsetY, transparency)
    if not target or not target.Parent then return nil end
    local layers, ox, oy, base = 8, offsetX or 4, offsetY or 4, transparency or 0.85
    local cornerRadius = 0
    local uc = target:FindFirstChildWhichIsA("UICorner")
    if uc and typeof(uc.CornerRadius) == "UDim" then cornerRadius = uc.CornerRadius.Offset end

    local container = Instance.new("Frame")
    container.Name = target.Name .. "Shadow"
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ZIndex = math.max(0, (target.ZIndex or 1) - 8)
    container.Parent = target.Parent

    local shadows = {}
    for i = 1, layers do
        local s = Instance.new("Frame")
        s.BackgroundColor3 = Color3.new(0,0,0)
        s.BorderSizePixel = 0
        s.ZIndex = container.ZIndex + i
        s.BackgroundTransparency = base + ((1 - base) * (i / layers))
        local rc = Instance.new("UICorner") rc.CornerRadius = UDim.new(0, cornerRadius + (i * 0.5)) rc.Parent = s
        s.Parent = container
        table.insert(shadows, s)
    end

    local function refresh()
        if not target.Parent or not container.Parent then return end
        if not target.Visible then container.Visible = false return end
        container.Visible = true
        container.Size, container.Position = target.Size, target.Position
        for i, s in ipairs(shadows) do
            s.Size = target.Size
            s.Position = target.Position + UDim2.new(0, ox * (i/layers), 0, oy * (i/layers))
            s.ZIndex = math.max(0, (target.ZIndex or 1) - 8 + i)
        end
    end
    for _,prop in ipairs({"Position","Size","ZIndex","AbsoluteSize","Visible"}) do
        target:GetPropertyChangedSignal(prop):Connect(refresh)
    end
    target.AncestryChanged:Connect(function() if not target.Parent then container:Destroy() end end)
    task.defer(refresh)
    return container
end

----------------------------------------------------------------------
-- Window scaffolding (root, tabs bar, pages, banner, drag, close, help)
----------------------------------------------------------------------

function Library:_buildWindow(opts)
    local COLORS = self.COLORS
    local gui = self.gui
    local bannerHeight, TOPBAR_SPACING = 28, 17
    local size = opts.Size or UDim2.new(0, 760, 0, 520 + bannerHeight + TOPBAR_SPACING)

    local root = Instance.new("Frame")
    root.Size = size
    root.Position = UDim2.new(0.5, -(size.X.Offset/2), 0.5, -(size.Y.Offset/2))
    root.BackgroundColor3 = COLORS.bg
    root.Parent = gui
    Instance.new("UICorner", root)
    self.root = root
    self:_register(root)

    local tabsBar = Instance.new("Frame")
    tabsBar.Size = UDim2.new(0, 160, 1, -(bannerHeight + TOPBAR_SPACING))
    tabsBar.Position = UDim2.new(0, 0, 0, bannerHeight + TOPBAR_SPACING)
    tabsBar.BackgroundColor3 = COLORS.panel
    tabsBar.ZIndex = 2
    tabsBar.Parent = root
    Instance.new("UICorner", tabsBar).CornerRadius = UDim.new(0,6)
    local tabsBarLayout = Instance.new("UIListLayout", tabsBar)
    tabsBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabsBarLayout.Padding = UDim.new(0,6)
    local tbp = Instance.new("UIPadding", tabsBar)
    tbp.PaddingTop = UDim.new(0,8); tbp.PaddingLeft = UDim.new(0,6); tbp.PaddingRight = UDim.new(0,6)
    self.tabsBar = tabsBar
    self:_register(tabsBar)

    local tabsUnderlay = Instance.new("Frame")
    tabsUnderlay.Size = tabsBar.Size
    tabsUnderlay.Position = tabsBar.Position
    tabsUnderlay.BackgroundColor3 = COLORS.panel
    tabsUnderlay.ZIndex = 1
    tabsUnderlay.Parent = root
    Instance.new("UICorner", tabsUnderlay).CornerRadius = UDim.new(0,4)
    self:_register(tabsUnderlay)

    self:DropShadow(root, 10, 10, 0.72)
    self:DropShadow(tabsBar, 6, 6, 0.78)

    local pages = Instance.new("ScrollingFrame")
    pages.Name = "Pages"
    pages.Size = UDim2.new(1, -160, 1, -(bannerHeight + TOPBAR_SPACING))
    pages.Position = UDim2.new(0, 160, 0, bannerHeight + math.floor(TOPBAR_SPACING/3))
    pages.BackgroundTransparency = 1
    pages.ScrollBarThickness = 10
    pages.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pages.CanvasSize = UDim2.new(0,0,0,0)
    pages.ClipsDescendants = true
    pages.Parent = root
    self.pages = pages
    self:_register(pages)

    local banner = Instance.new("TextLabel")
    banner.Size = UDim2.new(1, 0, 0, bannerHeight)
    banner.BackgroundTransparency = 1
    banner.Font = Enum.Font.GothamBold
    banner.TextSize = 14
    banner.TextColor3 = COLORS.textDim
    banner.Text = opts.Title or "MENU"
    banner.ZIndex = 60
    banner.Parent = root
    self.banner = banner
    self:_register(banner)

    local topDivider = Instance.new("Frame")
    topDivider.Size = UDim2.new(1, 0, 0, 1)
    topDivider.Position = UDim2.new(0, 0, 0, bannerHeight + math.floor(TOPBAR_SPACING/2))
    topDivider.BackgroundColor3 = COLORS.divider
    topDivider.BorderSizePixel = 0
    topDivider.ZIndex = banner.ZIndex - 1
    topDivider.Parent = root
    self:_register(topDivider, function() topDivider.BackgroundColor3 = self.COLORS.divider end)

    -- close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0, 6)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.Text = "X"
    closeBtn.TextColor3 = COLORS.close
    closeBtn.Parent = root
    closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = self.COLORS.closeHover end)
    closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = self.COLORS.close end)
    closeBtn.MouseButton1Click:Connect(function()
        if self.OnClose then pcall(self.OnClose) else root.Visible = false end
    end)
    self.closeBtn = closeBtn
    self:_register(closeBtn)

    -- help button (optional)
    if opts.ShowHelp ~= false then
        local helpBtn = Instance.new("TextButton")
        helpBtn.Size = UDim2.new(0, 72, 0, 28)
        helpBtn.Position = UDim2.new(0, 4, 0, 6)
        helpBtn.BackgroundColor3 = COLORS.panel
        helpBtn.TextColor3 = COLORS.text
        helpBtn.Font = Enum.Font.GothamBold
        helpBtn.TextSize = 14
        helpBtn.Text = "Help"
        helpBtn.AutoButtonColor = false
        helpBtn.ZIndex = banner.ZIndex + 1
        Instance.new("UICorner", helpBtn).CornerRadius = UDim.new(0,6)
        helpBtn.Parent = root
        helpBtn.MouseButton1Click:Connect(function() if self.OnHelp then pcall(self.OnHelp) end end)
        self.helpBtn = helpBtn
        self:_register(helpBtn)
    end

    -- drag (grab anywhere on tabsBar that isn't an interactive control)
    tabsBar.Active = true
    do
        local dragging, dragStart, startPos
        tabsBar.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            local overGui = false
            pcall(function()
                for _, o in ipairs(UserInputService:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y) or {}) do
                    if o:IsA("TextButton") or o:IsA("ImageButton") or o:IsA("TextBox") then overGui = true break end
                end
            end)
            if overGui then return end
            dragging, dragStart, startPos = true, input.Position, root.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end)
        self._dragConnections[function(input)
            if dragging and dragStart and startPos then
                local delta = input.Position - dragStart
                root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end] = true
    end

    self._bannerHeight, self._topSpacing = bannerHeight, TOPBAR_SPACING
end

----------------------------------------------------------------------
-- Tab selection
----------------------------------------------------------------------

function Library:_selectTab(button, page)
    local COLORS = self.COLORS
    local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    for _,c in ipairs(self.tabsBar:GetChildren()) do
        if c:IsA("TextButton") then
            pcall(function()
                c:SetAttribute("TabActive", false)
                TweenService:Create(c, ti, {TextColor3 = COLORS.textDim, Position = UDim2.new(c.Position.X.Scale, c.Position.X.Offset, 0, 6), BackgroundColor3 = COLORS.panel}):Play()
                local ind = c:FindFirstChild("ActiveIndicator")
                if ind then TweenService:Create(ind, ti, {BackgroundTransparency = 1}):Play() end
            end)
        end
    end
    for _,p in ipairs(self.pages:GetChildren()) do
        if p:IsA("Frame") then p.Visible = false end
    end
    pcall(function()
        button:SetAttribute("TabActive", true)
        TweenService:Create(button, ti, {TextColor3 = COLORS.white, Position = UDim2.new(button.Position.X.Scale, button.Position.X.Offset, 0, -4), BackgroundColor3 = COLORS.accent}):Play()
        local ind = button:FindFirstChild("ActiveIndicator")
        if ind then TweenService:Create(ind, ti, {BackgroundTransparency = 0}):Play() end
    end)
    page.Visible = true
    local h = self.TAB_WARNING_HANDLERS[page]
    if type(h) == "function" then h() end
end

----------------------------------------------------------------------
-- AddTab
----------------------------------------------------------------------

function Library:AddTab(name, colHeaders, warningText)
    local COLORS = self.COLORS
    local gui = self.gui

    local btn = Instance.new("TextButton")
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.Name = name .. "Tab"
    btn.Size = UDim2.new(1, -12, 0, 32)
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.Text = name
    btn.BackgroundColor3 = COLORS.panel
    btn.TextColor3 = COLORS.tabText
    btn.BorderSizePixel = 0
    btn.TextXAlignment = Enum.TextXAlignment.Left
    local btnPad = Instance.new("UIPadding", btn) btnPad.PaddingLeft = UDim.new(0, 12)
    btn.ZIndex = 10
    btn:SetAttribute("TabActive", false)
    btn.ClipsDescendants = true

    local indicator = Instance.new("Frame")
    indicator.Name = "ActiveIndicator"
    indicator.Size = UDim2.new(0, 4, 1, -8)
    indicator.Position = UDim2.new(1, -6, 0, 4)
    indicator.BackgroundColor3 = COLORS.accent
    indicator.BackgroundTransparency = 1
    indicator.ZIndex = btn.ZIndex - 1
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 2)
    indicator.Parent = btn

    local page = Instance.new("Frame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    local pageLayout = Instance.new("UIListLayout", page)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Padding = UDim.new(0, 0)
    local pagePad = Instance.new("UIPadding", page)
    pagePad.PaddingLeft = UDim.new(0, 8); pagePad.PaddingRight = UDim.new(0, 8)
    pagePad.PaddingTop = UDim.new(0, 8); pagePad.PaddingBottom = UDim.new(0, 8)

    btn.Parent = self.tabsBar
    page.Parent = self.pages

    self:_register(btn, function()
        local ind = btn:FindFirstChild("ActiveIndicator")
        local active = btn:GetAttribute("TabActive") == true
        btn.TextColor3 = active and self.COLORS.white or self.COLORS.tabText
        btn.BackgroundColor3 = active and self.COLORS.accent or self.COLORS.panel
        if ind then ind.BackgroundColor3 = self.COLORS.accent; ind.BackgroundTransparency = active and 0 or 1 end
    end)

    -- warning modal
    local warningOverlay
    local function showWarning()
        if not warningText or type(warningText) ~= "string" then return end
        if warningOverlay and warningOverlay.Parent then warningOverlay.Visible = true return end
        warningOverlay = Instance.new("Frame")
        warningOverlay.BackgroundColor3 = self.COLORS.panelAlt
        warningOverlay.BackgroundTransparency = 0.6
        warningOverlay.BorderSizePixel = 0
        warningOverlay.ZIndex = 10000
        warningOverlay.Position = UDim2.new(0, page.AbsolutePosition.X, 0, page.AbsolutePosition.Y)
        warningOverlay.Size = UDim2.new(0, page.AbsoluteSize.X, 0, page.AbsoluteSize.Y)
        warningOverlay.Parent = gui

        local modal = Instance.new("Frame")
        modal.Size = UDim2.new(0.9, 0, 0.86, 0)
        modal.Position = UDim2.new(0.5, 0, 0, 8)
        modal.AnchorPoint = Vector2.new(0.5, 0)
        modal.BackgroundColor3 = self.COLORS.panel
        modal.BorderSizePixel = 0
        modal.ZIndex = warningOverlay.ZIndex + 1
        modal.Parent = warningOverlay
        Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 12)
        local ms = Instance.new("UIStroke", modal) ms.Color = self.COLORS.divider ms.Thickness = 1

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -36, 0, 40); title.Position = UDim2.new(0, 18, 0, 12)
        title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBold; title.TextSize = 20
        title.Text = "Warning"; title.TextColor3 = self.COLORS.accent
        title.TextXAlignment = Enum.TextXAlignment.Left; title.ZIndex = modal.ZIndex + 1; title.Parent = modal

        local msg = Instance.new("TextLabel")
        msg.Size = UDim2.new(1, -36, 1, -120); msg.Position = UDim2.new(0, 18, 0, 64)
        msg.BackgroundTransparency = 1; msg.Font = Enum.Font.Gotham; msg.TextSize = 16
        msg.TextColor3 = self.COLORS.text; msg.TextWrapped = true; msg.Text = warningText
        msg.TextXAlignment = Enum.TextXAlignment.Center; msg.TextYAlignment = Enum.TextYAlignment.Center
        msg.ZIndex = modal.ZIndex + 1; msg.Parent = modal

        local okBtn = Instance.new("TextButton")
        okBtn.Size = UDim2.new(0, 160, 0, 40); okBtn.Position = UDim2.new(0.5, 0, 1, -56)
        okBtn.AnchorPoint = Vector2.new(0.5, 0.5); okBtn.BackgroundColor3 = self.COLORS.accent
        okBtn.Font = Enum.Font.GothamBold; okBtn.TextSize = 16; okBtn.TextColor3 = self.COLORS.white
        okBtn.Text = "OK"; okBtn.ZIndex = modal.ZIndex + 2; okBtn.Parent = modal
        Instance.new("UICorner", okBtn).CornerRadius = UDim.new(0, 8)
        okBtn.MouseButton1Click:Connect(function() if warningOverlay and warningOverlay.Parent then warningOverlay:Destroy() end end)
    end
    self.TAB_WARNING_HANDLERS[page] = showWarning

    btn.MouseButton1Click:Connect(function()
        local mp = UserInputService:GetMouseLocation()
        local lx = math.clamp(mp.X - btn.AbsolutePosition.X, 0, btn.AbsoluteSize.X)
        local ly = math.clamp(mp.Y - btn.AbsolutePosition.Y, 0, btn.AbsoluteSize.Y)
        local ripple = Instance.new("Frame")
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.Position = UDim2.new(0, lx, 0, ly)
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        ripple.BackgroundColor3 = (self.COLORS.accent):Lerp(self.COLORS.white, 0.22)
        ripple.BackgroundTransparency = 0.6
        ripple.BorderSizePixel = 0
        ripple.ZIndex = btn.ZIndex + 5
        Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)
        ripple.Parent = btn
        local maxDim = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y)
        local tw = TweenService:Create(ripple, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, maxDim*2, 0, maxDim*2), BackgroundTransparency = 1})
        tw:Play()
        tw.Completed:Connect(function() if ripple.Parent then ripple:Destroy() end end)
        self:_selectTab(btn, page)
        showWarning()
    end)

    btn.MouseEnter:Connect(function()
        local active = btn:GetAttribute("TabActive") == true
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = active and self.COLORS.accentHover or self.COLORS.panelAlt, TextColor3 = active and self.COLORS.white or self.COLORS.tabText}):Play()
    end)
    btn.MouseLeave:Connect(function()
        local active = btn:GetAttribute("TabActive") == true
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = active and self.COLORS.accent or self.COLORS.panel, TextColor3 = active and self.COLORS.white or self.COLORS.tabText}):Play()
    end)

    -- two-column layout
    local function makeCol(layoutOrder, headerText)
        local col = Instance.new("Frame")
        col.Size = UDim2.new(1, 0, 0, 0)
        col.BackgroundTransparency = 1
        col.AutomaticSize = Enum.AutomaticSize.Y
        col.LayoutOrder = layoutOrder
        col.Parent = page
        self:_register(col)
        local list = Instance.new("UIListLayout", col)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 8)
        local pad = Instance.new("UIPadding", col)
        pad.PaddingLeft = UDim.new(0,10); pad.PaddingRight = UDim.new(0,10)
        pad.PaddingTop = UDim.new(0,8); pad.PaddingBottom = UDim.new(0,8)
        if headerText then
            local hdr = Instance.new("TextLabel")
            hdr.Name = "Header"; hdr.Size = UDim2.new(1, 0, 0, 20)
            hdr.BackgroundTransparency = 1; hdr.Font = Enum.Font.GothamBold; hdr.TextSize = 14
            hdr.Text = tostring(headerText); hdr.TextColor3 = self.COLORS.accent
            hdr.TextXAlignment = Enum.TextXAlignment.Left; hdr.LayoutOrder = 0; hdr.Parent = col
            self:_register(hdr, function() hdr.TextColor3 = self.COLORS.accent end)
        end
        return col
    end

    local leftCol  = makeCol(0, colHeaders and colHeaders.Left)
    local divider  = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1); divider.BackgroundColor3 = COLORS.divider
    divider.BorderSizePixel = 0; divider.LayoutOrder = 1; divider.AnchorPoint = Vector2.new(0, 0.5)
    divider.Parent = page
    self:_register(divider, function() divider.BackgroundColor3 = self.COLORS.divider end)
    local rightCol = makeCol(2, colHeaders and colHeaders.Right)

    local tab = { button = btn, page = page, LeftCol = leftCol, RightCol = rightCol }
    if self.FIRST_TAB == nil then
        self.FIRST_TAB = tab
        self:_selectTab(btn, page)
    end
    table.insert(self._tabs, tab)
    return tab
end

----------------------------------------------------------------------
-- Collapsible group
----------------------------------------------------------------------

function Library:Group(parent, title, defaultOpen)
    local COLORS = self.COLORS
    local headerHeight, extraWidth, extraX = 36, 8, -10

    local grp = Instance.new("Frame")
    grp.Name = tostring(title or "Group")
    grp.BackgroundTransparency = 1
    grp.Size = UDim2.new(1, extraWidth, 0, headerHeight)
    grp.Position = UDim2.new(0, extraX, 0, 0)
    grp.Parent = parent

    local maxOrder = 0
    for _,c in ipairs(parent:GetChildren()) do
        if c ~= grp and (c:IsA("Frame") or c:IsA("TextLabel") or c:IsA("TextButton")) then
            maxOrder = math.max(maxOrder, c.LayoutOrder or 0)
        end
    end
    grp.LayoutOrder = maxOrder + 1

    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1, 0, 0, headerHeight)
    header.BackgroundColor3 = COLORS.panelAlt
    header.AutoButtonColor = false
    header.Font = Enum.Font.GothamBold
    header.TextSize = 18
    header.Text = tostring(title or "Group")
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.TextColor3 = COLORS.text
    header.Parent = grp
    header.ZIndex = 50
    local hp = Instance.new("UIPadding", header) hp.PaddingLeft = UDim.new(0,12); hp.PaddingRight = UDim.new(0,28)
    Instance.new("UICorner", header).CornerRadius = UDim.new(0,6)
    self:_register(header)

    local caret = Instance.new("TextLabel")
    caret.Size = UDim2.new(0, 18, 0, 18)
    caret.AnchorPoint = Vector2.new(1, 0.5)
    caret.Position = UDim2.new(1, -12, 0.5, 0)
    caret.BackgroundTransparency = 1
    caret.Font = Enum.Font.Gotham
    caret.TextSize = 16
    caret.Text = "▾"
    caret.TextColor3 = COLORS.textDim
    caret.ZIndex = header.ZIndex + 1
    caret.Parent = header
    self:_register(caret)

    local bodyClip = Instance.new("Frame")
    bodyClip.BackgroundTransparency = 1
    bodyClip.Position = UDim2.new(0,0,0,headerHeight)
    bodyClip.Size = UDim2.new(1,0,0,0)
    bodyClip.ClipsDescendants = true
    bodyClip.Parent = grp

    local inner = Instance.new("Frame")
    inner.BackgroundTransparency = 1
    inner.Size = UDim2.new(1,0,0,0)
    inner.AutomaticSize = Enum.AutomaticSize.Y
    inner.Parent = bodyClip
    local innerLayout = Instance.new("UIListLayout", inner)
    innerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    innerLayout.Padding = UDim.new(0,6)
    local ip = Instance.new("UIPadding", inner)
    ip.PaddingLeft = UDim.new(0,4); ip.PaddingRight = UDim.new(0,4); ip.PaddingTop = UDim.new(0,8); ip.PaddingBottom = UDim.new(0,8)

    local opened = not not defaultOpen
    local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local function setOpen(open)
        opened = not not open
        bodyClip.ClipsDescendants = not opened
        local contentH = innerLayout.AbsoluteContentSize.Y
        if opened then
            TweenService:Create(grp, ti, {Size = UDim2.new(1, extraWidth, 0, headerHeight + contentH)}):Play()
            TweenService:Create(bodyClip, ti, {Size = UDim2.new(1,0,0, contentH)}):Play()
            TweenService:Create(caret, ti, {Rotation = 0}):Play()
            caret.Text = "▾"
        else
            TweenService:Create(grp, ti, {Size = UDim2.new(1, extraWidth, 0, headerHeight)}):Play()
            TweenService:Create(bodyClip, ti, {Size = UDim2.new(1,0,0,0)}):Play()
            TweenService:Create(caret, ti, {Rotation = -90}):Play()
            caret.Text = "▸"
        end
    end
    header.MouseButton1Click:Connect(function() setOpen(not opened) end)
    task.defer(function()
        local contentH = innerLayout.AbsoluteContentSize.Y
        if opened then
            grp.Size = UDim2.new(1, extraWidth, 0, headerHeight + contentH)
            bodyClip.Size = UDim2.new(1,0,0, contentH)
            caret.Text = "▾"; caret.Rotation = 0
        else
            grp.Size = UDim2.new(1, extraWidth, 0, headerHeight)
            bodyClip.Size = UDim2.new(1,0,0,0)
            caret.Text = "▸"; caret.Rotation = -90
        end
    end)

    return { Frame = grp, Header = header, Body = inner, SetOpen = setOpen, Toggle = function() setOpen(not opened) end }
end

----------------------------------------------------------------------
-- LayoutOrder helper
----------------------------------------------------------------------

local function nextOrder(parent, frame)
    local maxOrder = 0
    for _,c in ipairs(parent:GetChildren()) do
        if c ~= frame and (c:IsA("Frame") or c:IsA("TextLabel") or c:IsA("TextButton")) then
            maxOrder = math.max(maxOrder, c.LayoutOrder or 0)
        end
    end
    return maxOrder + 1
end

----------------------------------------------------------------------
-- Toggle
----------------------------------------------------------------------

function Library:Toggle(parent, labelText, tooltipText)
    local COLORS = self.COLORS
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 36); frame.BackgroundTransparency = 1; frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.72, -6, 1, 0); label.BackgroundTransparency = 1
    label.Text = labelText or "Toggle"; label.Font = Enum.Font.GothamBold; label.TextSize = 17
    label.TextColor3 = COLORS.text; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = frame
    self:_register(label)

    local tooltip
    if tooltipText and type(tooltipText) == "string" then
        tooltip = Instance.new("TextLabel")
        tooltip.Name = "Tooltip"; tooltip.Text = tooltipText; tooltip.Font = Enum.Font.Gotham
        tooltip.TextSize = 14; tooltip.TextColor3 = COLORS.text; tooltip.TextWrapped = true
        tooltip.BackgroundColor3 = COLORS.panel; tooltip.BorderSizePixel = 0
        tooltip.AnchorPoint = Vector2.new(0.5, 0); tooltip.BackgroundTransparency = 1
        tooltip.TextTransparency = 1; tooltip.Visible = false; tooltip.ZIndex = 10000; tooltip.Parent = frame
        Instance.new("UICorner", tooltip).CornerRadius = UDim.new(0, 6)
        local tp = Instance.new("UIPadding", tooltip)
        tp.PaddingLeft = UDim.new(0,8); tp.PaddingRight = UDim.new(0,8); tp.PaddingTop = UDim.new(0,6); tp.PaddingBottom = UDim.new(0,6)
        local ts = Instance.new("UIStroke", tooltip) ts.Color = COLORS.divider ts.Thickness = 1
        self:_register(tooltip)
    end

    local surfaceColor = COLORS.panel
    local accentVisible = (COLORS.accent):Lerp(COLORS.white, 0.18)
    local lightStroke   = (COLORS.panel):Lerp(COLORS.text, 0.18)

    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(0, 56, 0, 28); toggle.AnchorPoint = Vector2.new(1, 0.5)
    toggle.Position = UDim2.new(1, -8, 0.5, 0); toggle.BackgroundColor3 = surfaceColor
    toggle.ClipsDescendants = true; toggle.Parent = frame
    self:_register(toggle)
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 14)
    local toggleStroke = Instance.new("UIStroke", toggle) toggleStroke.Thickness = 1 toggleStroke.Color = lightStroke toggleStroke.Transparency = 0.85

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0); fill.BackgroundColor3 = accentVisible; fill.BackgroundTransparency = 1; fill.Parent = toggle
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 14)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 22, 0, 22); knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = UDim2.new(0, 6, 0.5, 0); knob.BackgroundColor3 = COLORS.white; knob.ZIndex = 2; knob.Parent = toggle
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 11)
    local kStroke = Instance.new("UIStroke", knob) kStroke.Thickness = 1 kStroke.Color = (COLORS.panel):Lerp(COLORS.text, 0.14) kStroke.Transparency = 0.9

    local state = false
    local tweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local api -- forward

    local function setVisual(on)
        state = not not on
        if state then
            TweenService:Create(fill, TweenInfo.new(0.22), {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 0.45}):Play()
            TweenService:Create(toggle, TweenInfo.new(0.22), {BackgroundColor3 = surfaceColor:Lerp(accentVisible, 0.06)}):Play()
            TweenService:Create(knob, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -30, 0.5, 0)}):Play()
            toggleStroke.Color = accentVisible
            TweenService:Create(kStroke, TweenInfo.new(0.18), {Transparency = 1}):Play()
        else
            TweenService:Create(fill, tweenInfo, {Size = UDim2.new(0,0,1,0), BackgroundTransparency = 1}):Play()
            TweenService:Create(toggle, tweenInfo, {BackgroundColor3 = surfaceColor}):Play()
            TweenService:Create(knob, tweenInfo, {Position = UDim2.new(0, 6, 0.5, 0)}):Play()
            toggleStroke.Color = lightStroke
            TweenService:Create(kStroke, TweenInfo.new(0.18), {Transparency = 0.9}):Play()
        end
        if api and type(api.OnToggle) == "function" then pcall(api.OnToggle, state) end
    end

    api = { Set = function(v) setVisual(v) end, Get = function() return state end, OnToggle = nil }
    self.ToggleAPI[frame] = api

    if tooltip then
        local timer
        toggle.MouseEnter:Connect(function()
            TweenService:Create(knob, TweenInfo.new(0.12), {Size = UDim2.new(0, 24, 0, 24)}):Play()
            timer = tick()
            task.delay(0.5, function()
                if timer and (tick() - timer) >= 0.5 and tooltip.Parent then
                    tooltip.Visible = true; tooltip.Size = UDim2.new(0, 200, 0, 50)
                    tooltip.Position = UDim2.new(0.5, 0, 0.8, 0)
                    TweenService:Create(tooltip, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
                    TweenService:Create(tooltip, TweenInfo.new(0.12), {TextTransparency = 0}):Play()
                end
            end)
        end)
        toggle.MouseLeave:Connect(function()
            TweenService:Create(knob, TweenInfo.new(0.12), {Size = UDim2.new(0, 22, 0, 22)}):Play()
            timer = nil
            TweenService:Create(tooltip, TweenInfo.new(0.12), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
            task.delay(0.14, function() if tooltip.Parent then tooltip.Visible = false end end)
        end)
    else
        toggle.MouseEnter:Connect(function() TweenService:Create(knob, TweenInfo.new(0.12), {Size = UDim2.new(0, 24, 0, 24)}):Play() end)
        toggle.MouseLeave:Connect(function() TweenService:Create(knob, TweenInfo.new(0.12), {Size = UDim2.new(0, 22, 0, 22)}):Play() end)
    end

    toggle.Active = true
    toggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then setVisual(not state) end
    end)

    frame.LayoutOrder = nextOrder(parent, frame)
    setVisual(false)

    local handle = { Frame = frame, Get = api.Get, Set = api.Set }
    setmetatable(handle, { __newindex = function(t, k, v)
        if k == "OnChanged" or k == "OnToggle" then api.OnToggle = v else rawset(t, k, v) end
    end })
    return handle
end

----------------------------------------------------------------------
-- Button
----------------------------------------------------------------------

function Library:Button(parent, labelText)
    local COLORS = self.COLORS
    local frame = Instance.new("Frame")
    frame.Name = tostring(labelText or "Button")
    frame.Size = UDim2.new(1, 0, 0, 34); frame.BackgroundTransparency = 1; frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.72, -6, 1, 0); label.BackgroundTransparency = 1
    label.Text = labelText or "Button"; label.Font = Enum.Font.GothamBold; label.TextSize = 18
    label.TextColor3 = COLORS.text; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 84, 0, 26); btn.AnchorPoint = Vector2.new(1,0.5)
    btn.Position = UDim2.new(1, -8, 0.5, 0); btn.BackgroundColor3 = COLORS.panelDark; btn.AutoButtonColor = true
    btn.Font = Enum.Font.Gotham; btn.TextSize = 16; btn.TextColor3 = COLORS.text; btn.Text = "Click"; btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    local api = { OnClick = nil }
    self.ButtonAPI[frame] = api
    btn.MouseButton1Click:Connect(function() if type(api.OnClick) == "function" then pcall(api.OnClick) end end)

    frame.LayoutOrder = nextOrder(parent, frame)
    local handle = { Frame = frame, Button = btn }
    setmetatable(handle, { __newindex = function(t, k, v)
        if k == "OnClick" then api.OnClick = v else rawset(t, k, v) end
    end })
    return handle
end

----------------------------------------------------------------------
-- Slider
----------------------------------------------------------------------

function Library:Slider(parent, labelText, minVal, maxVal, defaultVal)
    local COLORS = self.COLORS
    local MIN = (type(minVal)=="number") and minVal or 1
    local MAX = (type(maxVal)=="number") and maxVal or 100
    local initial = (type(defaultVal)=="number") and defaultVal or math.floor((MIN+MAX)/2)

    local frame = Instance.new("Frame")
    frame.Name = tostring(labelText or "Slider")
    frame.Size = UDim2.new(1, 0, 0, 34); frame.BackgroundTransparency = 1; frame.Parent = parent
    self:_register(frame)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, -6, 1, 0); label.BackgroundTransparency = 1
    label.Text = labelText or "Slider"; label.Font = Enum.Font.GothamBold; label.TextSize = 18
    label.TextColor3 = COLORS.text; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = frame

    local holder = Instance.new("Frame")
    holder.AnchorPoint = Vector2.new(1, 0); holder.Position = UDim2.new(1, -8, 0, 2)
    holder.Size = UDim2.new(0.6, -8, 1, -4); holder.BackgroundTransparency = 1; holder.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 12); bar.Position = UDim2.new(0, 0, 0.5, -6)
    bar.BackgroundColor3 = COLORS.panelDark; bar.BorderSizePixel = 0; bar.Parent = holder
    self:_register(bar)
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0,6)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0); fill.BackgroundColor3 = COLORS.accent; fill.BorderSizePixel = 0; fill.Parent = bar
    self:_register(fill)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0,6)

    local handleBtn = Instance.new("TextButton")
    handleBtn.Size = UDim2.new(0, 16, 0, 16); handleBtn.Position = UDim2.new(0, -8, 0.5, -8)
    handleBtn.AnchorPoint = Vector2.new(0.5, 0.5); handleBtn.AutoButtonColor = false
    handleBtn.BackgroundColor3 = COLORS.panel; handleBtn.Text = ""; handleBtn.Parent = bar
    self:_register(handleBtn)
    Instance.new("UICorner", handleBtn).CornerRadius = UDim.new(0,8)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.5, 0, 1, 0); valueLabel.Position = UDim2.new(0.25, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1; valueLabel.Font = Enum.Font.GothamBold; valueLabel.TextSize = 14
    valueLabel.TextColor3 = COLORS.text; valueLabel.Text = tostring(initial)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Center; valueLabel.Parent = holder

    local dragging = false
    local current = math.clamp(initial, MIN, MAX)
    local api

    local function setValue(v)
        v = math.floor(math.clamp(v or MIN, MIN, MAX))
        local prev = current
        current = v
        local pct = (MAX > MIN) and (current - MIN) / (MAX - MIN) or 0
        fill.Size = UDim2.new(pct, 0, 1, 0)
        handleBtn.Position = UDim2.new(pct, 0, 0.5, 0)
        valueLabel.Text = tostring(current)
        if current ~= prev and api and type(api.OnChange) == "function" then pcall(api.OnChange, current) end
    end

    local function inputToValue(inputX)
        local absPos = inputX - bar.AbsolutePosition.X
        local w = bar.AbsoluteSize.X
        local pct = (w > 0) and math.clamp(absPos / w, 0, 1) or 0
        return math.floor(MIN + pct * (MAX - MIN) + 0.5)
    end

    handleBtn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    handleBtn.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    bar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then setValue(inputToValue(input.Position.X)) end end)
    self._dragConnections[function(input) if dragging then setValue(inputToValue(input.Position.X)) end end] = true

    api = { Get = function() return current end, Set = function(v) setValue(v) end, OnChange = nil, Min = MIN, Max = MAX }
    self.SliderAPI[frame] = api

    frame.LayoutOrder = nextOrder(parent, frame)
    -- defer initial render until bar has a size
    if bar.AbsoluteSize.X > 0 then setValue(current)
    else
        local conn
        conn = bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            if bar.AbsoluteSize.X > 0 then setValue(current) if conn then conn:Disconnect() end end
        end)
        task.delay(0.1, function() setValue(current) if conn then conn:Disconnect() end end)
    end

    local handle = { Frame = frame, Get = api.Get, Set = api.Set }
    setmetatable(handle, { __newindex = function(t, k, v)
        if k == "OnChanged" or k == "OnChange" then api.OnChange = v else rawset(t, k, v) end
    end })
    return handle
end

----------------------------------------------------------------------
-- Keybind
----------------------------------------------------------------------

function Library:Keybind(parent, title, defaultKey)
    local COLORS = self.COLORS
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,34); frame.BackgroundTransparency = 1; frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, -6, 1, 0); label.BackgroundTransparency = 1
    label.Text = title or "Keybind"; label.Font = Enum.Font.GothamBold; label.TextSize = 18
    label.TextColor3 = COLORS.text; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.5, -8, 1, 0); btn.AnchorPoint = Vector2.new(1,0)
    btn.Position = UDim2.new(1, -8, 0, 0); btn.BackgroundColor3 = COLORS.panelDark; btn.AutoButtonColor = true
    btn.Font = Enum.Font.Gotham; btn.TextSize = 16; btn.TextColor3 = COLORS.text; btn.Text = "None"; btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    local function keyName(k)
        if not k then return "None" end
        if typeof(k) == "EnumItem" then return k.Name end
        return tostring(k)
    end

    local current = (typeof(defaultKey) == "EnumItem") and defaultKey or nil
    local listening, pending, inputConn = false, nil, nil
    local keyListenerConn = nil
    local api

    local function stopKeyListener() if keyListenerConn then keyListenerConn:Disconnect() keyListenerConn = nil end end
    local function startKeyListener(bound)
        stopKeyListener()
        if not (typeof(bound) == "EnumItem" and bound.EnumType == Enum.KeyCode) then return end
        keyListenerConn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            local disabled = api and api.IsDisabled and api.IsDisabled() or false
            if input.KeyCode == bound and not disabled and api and type(api.OnActivate) == "function" then
                api.OnActivate(bound)
            end
        end)
    end

    local function updateText()
        if listening then
            btn.Text = 'Press a key, then Enter…'
        else
            local disabled = api and api.IsDisabled and api.IsDisabled() or false
            if disabled then
                btn.Text = keyName(current) .. " (Disabled)"
                btn.TextColor3 = self.COLORS.divider
            else
                btn.Text = keyName(current); btn.TextColor3 = self.COLORS.text
            end
        end
    end

    btn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true; pending = nil; updateText()
        task.wait(0.05)
        inputConn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            local kc = input.KeyCode
            if kc == Enum.KeyCode.Unknown then return end
            if kc == Enum.KeyCode.Return or kc == Enum.KeyCode.KeypadEnter then
                if pending then
                    current = pending
                    if api and type(api.OnBind) == "function" then pcall(api.OnBind, current) end
                    startKeyListener(current)
                end
                listening = false; if inputConn then inputConn:Disconnect() inputConn = nil end; updateText()
            elseif kc == Enum.KeyCode.Escape then
                listening = false; pending = nil; if inputConn then inputConn:Disconnect() inputConn = nil end; updateText()
            else
                pending = kc; btn.Text = kc.Name .. " (Enter to save)"
            end
        end)
    end)

    api = {
        Get = function() return current end,
        Set = function(k) current = (typeof(k)=="EnumItem") and k or nil; updateText(); startKeyListener(current) end,
        IsDisabled = function() return self.DisabledKeybinds[frame] == true end,
        SetDisabled = function(b) self.DisabledKeybinds[frame] = not not b; updateText() end,
        Refresh = updateText, OnBind = nil, OnActivate = nil,
    }
    self.KeybindAPI[frame] = api

    -- right-click toggles disabled
    btn.MouseButton2Click:Connect(function() api.SetDisabled(not api.IsDisabled()) end)

    startKeyListener(current)
    frame.LayoutOrder = nextOrder(parent, frame)
    updateText()

    local handle = { Frame = frame, Get = api.Get, Set = api.Set,
        SetDisabled = api.SetDisabled, IsDisabled = api.IsDisabled }
    setmetatable(handle, { __newindex = function(t, k, v)
        if k == "OnActivate" then api.OnActivate = v
        elseif k == "OnBind" then api.OnBind = v
        else rawset(t, k, v) end
    end })
    return handle
end

----------------------------------------------------------------------
-- Dropdown
----------------------------------------------------------------------

function Library:Dropdown(parent, labelText, items, defaultIndex)
    local COLORS = self.COLORS
    local frame = Instance.new("Frame")
    frame.Name = tostring(labelText or "DropDown")
    frame.Size = UDim2.new(1, 0, 0, 34); frame.BackgroundTransparency = 1; frame.Parent = parent
    self:_register(frame)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, -6, 1, 0); label.BackgroundTransparency = 1
    label.Text = labelText or "Select"; label.Font = Enum.Font.GothamBold; label.TextSize = 18
    label.TextColor3 = COLORS.text; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = frame

    local display = Instance.new("TextButton")
    display.Size = UDim2.new(0.4, -8, 1, 0); display.AnchorPoint = Vector2.new(1, 0)
    display.Position = UDim2.new(1, -8, 0, 0); display.BackgroundColor3 = COLORS.panelDark; display.AutoButtonColor = false
    display.Font = Enum.Font.Gotham; display.TextSize = 16; display.TextColor3 = COLORS.text; display.Text = ""
    display.TextXAlignment = Enum.TextXAlignment.Left; display.Parent = frame
    self:_register(display)
    Instance.new("UICorner", display).CornerRadius = UDim.new(0,6)
    local dp = Instance.new("UIPadding", display) dp.PaddingLeft = UDim.new(0,8); dp.PaddingRight = UDim.new(0,28)

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 24, 1, 0); arrow.AnchorPoint = Vector2.new(1,0.5)
    arrow.Position = UDim2.new(1, -4, 0.5, 0); arrow.BackgroundTransparency = 1
    arrow.Font = Enum.Font.Gotham; arrow.TextSize = 18; arrow.TextColor3 = COLORS.textDim; arrow.Text = "▾"; arrow.Parent = display

    local DROP_Z = 50
    local drop = Instance.new("Frame")
    drop.Size = UDim2.new(1, 0, 0, 0); drop.Position = UDim2.new(0, 0, 1, 6)
    drop.BackgroundColor3 = COLORS.panelAlt; drop.ClipsDescendants = true; drop.Visible = false
    drop.ZIndex = DROP_Z; drop.Parent = frame
    self:_register(drop)
    Instance.new("UICorner", drop).CornerRadius = UDim.new(0,8)
    local ds = Instance.new("UIStroke", drop) ds.Thickness = 1 ds.Color = COLORS.divider

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -12, 1, -12); scroll.Position = UDim2.new(0, 6, 0, 6)
    scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 8; scroll.ZIndex = DROP_Z; scroll.Parent = drop
    pcall(function() scroll.ScrollBarImageColor3 = COLORS.accent end)
    local sl = Instance.new("UIListLayout", scroll) sl.SortOrder = Enum.SortOrder.LayoutOrder sl.Padding = UDim.new(0, 4)
    local sp = Instance.new("UIPadding", scroll) sp.PaddingTop = UDim.new(0,4); sp.PaddingBottom = UDim.new(0,4)

    items = items or {}
    local selected, btnRefs = nil, {}
    local api

    local function populate()
        for _,c in ipairs(scroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        btnRefs = {}
        for i, v in ipairs(items) do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 28); b.BackgroundTransparency = 1; b.AutoButtonColor = false
            b.Font = Enum.Font.Gotham; b.TextSize = 16; b.TextColor3 = COLORS.text; b.Text = tostring(v)
            b.LayoutOrder = i; b.ZIndex = DROP_Z + 1; b.Parent = scroll
            Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
            local bp = Instance.new("UIPadding", b) bp.PaddingLeft = UDim.new(0,8)
            btnRefs[i] = b
            b.MouseEnter:Connect(function() if selected and selected.index == i then return end
                TweenService:Create(b, TweenInfo.new(0.12), {BackgroundTransparency = 0, BackgroundColor3 = self.COLORS.panelAlt}):Play() end)
            b.MouseLeave:Connect(function() if selected and selected.index == i then return end
                TweenService:Create(b, TweenInfo.new(0.12), {BackgroundTransparency = 1}):Play() end)
            b.MouseButton1Click:Connect(function()
                for k, ref in pairs(btnRefs) do ref.BackgroundTransparency = 1; ref.TextColor3 = self.COLORS.text end
                b.BackgroundTransparency = 0; b.BackgroundColor3 = self.COLORS.highlight; b.TextColor3 = self.COLORS.white
                selected = { index = i, value = v }; display.Text = tostring(v)
                drop.Visible = false; TweenService:Create(drop, TweenInfo.new(0.12), {Size = UDim2.new(1,0,0,0)}):Play()
                arrow.Text = "▾"
                if api and type(api.OnSelect) == "function" then pcall(api.OnSelect, i, v) end
            end)
        end
        drop.Size = UDim2.new(1, 0, 0, math.min(#items * 28, 200))
    end

    display.MouseButton1Click:Connect(function()
        local open = not drop.Visible
        local target = math.min(#items * 28, 200)
        if open then
            drop.Visible = true
            TweenService:Create(drop, TweenInfo.new(0.18), {Size = UDim2.new(1,0,0,target)}):Play()
            arrow.Text = "▴"
        else
            local tw = TweenService:Create(drop, TweenInfo.new(0.12), {Size = UDim2.new(1,0,0,0)})
            tw:Play(); tw.Completed:Connect(function() drop.Visible = false end)
            arrow.Text = "▾"
        end
    end)

    api = {
        SetItems = function(tbl) items = tbl or {}; populate() end,
        Set = function(idx)
            local v = items[idx]
            if v ~= nil then
                selected = { index = idx, value = v }; display.Text = tostring(v)
                for k, ref in pairs(btnRefs) do ref.BackgroundTransparency = 1; ref.TextColor3 = self.COLORS.text end
                if btnRefs[idx] then btnRefs[idx].BackgroundTransparency = 0; btnRefs[idx].BackgroundColor3 = self.COLORS.highlight; btnRefs[idx].TextColor3 = self.COLORS.white end
            end
        end,
        Get = function() return selected end,
        OnSelect = nil,
    }
    self.DropdownAPI[frame] = api

    populate()
    if defaultIndex then api.Set(defaultIndex) end
    frame.LayoutOrder = nextOrder(parent, frame)

    local handle = { Frame = frame, Get = api.Get, Set = api.Set, SetItems = api.SetItems }
    setmetatable(handle, { __newindex = function(t, k, v)
        if k == "OnChanged" or k == "OnSelect" then api.OnSelect = v else rawset(t, k, v) end
    end })
    return handle
end

----------------------------------------------------------------------
-- Color Picker (HSV wheel + brightness slider)
----------------------------------------------------------------------

function Library:ColorPicker(parent, labelText, defaultColor)
    local COLORS = self.COLORS
    local frame = Instance.new("Frame")
    frame.Name = tostring(labelText or "ColorPicker")
    frame.Size = UDim2.new(1, 0, 0, 34); frame.BackgroundTransparency = 1; frame.Parent = parent
    self:_register(frame)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, -6, 1, 0); label.BackgroundTransparency = 1
    label.Text = labelText or "Color"; label.Font = Enum.Font.GothamBold; label.TextSize = 18
    label.TextColor3 = COLORS.text; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = frame

    local display = Instance.new("TextButton")
    display.Size = UDim2.new(0.48, 0, 1, 0); display.AnchorPoint = Vector2.new(1, 0)
    display.Position = UDim2.new(1, 0, 0, 0); display.BackgroundColor3 = COLORS.panelDark; display.BorderSizePixel = 0
    display.AutoButtonColor = false; display.Text = ""; display.Parent = frame
    self:_register(display)
    Instance.new("UICorner", display).CornerRadius = UDim.new(0,6)
    local dpad = Instance.new("UIPadding", display) dpad.PaddingLeft = UDim.new(0,8)

    local swatch = Instance.new("Frame")
    swatch.Size = UDim2.new(0, 20, 0, 20); swatch.Position = UDim2.new(0, 0, 0.5, -10)
    swatch.BackgroundColor3 = (typeof(defaultColor)=="Color3") and defaultColor or COLORS.accent
    swatch.BorderSizePixel = 0; swatch.Parent = display
    Instance.new("UICorner", swatch).CornerRadius = UDim.new(0,4)

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0,24,1,0); arrow.AnchorPoint = Vector2.new(1,0.5)
    arrow.Position = UDim2.new(1, -8, 0.5, 0); arrow.BackgroundTransparency = 1
    arrow.Font = Enum.Font.Gotham; arrow.TextSize = 18; arrow.TextColor3 = COLORS.textDim; arrow.Text = "▾"; arrow.Parent = display

    local TOP_Z = 600
    local palette = Instance.new("Frame")
    palette.Size = UDim2.new(1, 0, 0, 0); palette.Position = UDim2.new(0, 0, 1, 6)
    palette.BackgroundColor3 = COLORS.panelAlt; palette.ClipsDescendants = true; palette.Visible = false
    palette.ZIndex = TOP_Z; palette.Parent = frame
    self:_register(palette)
    Instance.new("UICorner", palette).CornerRadius = UDim.new(0,8)
    local ps = Instance.new("UIStroke", palette) ps.Thickness = 1 ps.Color = COLORS.divider

    local scroll = Instance.new("Frame")
    scroll.Size = UDim2.new(1, -12, 0, 56); scroll.Position = UDim2.new(0, 6, 0, 6)
    scroll.BackgroundTransparency = 1; scroll.ZIndex = TOP_Z; scroll.Parent = palette

    local function colorToHSVtbl(c)
        local ok, h, s, v = pcall(function() return Color3.toHSV(c) end)
        if ok and h then return {h=h*360, s=s*100, v=v*100} end
        return {h=200, s=100, v=100}
    end
    local initialHSV = colorToHSVtbl((typeof(defaultColor)=="Color3") and defaultColor or COLORS.accent)
    local currentHue, currentSat, currentValue = initialHSV.h/360, initialHSV.s/100, initialHSV.v/100
    local current = swatch.BackgroundColor3

    local wheelSize = 180
    local wheelFrame = Instance.new("Frame")
    wheelFrame.Size = UDim2.new(0, wheelSize, 0, wheelSize); wheelFrame.Position = UDim2.new(0, 40, 0, 6)
    wheelFrame.BackgroundTransparency = 1; wheelFrame.ZIndex = TOP_Z; wheelFrame.Parent = scroll

    local RES = 64
    local cellSize = wheelSize / RES
    local half, radius = wheelSize/2, wheelSize/2
    local intSize = math.ceil(cellSize) + 1
    for y = 0, RES-1 do
        for x = 0, RES-1 do
            local px, py = math.floor(x*cellSize), math.floor(y*cellSize)
            local cx, cy = (px + intSize*0.5) - half, (py + intSize*0.5) - half
            local dist = math.sqrt(cx*cx + cy*cy)
            if dist <= radius + 1 then
                local ang = math.atan2(cy, cx)
                local hue = ((ang / (2*math.pi)) + 0.5) % 1
                local sat = math.clamp(dist / radius, 0, 1)
                local cell = Instance.new("Frame")
                cell.Size = UDim2.new(0, intSize, 0, intSize); cell.Position = UDim2.new(0, px, 0, py)
                cell.BackgroundColor3 = Color3.fromHSV(hue, sat, 1); cell.BorderSizePixel = 0
                cell.ZIndex = TOP_Z; cell.Parent = wheelFrame
            end
        end
    end

    local pointer = Instance.new("Frame")
    pointer.Size = UDim2.new(0, 12, 0, 12); pointer.AnchorPoint = Vector2.new(0.5, 0.5)
    pointer.BackgroundTransparency = 1; pointer.ZIndex = TOP_Z + 1; pointer.Parent = wheelFrame
    Instance.new("UICorner", pointer).CornerRadius = UDim.new(1,0)
    local pst = Instance.new("UIStroke", pointer) pst.Thickness = 2 pst.Color = Color3.new(0,0,0)

    local valueSliderFrame = Instance.new("Frame")
    valueSliderFrame.Size = UDim2.new(0, 16, 0, wheelSize); valueSliderFrame.Position = UDim2.new(0, wheelSize + 8, 0, 6)
    valueSliderFrame.BackgroundColor3 = Color3.new(0.2,0.2,0.2); valueSliderFrame.BorderSizePixel = 0
    valueSliderFrame.ZIndex = TOP_Z; valueSliderFrame.Parent = scroll
    local valueHandle = Instance.new("Frame")
    valueHandle.Size = UDim2.new(1,0,0,8); valueHandle.AnchorPoint = Vector2.new(0.5,0.5)
    valueHandle.BackgroundColor3 = Color3.new(1,1,1); valueHandle.BorderSizePixel = 0; valueHandle.Parent = valueSliderFrame
    Instance.new("UICorner", valueHandle).CornerRadius = UDim.new(0,4)
    valueHandle.Position = UDim2.new(0.5,0,0,(1 - currentValue) * wheelSize)

    local api
    local function setColor(c)
        if not c then return end
        current = c; swatch.BackgroundColor3 = c
        if api and type(api.OnChange) == "function" then api.OnChange(c) end
    end

    local sliderDragging = false
    local function updateValueFromY(y)
        local localY = math.clamp(y - valueSliderFrame.AbsolutePosition.Y, 0, wheelSize)
        currentValue = 1 - (localY / wheelSize)
        valueHandle.Position = UDim2.new(0.5,0,0,localY)
        setColor(Color3.fromHSV(currentHue or 0, currentSat or 0, currentValue))
    end
    valueSliderFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then sliderDragging = true updateValueFromY(input.Position.Y) end end)
    valueSliderFrame.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then sliderDragging = false end end)

    local function posToColor(px, py)
        local cx, cy = px - half, py - half
        local dist = math.sqrt(cx*cx + cy*cy)
        local sat = math.clamp(dist / radius, 0, 1)
        local ang = math.atan2(cy, cx)
        local hue = ((ang / (2*math.pi)) + 0.5) % 1
        return hue, sat
    end
    local wheelDragging = false
    local function updatePointerAt(screenX, screenY)
        local localPos = Vector2.new(screenX, screenY) - Vector2.new(wheelFrame.AbsolutePosition.X, wheelFrame.AbsolutePosition.Y)
        local lx, ly = math.clamp(localPos.X, 0, wheelSize), math.clamp(localPos.Y, 0, wheelSize)
        local hue, sat = posToColor(lx, ly)
        currentHue, currentSat = hue, sat
        setColor(Color3.fromHSV(hue, sat, currentValue))
        pointer.Position = UDim2.new(0, lx, 0, ly)
    end
    wheelFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then wheelDragging = true updatePointerAt(input.Position.X, input.Position.Y) end end)
    wheelFrame.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then wheelDragging = false end end)

    self._dragConnections[function(input)
        if sliderDragging then updateValueFromY(input.Position.Y) end
        if wheelDragging then updatePointerAt(input.Position.X, input.Position.Y) end
    end] = true

    display.Active = true
    display.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local open = not palette.Visible
        if open then
            palette.Visible = true; arrow.Text = "▴"
            TweenService:Create(palette, TweenInfo.new(0.18), {Size = UDim2.new(1,0,0,220)}):Play()
        else
            local tw = TweenService:Create(palette, TweenInfo.new(0.12), {Size = UDim2.new(1,0,0,0)})
            tw:Play(); tw.Completed:Connect(function() palette.Visible = false; arrow.Text = "▾" end)
        end
    end)

    api = {
        Get = function() return current end,
        Set = function(c)
            setColor(c)
            local h,s,v = Color3.toHSV(c)
            currentHue, currentSat, currentValue = h, s, v
            local px = (math.cos(h*2*math.pi - math.pi) * (s*radius)) + half
            local py = (math.sin(h*2*math.pi - math.pi) * (s*radius)) + half
            pointer.Position = UDim2.new(0, px, 0, py)
            valueHandle.Position = UDim2.new(0.5,0,0,(1 - v) * wheelSize)
        end,
        OnChange = nil,
    }
    self.ColorPickerAPI[frame] = api

    frame.LayoutOrder = nextOrder(parent, frame)
    local handle = { Frame = frame, Get = api.Get, Set = api.Set }
    setmetatable(handle, { __newindex = function(t, k, v)
        if k == "OnChanged" or k == "OnChange" then api.OnChange = v else rawset(t, k, v) end
    end })
    return handle
end

----------------------------------------------------------------------
-- Notifications
----------------------------------------------------------------------

function Library:Notify(text, duration)
    local COLORS = self.COLORS
    local dur = (type(duration)=="number" and duration > 0) and duration or 3

    local holder = self.gui:FindFirstChild("NotificationsHolder")
    if not holder then
        holder = Instance.new("Frame")
        holder.Name = "NotificationsHolder"
        holder.Size = UDim2.new(0, 420, 0, 200)
        holder.AnchorPoint = Vector2.new(1, 1)
        holder.Position = UDim2.new(1, -12, 1, -12)
        holder.BackgroundTransparency = 1
        holder.ZIndex = 10000
        holder.Parent = self.gui
        local layout = Instance.new("UIListLayout", holder)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 8)
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    end

    local msgStr = tostring(text or "Notification")
    local fontSize, font = 16, Enum.Font.GothamBold
    local screenW = (self.gui.AbsoluteSize and self.gui.AbsoluteSize.X) or 760
    local maxAllowed = math.max(240, screenW - 24)
    local maxContentW = math.min(600, maxAllowed - 80)
    local measured = TextService:GetTextSize(msgStr, fontSize, font, Vector2.new(maxContentW, 10000))
    local targetW = math.min(math.max(math.ceil(measured.X + 80), 240), maxAllowed)
    local targetH = math.max(56, math.ceil(measured.Y + 24))

    local container = Instance.new("Frame")
    container.Name = "Notification"
    container.Size = UDim2.new(0, targetW, 0, 0)
    container.BackgroundColor3 = COLORS.panelDark
    container.BorderSizePixel = 0
    container.ZIndex = holder.ZIndex
    container.LayoutOrder = math.floor(tick() * 1000)
    container.Parent = holder
    self:_register(container)
    Instance.new("UICorner", container).CornerRadius = UDim.new(0,10)
    local cs = Instance.new("UIStroke", container) cs.Color = COLORS.divider cs.Thickness = 1

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 6, 1, 0); accent.BackgroundColor3 = COLORS.accent; accent.BorderSizePixel = 0
    accent.ZIndex = container.ZIndex + 2; accent.Parent = container
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0,4)

    local inner = Instance.new("Frame")
    inner.Size = UDim2.new(1, -20, 1, -12); inner.Position = UDim2.new(0, 12, 0, 6)
    inner.BackgroundTransparency = 1; inner.ZIndex = container.ZIndex + 1; inner.Parent = container

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 28, 0, 28); icon.Position = UDim2.new(0, 0, 0.5, -14)
    icon.BackgroundTransparency = 1; icon.Font = Enum.Font.GothamBold; icon.TextSize = 18
    icon.TextColor3 = COLORS.accent; icon.Text = "🔔"; icon.TextTransparency = 1
    icon.ZIndex = inner.ZIndex + 1; icon.Parent = inner

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -36, 1, 0); lbl.Position = UDim2.new(0, 36, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Font = font; lbl.TextSize = fontSize; lbl.Text = msgStr
    lbl.TextColor3 = COLORS.text; lbl.TextStrokeTransparency = 0.7
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.TextWrapped = true; lbl.TextTransparency = 1; lbl.ZIndex = inner.ZIndex + 1; lbl.Parent = inner

    local barHolder = Instance.new("Frame")
    barHolder.Size = UDim2.new(1, -20, 0, 6); barHolder.Position = UDim2.new(0, 10, 1, -10)
    barHolder.BackgroundTransparency = 1; barHolder.ZIndex = container.ZIndex + 1; barHolder.Parent = container
    local prog = Instance.new("Frame")
    prog.AnchorPoint = Vector2.new(1, 0); prog.Position = UDim2.new(1, 0, 0, 0); prog.Size = UDim2.new(1, 0, 1, 0)
    prog.BackgroundColor3 = COLORS.accent; prog.BorderSizePixel = 0; prog.ZIndex = container.ZIndex + 2; prog.Parent = barHolder
    Instance.new("UICorner", prog).CornerRadius = UDim.new(0,3)

    TweenService:Create(container, TweenInfo.new(0.34, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Size = UDim2.new(0, targetW, 0, targetH)}):Play()
    TweenService:Create(lbl, TweenInfo.new(0.28), {TextTransparency = 0}):Play()
    TweenService:Create(icon, TweenInfo.new(0.28), {TextTransparency = 0}):Play()
    TweenService:Create(prog, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)}):Play()

    task.delay(dur, function()
        pcall(function()
            TweenService:Create(lbl, TweenInfo.new(0.22), {TextTransparency = 1}):Play()
            TweenService:Create(icon, TweenInfo.new(0.22), {TextTransparency = 1}):Play()
            TweenService:Create(container, TweenInfo.new(0.28), {Size = UDim2.new(0, targetW, 0, 0)}):Play()
        end)
        task.delay(0.32, function() pcall(function() container:Destroy() end) end)
    end)

    return container
end

----------------------------------------------------------------------
-- Toast (transient top-center banner)
----------------------------------------------------------------------

function Library:Toast(text, duration)
    local COLORS = self.COLORS
    if not self._toastHolder then
        local holder = Instance.new("Frame")
        holder.Name = "ToastHolder"
        holder.AnchorPoint = Vector2.new(0.5, 0)
        holder.Position = UDim2.new(0.5, 0, 0, 8)
        holder.BackgroundTransparency = 1
        holder.Size = UDim2.new(0, 0, 0, 0)
        holder.AutomaticSize = Enum.AutomaticSize.XY
        holder.ZIndex = 700
        holder.Parent = self.gui
        local layout = Instance.new("UIListLayout", holder)
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 8)
        self._toastHolder = holder
    end

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 0.12
    frame.BackgroundColor3 = COLORS.panelAlt
    frame.Size = UDim2.new(0, 260, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.ZIndex = 701
    frame.Parent = self._toastHolder
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local st = Instance.new("UIStroke", frame) st.Thickness = 1 st.Color = COLORS.divider
    local pad = Instance.new("UIPadding", frame)
    pad.PaddingLeft = UDim.new(0,10); pad.PaddingRight = UDim.new(0,10); pad.PaddingTop = UDim.new(0,6); pad.PaddingBottom = UDim.new(0,6)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 0); lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1; lbl.Text = tostring(text or "")
    lbl.TextWrapped = true; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 16
    lbl.TextColor3 = COLORS.tabText; lbl.ZIndex = 702; lbl.Parent = frame

    self:_register(frame, function() frame.BackgroundColor3 = self.COLORS.panelAlt; st.Color = self.COLORS.divider end)
    self:_register(lbl, function() lbl.TextColor3 = self.COLORS.tabText end)

    task.delay((type(duration)=="number" and duration) or 3, function()
        pcall(function() if frame.Parent then frame:Destroy() end end)
    end)
    return frame
end

----------------------------------------------------------------------
-- Teardown
----------------------------------------------------------------------

function Library:Destroy()
    pcall(function() if self._inputChangedConn then self._inputChangedConn:Disconnect() end end)
    pcall(function() if self.gui then self.gui:Destroy() end end)
end

return Library
