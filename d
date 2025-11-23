--[[
    ═══════════════════════════════════════════════════════════
    📦 MAP CLONER - SOLARA FILE SAVER
    ═══════════════════════════════════════════════════════════
    
    ✅ ينسخ الماب
    ✅ يحفظ في ملف على جهازك
    ✅ المسار: Solara/workspace/SavedMaps/
    
    يدعم: Solara, Wave, Synapse X
    
    ═══════════════════════════════════════════════════════════
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

print("═══════════════════════════════════════")
print("📦 MAP CLONER - Solara File Saver")
print("═══════════════════════════════════════")

-- التحقق من دعم حفظ الملفات
if not writefile or not makefolder then
    warn("⚠️ هذا الإكسبلويت لا يدعم حفظ الملفات!")
    warn("⚠️ استخدم Solara أو Wave أو Synapse X")
    return
end

-- إنشاء مجلد الحفظ
local folderPath = "SavedMaps"
local success = pcall(function()
    makefolder(folderPath)
end)

if success then
    print("✅ تم إنشاء المجلد: workspace/" .. folderPath)
else
    print("ℹ️ المجلد موجود مسبقاً")
end

-- دالة تحويل Vector3 لنص
local function Vec3ToString(vec)
    return string.format("Vector3.new(%.2f, %.2f, %.2f)", vec.X, vec.Y, vec.Z)
end

-- دالة تحويل Color3 لنص
local function Color3ToString(color)
    return string.format("Color3.new(%.3f, %.3f, %.3f)", color.R, color.G, color.B)
end

-- دالة تحويل BasePart إلى كود Lua
local function PartToLua(part, varName, indent)
    indent = indent or ""
    local code = {}
    
    table.insert(code, indent .. "local " .. varName .. " = Instance.new('" .. part.ClassName .. "')")
    table.insert(code, indent .. varName .. ".Name = '" .. part.Name .. "'")
    
    if part:IsA("BasePart") then
        table.insert(code, indent .. varName .. ".Size = " .. Vec3ToString(part.Size))
        table.insert(code, indent .. varName .. ".Position = " .. Vec3ToString(part.Position))
        table.insert(code, indent .. varName .. ".Rotation = " .. Vec3ToString(part.Rotation))
        table.insert(code, indent .. varName .. ".Color = " .. Color3ToString(part.Color))
        table.insert(code, indent .. varName .. ".Material = Enum.Material." .. tostring(part.Material))
        table.insert(code, indent .. varName .. ".Transparency = " .. part.Transparency)
        table.insert(code, indent .. varName .. ".Anchored = " .. tostring(part.Anchored))
        table.insert(code, indent .. varName .. ".CanCollide = " .. tostring(part.CanCollide))
        
        if part:IsA("MeshPart") then
            table.insert(code, indent .. varName .. ".MeshId = '" .. part.MeshId .. "'")
            table.insert(code, indent .. varName .. ".TextureID = '" .. part.TextureID .. "'")
        end
    end
    
    return table.concat(code, "\n")
end

-- دالة تحويل Model كامل إلى سكربت Lua
local function ModelToLuaScript(model, maxParts)
    maxParts = maxParts or 500
    local code = {}
    
    table.insert(code, "--[[")
    table.insert(code, "    ═══════════════════════════════════════")
    table.insert(code, "    📦 Generated Map: " .. model.Name)
    table.insert(code, "    🕐 Date: " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(code, "    ═══════════════════════════════════════")
    table.insert(code, "]]")
    table.insert(code, "")
    table.insert(code, "local model = Instance.new('Model')")
    table.insert(code, "model.Name = '" .. model.Name .. "'")
    table.insert(code, "model.Parent = workspace")
    table.insert(code, "")
    
    local partCount = 0
    local descendants = model:GetDescendants()
    
    for i, child in pairs(descendants) do
        if child:IsA("BasePart") then
            if partCount >= maxParts then
                table.insert(code, "")
                table.insert(code, "-- ⚠️ تم الوصول للحد الأقصى (" .. maxParts .. " عنصر)")
                table.insert(code, "-- إجمالي العناصر: " .. #descendants)
                break
            end
            
            local varName = "part" .. (partCount + 1)
            table.insert(code, "-- " .. child.Name .. " (" .. child.ClassName .. ")")
            table.insert(code, PartToLua(child, varName, ""))
            table.insert(code, varName .. ".Parent = model")
            table.insert(code, "")
            
            partCount = partCount + 1
            
            -- تأخير لتجنب التجميد
            if partCount % 50 == 0 then
                wait()
            end
        end
    end
    
    table.insert(code, "print('✅ تم تحميل الماب: " .. model.Name .. "')")
    table.insert(code, "print('📊 عدد العناصر: ' .. #model:GetDescendants())")
    
    return table.concat(code, "\n"), partCount
end

-- دالة تحويل Model إلى JSON
local function ModelToJSON(model)
    local data = {
        Name = model.Name,
        ClassName = model.ClassName,
        Timestamp = os.time(),
        Objects = {}
    }
    
    for _, child in pairs(model:GetDescendants()) do
        if child:IsA("BasePart") then
            local objData = {
                Name = child.Name,
                ClassName = child.ClassName,
                Size = {child.Size.X, child.Size.Y, child.Size.Z},
                Position = {child.Position.X, child.Position.Y, child.Position.Z},
                Rotation = {child.Rotation.X, child.Rotation.Y, child.Rotation.Z},
                Color = {child.Color.R, child.Color.G, child.Color.B},
                Material = tostring(child.Material),
                Transparency = child.Transparency,
                Anchored = child.Anchored,
                CanCollide = child.CanCollide
            }
            
            if child:IsA("MeshPart") then
                objData.MeshId = child.MeshId
                objData.TextureID = child.TextureID
            end
            
            table.insert(data.Objects, objData)
        end
    end
    
    return HttpService:JSONEncode(data)
end

-- دالة حفظ الماب كملف
local function SaveMapToFile(mapModel, format)
    format = format or "lua" -- lua أو json
    
    if not mapModel or not mapModel:IsA("Model") then 
        warn("⚠️ العنصر ليس Model!")
        return false
    end
    
    print("\n📦 جاري معالجة: " .. mapModel.Name)
    
    local fileName = mapModel.Name:gsub("%s+", "_") -- استبدال المسافات
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local fullFileName = folderPath .. "/" .. fileName .. "_" .. timestamp .. "." .. format
    
    local content, partCount
    
    if format == "lua" then
        print("  📝 تحويل إلى Lua Script...")
        content, partCount = ModelToLuaScript(mapModel, 500)
    elseif format == "json" then
        print("  📝 تحويل إلى JSON...")
        content = ModelToJSON(mapModel)
        partCount = #mapModel:GetDescendants()
    end
    
    -- حفظ الملف
    local success = pcall(function()
        writefile(fullFileName, content)
    end)
    
    if success then
        print("  ✅ تم الحفظ بنجاح!")
        print("  📁 المسار: workspace/" .. fullFileName)
        print("  📊 عدد العناصر: " .. partCount)
        print("  📏 حجم الملف: " .. string.format("%.2f", #content / 1024) .. " KB")
        return true, fullFileName
    else
        warn("  ❌ فشل حفظ الملف!")
        return false
    end
end

-- دالة نسخ وحفظ كل المابات
local function SaveAllMaps(format)
    format = format or "lua"
    local savedCount = 0
    local failedCount = 0
    
    print("\n🔍 البحث عن المابات في Workspace...")
    
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj ~= Player.Character and 
           obj ~= Workspace.CurrentCamera and
           not Players:GetPlayerFromCharacter(obj) and
           obj:IsA("Model") and
           #obj:GetDescendants() > 5 then -- فقط المابات اللي فيها أكثر من 5 عناصر
            
            local success = SaveMapToFile(obj, format)
            
            if success then
                savedCount = savedCount + 1
            else
                failedCount = failedCount + 1
            end
            
            -- تأخير صغير
            if savedCount % 3 == 0 then
                wait(0.2)
            end
        end
    end
    
    return savedCount, failedCount
end

-- دالة حفظ ماب محدد بالاسم
local function SaveMapByName(mapName, format)
    format = format or "lua"
    local mapModel = Workspace:FindFirstChild(mapName)
    
    if mapModel then
        return SaveMapToFile(mapModel, format)
    else
        warn("⚠️ لم يتم العثور على: " .. mapName)
        return false
    end
end

-- ═══════════════════════════════════════════════════════════
-- التنفيذ التلقائي
-- ═══════════════════════════════════════════════════════════

print("\n🚀 بدء الحفظ التلقائي...")
print("📝 الصيغة: Lua Script (.lua)")

local savedCount, failedCount = SaveAllMaps("lua")

print("\n═══════════════════════════════════════")
print("✅ اكتمل الحفظ!")
print("═══════════════════════════════════════")
print("📊 الإحصائيات:")
print("  ✅ تم حفظ: " .. savedCount .. " ماب")
print("  ❌ فشل: " .. failedCount .. " ماب")
print("  📁 المسار: Solara/workspace/SavedMaps/")
print("═══════════════════════════════════════")

-- إشعار
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "📦 Map Saved";
    Text = "تم حفظ " .. savedCount .. " ماب في workspace!";
    Duration = 5;
})

print("\n💡 الدوال المتاحة:")
print("  • SaveMapByName('اسم_الماب', 'lua')  -- حفظ ماب محدد")
print("  • SaveMapByName('اسم_الماب', 'json') -- حفظ بصيغة JSON")
print("  • SaveAllMaps('lua')                 -- حفظ كل المابات")
print("═══════════════════════════════════════\n")

-- جعل الدوال عامة
_G.SaveMapByName = SaveMapByName
_G.SaveAllMaps = SaveAllMaps
_G.SaveMapToFile = SaveMapToFile
