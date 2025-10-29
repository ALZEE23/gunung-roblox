local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemService = {}

function ItemService.getItemsByCategory(category)
    local ItemsFolder = ReplicatedStorage:FindFirstChild("Items")
    if not ItemsFolder then 
        print("[ItemManager] Items folder not found!")
        return {} 
    end
    
    local categoryFolder = ItemsFolder:FindFirstChild(category)
    if not categoryFolder then 
        print("[ItemManager] Category folder not found:", category)
        return {} 
    end
    
    print("[ItemManager] Scanning category:", category)
    
    local items = {}
    for _, itemModel in ipairs(categoryFolder:GetChildren()) do
        print("[ItemManager] Found child:", itemModel.Name, "Type:", itemModel.ClassName)
        
        -- 🔧 FIX: Check for MeshPart instead of Model
        if itemModel:IsA("MeshPart") or itemModel:IsA("Part") or itemModel:IsA("Model") then
            local itemData = {
                id = itemModel.Name,
                name = itemModel.Name,
                category = category,
                model = itemModel,
                value = itemModel:FindFirstChild("Value") and itemModel.Value.Value or 0,
            }
            
            print("[ItemManager] Added item:", itemData.id, "from category:", category)
            table.insert(items, itemData)
        end
    end
    
    print("[ItemManager] Total items in", category, ":", #items)
    return items
end

function ItemService.getAllItems()
    local allItems = {}
    local categories = {"Organic", "Anorganic", "Campuran"}
    
    for _, category in ipairs(categories) do
        local categoryItems = ItemService.getItemsByCategory(category)
        for _, item in ipairs(categoryItems) do
            allItems[item.id] = item
        end
    end
    
    return allItems
end

function ItemService.getItemData(itemId)
    local ItemsFolder = ReplicatedStorage:FindFirstChild("Items")
    if not ItemsFolder then return nil end
    
    -- Search in all categories
    local categories = {"Organic", "Anorganic", "Campuran"}
    for _, categoryName in ipairs(categories) do
        local categoryFolder = ItemsFolder:FindFirstChild(categoryName)
        if categoryFolder then
            local itemModel = categoryFolder:FindFirstChild(itemId)
            if itemModel then
                return {
                    id = itemModel.Name,
                    name = itemModel.Name,
                    category = categoryName,
                    model = itemModel,
                    value = itemModel:FindFirstChild("Value") and itemModel.Value.Value or 0,
                    description = itemModel:FindFirstChild("Description") and itemModel.Description.Value or "",
                }
            end
        end
    end
    
    return nil
end

return ItemService