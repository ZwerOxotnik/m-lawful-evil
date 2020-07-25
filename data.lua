data:extend{
    {
        type = "sprite",
        name = "lawful-button-sprite",
        filename = "__m-lawful-evil__/graphics/gavel.png",
        width = 512,
        height = 512,
        flags = {
            "icon"
        }
    }
}

local default_gui = data.raw["gui-style"].default
if default_gui["large_caption_label"] == nil then
    default_gui["large_caption_label"] = {
        type = "label_style",
        parent = "caption_label",
        font = "default-large-bold"
    }
end