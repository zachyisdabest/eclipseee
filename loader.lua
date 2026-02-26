-- Eclipse Loader.lua — one-time online check, then trust local save

-- Services
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

-- Config
local SAVED_KEY_FILE = "eclipse_key.txt"      -- presence of this file = already verified on this device
local MAIN_HUB_URL   = "https://raw.githubusercontent.com/zachyisdabest/Eclipse/main/mainhub.lua"
local VERIFY_BASE    = "https://03df6bdd-28f6-44f5-b766-5bf63d614ed5-00-22hauxpzzfxdx.janeway.replit.dev/verify" -- your Replit endpoint

-- File helpers
local function has_saved_ok()
    return isfile and isfile(SAVED_KEY_FILE)
end

local function save_ok(key)
    if writefile then
        -- store something simple; key optional
        writefile(SAVED_KEY_FILE, tostring(key or "OK"))
    end
end

local function delete_saved_ok()
    if delfile and isfile and isfile(SAVED_KEY_FILE) then
        pcall(delfile, SAVED_KEY_FILE)
    end
end

-- Verify against Replit once
local function verify_once(key)
    key = tostring(key or ""):gsub("^%s*(.-)%s*$", "%1")
    if key == "" then return false, "No key" end
    local url = VERIFY_BASE .. "?key=" .. key

    local ok, body = pcall(function() return game:HttpGet(url) end)
    if not ok then
        warn("[Eclipse] HTTP failed:", body)
        return false, "HTTP failed"
    end

    local okj, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not okj then
        warn("[Eclipse] JSON decode failed")
        return false, "Bad JSON"
    end

    if data.success == true then
        return true, data.message or "OK"
    else
        return false, data.message or "Invalid key"
    end
end

-- Load hub
local function load_hub(ui, bar)
    if bar then
        local t = TweenService:Create(bar, TweenInfo.new(3.5), { Size = UDim2.new(1,0,0,5) })
        bar.Visible = true; t:Play(); t.Completed:Wait()
    end
    if ui and ui.Parent then ui:Destroy() end
    _G.EclipseLoaded = true
    loadstring(game:HttpGet(MAIN_HUB_URL))()
end

-- If already verified on this device, skip online check
if has_saved_ok() then
    load_hub()
    return
end

-- UI
local function show_ui()
    local parent = (gethui and gethui()) or game.CoreGui
    local gui = Instance.new("ScreenGui", parent)
    gui.Name = "EclipseLoader"

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 300, 0, 210)
    frame.Position = UDim2.new(0.5,-150,0.5,-105)
    frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    frame.Active = true; frame.Draggable = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,0,0,40)
    title.BackgroundTransparency = 1
    title.Text = "Eclipse Loader"
    title.Font = Enum.Font.GothamBold; title.TextSize = 22
    title.TextColor3 = Color3.new(1,1,1)

    local box = Instance.new("TextBox", frame)
    box.Size = UDim2.new(0.9,0,0,30)
    box.Position = UDim2.new(0.05,0,0,55)
    box.PlaceholderText = "Enter License Key"
    box.Text = ""; box.Font = Enum.Font.Gotham; box.TextSize = 16
    box.TextColor3 = Color3.new(0,0,0)
    box.BackgroundColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,6)

    local status = Instance.new("TextLabel", frame)
    status.Position = UDim2.new(0.05,0,0,95)
    status.Size = UDim2.new(0.9,0,0,20)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.Font = Enum.Font.Gotham; status.TextSize = 14
    status.TextColor3 = Color3.new(1,1,1)

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.9,0,0,30)
    btn.Position = UDim2.new(0.05,0,0,125)
    btn.Text = "Verify Key"
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 16
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.fromRGB(30,150,255)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    local reset = Instance.new("TextButton", frame)
    reset.Size = UDim2.new(0.9,0,0,24)
    reset.Position = UDim2.new(0.05,0,0,162)
    reset.Text = "Reset Saved Key"
    reset.Font = Enum.Font.GothamBold; reset.TextSize = 14
    reset.TextColor3 = Color3.new(1,1,1)
    reset.BackgroundColor3 = Color3.fromRGB(200,60,60)
    Instance.new("UICorner", reset).CornerRadius = UDim.new(0,6)

    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(0,0,0,5)
    bar.Position = UDim2.new(0,0,1,-5)
    bar.BackgroundColor3 = Color3.fromRGB(0,255,0)
    bar.Visible = false

    reset.MouseButton1Click:Connect(function()
        delete_saved_ok()
        status.Text = "Saved key removed."
    end)

    local debounce = false
    btn.MouseButton1Click:Connect(function()
        if debounce then return end
        debounce = true
        status.Text = "Verifying..."
        local key = box.Text
        local ok, msg = verify_once(key)
        if ok then
            status.Text = "Key valid. Loading..."
            save_ok(key)             -- mark device as verified
            task.wait(0.6)
            load_hub(gui, bar)
        else
            status.Text = "Invalid key: " .. tostring(msg or "")
            task.delay(0.6, function() debounce = false end)
        end
    end)
end

show_ui()
