local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemService = {}

function ItemService.getItemsByCategory(category)
    local ItemsFolder = ReplicatedStorage:FindFirstChild("Items")
    if not ItemsFolder then return {} end
    
    local categoryFolder = ItemsFolder:FindFirstChild(category)
    if not categoryFolder then return {} end
    
    local items = {}
    for _, itemModel in ipairs(categoryFolder:GetChildren()) do
        if itemModel:IsA("Model") then
            table.insert(items, {
                id = itemModel.Name,
                name = itemModel.Name,
                category = category,
                model = itemModel,
                value = itemModel:FindFirstChild("Value") and itemModel.Value.Value or 0,
            })
        end
    end
    
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