local deepcopy = util.table.deepcopy
local styles = data.raw["gui-style"].default


data:extend{
    {
        type = "sprite",
        name = "lawful-button-sprite",
        filename = "__m-lawful-evil__/graphics/gavel.png",
        width = 512, height = 512,
        flags = {"icon"}
    }
}

if styles["large_caption_label"] == nil then
    styles["large_caption_label"] = {
        type = "label_style",
        parent = "caption_label",
        font = "default-large-bold"
    }
end

local slot_button = styles.slot_button
styles.lawful_evil_button = {
  type = "button_style",
	parent = "slot_button",
	tooltip = "mod-name.m-lawful-evil",
	default_graphical_set = deepcopy(slot_button.default_graphical_set),
	hovered_graphical_set = deepcopy(slot_button.hovered_graphical_set),
	clicked_graphical_set = deepcopy(slot_button.clicked_graphical_set)
}
local lawful_evil_button = styles.lawful_evil_button
lawful_evil_button.default_graphical_set.glow = {
	top_outer_border_shift = 4,
	bottom_outer_border_shift = -4,
	left_outer_border_shift = 4,
	right_outer_border_shift = -4,
	draw_type = "outer",
	filename = "__m-lawful-evil__/graphics/gavel.png",
	flags = {"gui-icon"},
	size = 512,
	scale = 1
}
lawful_evil_button.hovered_graphical_set.glow.center = {
	filename = "__m-lawful-evil__/graphics/gavel.png",
	flags = {"gui-icon"},
	size = 512,
	scale = 1
}
lawful_evil_button.clicked_graphical_set.glow = {
	top_outer_border_shift = 2,
	bottom_outer_border_shift = -2,
	left_outer_border_shift = 2,
	right_outer_border_shift = -2,
	draw_type = "outer",
	filename = "__m-lawful-evil__/graphics/gavel.png",
	flags = {"gui-icon"},
	size = 512,
	scale = 1
}
