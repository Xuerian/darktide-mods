local mod = get_mod("BuffHUDImprovements")
local BuffTemplates = require("scripts/settings/buff/buff_templates")
local MasterItems = require("scripts/backend/master_items")

local BuffSettingsWindow = class("ModBuffSettingsWindow")

function BuffSettingsWindow:init()
	self._is_open = false
	self._items = {}
	self._icon_cache = {}
	self._buffs = {}
	self._num_buffs = 0
	self._page = 1
	self._search = ""
end

function BuffSettingsWindow:open()
	local input_manager = Managers.input
	local name = self.__class_name

	if not input_manager:cursor_active() then
		input_manager:push_cursor(name)
	end

	self._items = MasterItems.get_cached()

	if self._num_buffs == 0 then
		for _, buff_template in pairs(BuffTemplates) do
			local hud_icon = self:_get_icon(buff_template)
			if hud_icon then
				self._num_buffs = self._num_buffs + 1
				self._buffs[buff_template.name] = buff_template
			end
		end
	end

	self._is_open = true
	Imgui.open_imgui()
end

function BuffSettingsWindow:close()
	local input_manager = Managers.input
	local name = self.__class_name

	if input_manager:cursor_active() then
		input_manager:pop_cursor(name)
	end

	self._is_open = false
	Imgui.close_imgui()
end

function BuffSettingsWindow:_get_icon(buff_template)
	if buff_template.hide_icon_in_hud then
		return nil
	end

	if buff_template.hud_icon then
		return buff_template.hud_icon
	end

	local cached_icon = self._icon_cache[buff_template.name]
	if cached_icon then
		return cached_icon
	end

	for _, item in pairs(self._items) do
		if item.trait == buff_template.name then
			if item.icon and item.icon ~= "" then
				self._icon_cache[buff_template.name] = item.icon
				return item.icon
			end
		end
	end

	return nil
end

function BuffSettingsWindow:checkbox(_label, key)
	-- make the label unique else imgui gets confused
	-- big space to hide the unwanted bit off screen
	local label = _label .. "                                    " .. key
	local val = mod:get(key)
	local new_val = Imgui.checkbox(label, val)
	if val ~= new_val then
		mod:set(key, new_val)
	end
end

function BuffSettingsWindow:update()
	if self._is_open then
		-- Imgui.set_next_window_size(400, 600)
		Imgui.begin_window("Buff Settings", "always_auto_resize")

		local _search = Imgui.input_text("Search", self._search)
		if _search ~= self._search then
			self._search = _search
			self._page = 1
		end

		local min = self._page
		local max = self._page + 8

		local i = 1
		for _, buff_template in pairs(self._buffs) do
			if self._search == "" or #self._search > 0 and string.find(buff_template.name, self._search) then
				if i >= min and i <= max then
					local hud_icon = self:_get_icon(buff_template)
					if hud_icon then
						Imgui.columns(2)
						Imgui.set_column_width(80, 0)
						Imgui.image(hud_icon, 64, 64)
						if Imgui.is_item_hovered() then
							Imgui.begin_tool_tip()
							Imgui.text(buff_template.name)
							Imgui.end_tool_tip()
						end
						Imgui.next_column()
						self:checkbox("Priority", buff_template.name .. "_priority")
						self:checkbox("Hidden", buff_template.name .. "_hidden")
						Imgui.next_column()
					end
				end
				i = i + 1
			end
		end
		Imgui.columns(1)
		self._page = Imgui.slider_int("Page", self._page, 1, math.min(i - 9, self._num_buffs - 8))
		Imgui.end_window()
	end
end

return BuffSettingsWindow
