function MenuManager() constructor
{
	eventBus = undefined;
	keybinds = undefined;
	inputLockFrames = 0;

	isOpen = false;
	currentMenuId = "";
	menuStack = [];

	menus = {};

	selectedIndex = 0;
	hoverIndex = -1;

	guiW = display_get_gui_width();
	guiH = display_get_gui_height();

	titleY = 64;
	itemsY = 160;
	lineH = 40;

	titleColor = c_red;
	itemColor = c_yellow;
	highlightColor = c_white;

	versionString = "v0.0.0";

	currentItemRects = [];

	soundVolume = 1.0;
	musicVolume = 1.0;

	uiHoverSoundName = "snd_ui_hover";
	uiSelectSoundName = "snd_ui_select";
	lastSelectedIndex = -1;

	isCapturingKey = false;
	captureActionName = "";

	setVersion = function(v)
	{
		versionString = string(v);
	};

	init = function(bus)
	{
		eventBus = bus;

		if(variable_global_exists("keybinds") && is_struct(global.keybinds))
		{
			keybinds = global.keybinds;
		}

		if(!is_undefined(eventBus))
		{
			eventBus.on("menu/open", method(self, self.onOpen));
			eventBus.on("menu/close", method(self, self.onClose));
			eventBus.on("menu/show", method(self, self.onShow));
			eventBus.on("menu/loading", method(self, self.onLoading));
			eventBus.on("settings/changed", method(self, self.onSettingsChanged));
		}

		self.syncVolumesFromSettings();
	};

	setKeybinds = function(kb)
	{
		if(is_struct(kb))
		{
			keybinds = kb;
		}
	};

	getKeybinds = function()
	{
		if(is_struct(keybinds))
		{
			return keybinds;
		}

		if(variable_global_exists("keybinds") && is_struct(global.keybinds))
		{
			return global.keybinds;
		}

		return undefined;
	};

	onSettingsChanged = function(payload, eventName, sender)
	{
		if(!is_struct(payload) || !variable_struct_exists(payload, "key") || !variable_struct_exists(payload, "value"))
		{
			return;
		}

		if(payload.key == "sfxVolume" && is_real(payload.value))
		{
			soundVolume = payload.value;
		}
		else if(payload.key == "musicVolume" && is_real(payload.value))
		{
			musicVolume = payload.value;
		}
	};

	syncVolumesFromSettings = function()
	{
		if(!variable_global_exists("settings") || !is_struct(global.settings))
		{
			return;
		}

		var sm = global.settings;
		if(variable_struct_exists(sm, "get") && is_callable(sm.get))
		{
			var sv = sm.get("sfxVolume");
			var mv = sm.get("musicVolume");

			if(is_real(sv)) soundVolume = sv;
			if(is_real(mv)) musicVolume = mv;
		}
	};

	onOpen = function(payload, eventName, sender)
	{
		self.open();
	};

	onClose = function(payload, eventName, sender)
	{
		self.close();
	};

	onShow = function(payload, eventName, sender)
	{
		if(is_struct(payload) && variable_struct_exists(payload, "menuId"))
		{
			self.show(payload.menuId);
		}
	};

	onLoading = function(payload, eventName, sender)
	{
		self.show("loading");
	};

	open = function()
	{
		isOpen = true;
		inputLockFrames = 1;
		lastSelectedIndex = -1;
	};

	close = function()
	{
		isOpen = false;
		menuStack = [];
		currentMenuId = "";
		selectedIndex = 0;
		hoverIndex = -1;
		currentItemRects = [];
		inputLockFrames = 0;
		lastSelectedIndex = -1;
	};

	show = function(menuId)
	{
		if(is_undefined(menuId) || menuId == "")
		{
			return false;
		}

		if(!variable_struct_exists(menus, menuId))
		{
			return false;
		}

		isOpen = true;
		currentMenuId = menuId;
		selectedIndex = 0;
		hoverIndex = -1;
		menuStack = [];
		inputLockFrames = 1;

		self.selectFirstInteractive();
		lastSelectedIndex = -1;

		return true;
	};

	push = function(menuId)
	{
		if(is_undefined(menuId) || menuId == "")
		{
			return false;
		}

		if(!variable_struct_exists(menus, menuId))
		{
			return false;
		}

		if(currentMenuId != "")
		{
			var n = array_length(menuStack);
			menuStack[n] = currentMenuId;
		}

		isOpen = true;
		currentMenuId = menuId;
		selectedIndex = 0;
		hoverIndex = -1;
		inputLockFrames = 1;

		self.selectFirstInteractive();
		lastSelectedIndex = -1;

		return true;
	};

	pop = function()
	{
		var n = array_length(menuStack);

		if(n <= 0)
		{
			return false;
		}

		var prevMenuId = menuStack[n - 1];
		array_delete(menuStack, n - 1, 1);
		currentMenuId = prevMenuId;

		selectedIndex = 0;
		hoverIndex = -1;
		inputLockFrames = 1;

		self.selectFirstInteractive();
		lastSelectedIndex = -1;

		return true;
	};

	getMenu = function()
	{
		if(currentMenuId == "")
		{
			return undefined;
		}

		if(!variable_struct_exists(menus, currentMenuId))
		{
			return undefined;
		}

		return menus[$ currentMenuId];
	};

	addMenu = function()
	{
		var menuId = (argument_count > 0) ? argument[0] : "";
		var title = (argument_count > 1) ? argument[1] : "";
		var opts = (argument_count > 2) ? argument[2] : undefined;

		if(is_undefined(menuId) || menuId == "")
		{
			return false;
		}

		var menu =
		{
			id : menuId,
			title : string(title),
			items : [],
			background : true,
			backAction : "pop"
		};

		if(is_struct(opts))
		{
			if(variable_struct_exists(opts, "background"))
			{
				menu.background = opts.background;
			}

			if(variable_struct_exists(opts, "backAction"))
			{
				menu.backAction = opts.backAction;
			}
		}

		menus[$ menuId] = menu;
		return true;
	};

	addActionItem = function()
	{
		var menuId = (argument_count > 0) ? argument[0] : "";
		var label = (argument_count > 1) ? argument[1] : "";
		var actionFn = (argument_count > 2) ? argument[2] : undefined;
		var opts = (argument_count > 3) ? argument[3] : undefined;

		if(!variable_struct_exists(menus, menuId))
		{
			return false;
		}

		if(!is_callable(actionFn))
		{
			return false;
		}

		var item =
		{
			type : "action",
			label : string(label),
			action : actionFn,
			enabled : true
		};

		if(is_struct(opts) && variable_struct_exists(opts, "enabled"))
		{
			item.enabled = opts.enabled;
		}

		var menu = menus[$ menuId];
		var items = menu.items;
		items[array_length(items)] = item;
		menu.items = items;
		menus[$ menuId] = menu;

		return true;
	};

	addSubmenuItem = function()
	{
		var menuId = (argument_count > 0) ? argument[0] : "";
		var label = (argument_count > 1) ? argument[1] : "";
		var targetMenuId = (argument_count > 2) ? argument[2] : "";
		var opts = (argument_count > 3) ? argument[3] : undefined;

		if(!variable_struct_exists(menus, menuId))
		{
			return false;
		}

		if(is_undefined(targetMenuId) || targetMenuId == "")
		{
			return false;
		}

		var token =
		{
			pushFn : method(self, self.push),
			targetMenuId : targetMenuId,

			run : function()
			{
				self.pushFn(self.targetMenuId);
			}
		};

		return self.addActionItem(menuId, label, method(token, token.run), opts);
	};

	addRangeItem = function()
	{
		var menuId = (argument_count > 0) ? argument[0] : "";
		var label = (argument_count > 1) ? argument[1] : "";
		var getFn = (argument_count > 2) ? argument[2] : undefined;
		var setFn = (argument_count > 3) ? argument[3] : undefined;
		var opts = (argument_count > 4) ? argument[4] : undefined;

		if(!variable_struct_exists(menus, menuId))
		{
			return false;
		}

		if(!is_callable(getFn) || !is_callable(setFn))
		{
			return false;
		}

		var item =
		{
			type : "range",
			label : string(label),
			get : getFn,
			set : setFn,
			step : 0.05,
			min : 0.0,
			max : 1.0,
			enabled : true
		};

		if(is_struct(opts))
		{
			if(variable_struct_exists(opts, "step"))
			{
				item.step = opts.step;
			}

			if(variable_struct_exists(opts, "min"))
			{
				item.min = opts.min;
			}

			if(variable_struct_exists(opts, "max"))
			{
				item.max = opts.max;
			}

			if(variable_struct_exists(opts, "enabled"))
			{
				item.enabled = opts.enabled;
			}
		}

		var menu = menus[$ menuId];
		var items = menu.items;
		items[array_length(items)] = item;
		menu.items = items;
		menus[$ menuId] = menu;

		return true;
	};


	addLabelItem = function()
	{
		var menuId = (argument_count > 0) ? argument[0] : "";
		var label = (argument_count > 1) ? argument[1] : "";

		if(!variable_struct_exists(menus, menuId))
		{
			return false;
		}

		var item =
		{
			type : "label",
			label : string(label)
		};

		var menu = menus[$ menuId];
		var items = menu.items;
		items[array_length(items)] = item;
		menu.items = items;
		menus[$ menuId] = menu;

		return true;
	};

	addKeybindItem = function()
	{
		var menuId = (argument_count > 0) ? argument[0] : "";
		var label = (argument_count > 1) ? argument[1] : "";
		var actionName = (argument_count > 2) ? argument[2] : "";
		var opts = (argument_count > 3) ? argument[3] : undefined;

		if(!variable_struct_exists(menus, menuId))
		{
			return false;
		}

		if(is_undefined(actionName) || actionName == "")
		{
			return false;
		}

		var item =
		{
			type : "keybind",
			label : string(label),
			actionName : string(actionName),
			enabled : true
		};

		if(is_struct(opts) && variable_struct_exists(opts, "enabled"))
		{
			item.enabled = opts.enabled;
		}

		var menu = menus[$ menuId];
		var items = menu.items;
		items[array_length(items)] = item;
		menu.items = items;
		menus[$ menuId] = menu;

		return true;
	};


	clamp01 = function(v)
	{
		if(v < 0) { return 0; }
		if(v > 1) { return 1; }
		return v;
	};

	getSoundVolume = function()
	{
		return soundVolume;
	};

	setSoundVolume = function(v)
	{
		soundVolume = clamp01(v);

		if(!is_undefined(eventBus))
		{
			eventBus.emit("settings/set", { key : "sfxVolume", value : soundVolume }, noone);
			eventBus.emit("settings/apply", { }, noone);
		}
	};

	getMusicVolume = function()
	{
		return musicVolume;
	};

	setMusicVolume = function(v)
	{
		musicVolume = clamp01(v);

		if(!is_undefined(eventBus))
		{
			eventBus.emit("settings/set", { key : "musicVolume", value : musicVolume }, noone);
			eventBus.emit("settings/apply", { }, noone);
		}
	};


	setUiSounds = function(hoverName, selectName)
	{
		if(!is_undefined(hoverName))
		{
			uiHoverSoundName = string(hoverName);
		}

		if(!is_undefined(selectName))
		{
			uiSelectSoundName = string(selectName);
		}
	};

	resolveSoundId = function(soundName)
	{
		if(is_undefined(soundName) || soundName == "")
		{
			return noone;
		}

			var assetId = asset_get_index(soundName);
			if(assetId < 0)
			{
				return noone;
			}

			return assetId;
	};

	emitUiSound = function(soundName)
	{
		if(is_undefined(eventBus))
		{
			return;
		}

		var sid = resolveSoundId(soundName);
		if(sid == noone)
		{
			return;
		}

		eventBus.emit("audio/playUi", { sound : sid }, noone);
	};

	isItemInteractive = function(item)
	{
		if(is_undefined(item))
		{
			return false;
		}

		if(variable_struct_exists(item, "enabled") && !item.enabled)
		{
			return false;
		}

		if(variable_struct_exists(item, "type") && item.type == "label")
		{
			return false;
		}

		return true;
	};

	playHoverSound = function()
	{
		emitUiSound(uiHoverSoundName);
	};

	playSelectSound = function()
	{
		emitUiSound(uiSelectSoundName);
	};

	getKeyForAction = function(actionName, fallbackKey)
	{
		var vk = fallbackKey;
		var kb = getKeybinds();

		if(is_struct(kb) && variable_struct_exists(kb, "getKey") && is_callable(kb.getKey))
		{
			var v = kb.getKey(actionName);
			if(is_real(v))
			{
				var loaded = floor(v);
				if(loaded > 0)
				{
					vk = loaded;
				}
			}
		}

		return vk;
	};

	fallbackKeyForAction = function(actionName)
	{
		switch(string(actionName))
		{
			case "pause": return vk_escape;
			case "recenter": return vk_space;
			case "toggleFullscreen": return vk_f10;
		}

		return 0;
	};

	keyNameForCode = function(vk)
	{
		switch(vk)
		{
			case vk_escape: return "Esc";
			case vk_space: return "Space";
			case vk_enter: return "Enter";
			case vk_tab: return "Tab";
			case vk_backspace: return "Backspace";
			case vk_up: return "Up";
			case vk_down: return "Down";
			case vk_left: return "Left";
			case vk_right: return "Right";
			case vk_f1: return "F1";
			case vk_f2: return "F2";
			case vk_f3: return "F3";
			case vk_f4: return "F4";
			case vk_f5: return "F5";
			case vk_f6: return "F6";
			case vk_f7: return "F7";
			case vk_f8: return "F8";
			case vk_f9: return "F9";
			case vk_f10: return "F10";
			case vk_f11: return "F11";
			case vk_f12: return "F12";
		}

		if(is_real(vk))
		{
			var cA = ord("A");
			var cZ = ord("Z");
			var c0 = ord("0");
			var c9 = ord("9");

			if(vk >= cA && vk <= cZ)
			{
				return chr(vk);
			}

			if(vk >= c0 && vk <= c9)
			{
				return chr(vk);
			}
		}

		return "Key " + string(vk);
	};

	beginKeyCapture = function(actionName)
	{
		isCapturingKey = true;
		captureActionName = string(actionName);
		keyboard_lastkey = 0;
		inputLockFrames = 1;
	};

	endKeyCapture = function()
	{
		isCapturingKey = false;
		captureActionName = "";
		keyboard_lastkey = 0;
		inputLockFrames = 1;
	};

	updateKeyCapture = function()
	{
		var k = keyboard_lastkey;
		if(k == 0)
		{
			return;
		}

		keyboard_lastkey = 0;

		if(k == vk_escape)
		{
			endKeyCapture();
			return;
		}

		var kb = getKeybinds();
		if(is_struct(kb) && variable_struct_exists(kb, "setKey") && is_callable(kb.setKey))
		{
			kb.setKey(captureActionName, k);
			if(variable_struct_exists(kb, "save") && is_callable(kb.save))
			{
				kb.save();
			}
		}

		endKeyCapture();
	};


	getItemCount = function(menu)
	{
		if(is_undefined(menu))
		{
			return 0;
		}

		return array_length(menu.items);
	};


	selectFirstInteractive = function()
	{
		var menu = self.getMenu();

		if(is_undefined(menu))
		{
			selectedIndex = 0;
			return;
		}

		var count = array_length(menu.items);

		for(var i = 0; i < count; i += 1)
		{
			if(self.isItemInteractive(menu.items[i]))
			{
				selectedIndex = i;
				return;
			}
		}

		selectedIndex = 0;
	};


	moveSelection = function(dir)
	{
		var menu = self.getMenu();

		if(is_undefined(menu))
		{
			return;
		}

		var count = array_length(menu.items);

		if(count <= 0)
		{
			return;
		}

		var next = selectedIndex;

		for(var attempts = 0; attempts < count; attempts += 1)
		{
			next += dir;

			if(next < 0)
			{
				next = count - 1;
			}
			else if(next >= count)
			{
				next = 0;
			}

			if(self.isItemInteractive(menu.items[next]))
			{
				selectedIndex = next;
				return;
			}
		}

		selectedIndex = clamp(selectedIndex, 0, count - 1);
	};

	activateSelection = function()
	{
		var menu = self.getMenu();

		if(is_undefined(menu))
		{
			return;
		}

		var count = array_length(menu.items);

		if(count <= 0)
		{
			return;
		}

		if(selectedIndex < 0 || selectedIndex >= count)
		{
			return;
		}

		var item = menu.items[selectedIndex];

		if(variable_struct_exists(item, "enabled") && !item.enabled)
		{
			return;
		}

		if(item.type == "action")
		{
			self.playSelectSound();
			item.action();
		}
		else if(item.type == "keybind")
		{
			self.playSelectSound();
			self.beginKeyCapture(item.actionName);
		}
	};

	adjustSelection = function(dir)
	{
		var menu = self.getMenu();

		if(is_undefined(menu))
		{
			return;
		}

		var count = array_length(menu.items);

		if(selectedIndex < 0 || selectedIndex >= count)
		{
			return;
		}

		var item = menu.items[selectedIndex];

		if(item.type != "range")
		{
			return;
		}

		var v = item.get();
		var next = v + (item.step * dir);

		if(next < item.min) { next = item.min; }
		if(next > item.max) { next = item.max; }

		item.set(next);
	};

	actionBack = function()
	{
		self.back();
	};

	back = function()
	{
		var menu = self.getMenu();

		if(is_undefined(menu))
		{
			close();
			return;
		}

		if(menu.backAction == "unpause")
		{
			actionReturnToGame();
			return;
		}

		if(menu.backAction == "close")
		{
			close();
			return;
		}

		if(menu.backAction == "main")
		{
			show("main");
			return;
		}

		pop();
	};

	updateHover = function()
	{
		hoverIndex = -1;

		var count = array_length(currentItemRects);

		if(count <= 0)
		{
			return;
		}

		var mx = device_mouse_x_to_gui(0);
		var my = device_mouse_y_to_gui(0);

		for(var i = 0; i < count; i += 1)
		{
			var r = currentItemRects[i];

			if(mx >= r.x1 && mx <= r.x2 && my >= r.y1 && my <= r.y2)
			{
				var menu = self.getMenu();
				if(!is_undefined(menu) && i >= 0 && i < array_length(menu.items))
				{
					var item = menu.items[i];
					if(self.isItemInteractive(item))
					{
						hoverIndex = i;
						selectedIndex = i;
					}
				}

				return;
			}
		}
	};

	update = function()
	{
		if(!isOpen)
		{
			return;
		}

		guiW = display_get_gui_width();
		guiH = display_get_gui_height();

		var menu = self.getMenu();

		if(is_undefined(menu))
		{
			return;
		}
		
		if(inputLockFrames > 0)
		{
			inputLockFrames -= 1;
			self.updateHover();
			return;
		}

		if(menu.id == "intro")
		{
			if(keyboard_check_pressed(vk_anykey) || mouse_check_button_pressed(mb_left))
			{
				self.show("main");
			}

			return;
		}

		if(isCapturingKey)
		{
			self.updateKeyCapture();
			return;
		}

		self.updateHover();

		if(keyboard_check_pressed(vk_up))
		{
			self.moveSelection(-1);
		}

		if(keyboard_check_pressed(vk_down))
		{
			self.moveSelection(1);
		}

		if(keyboard_check_pressed(vk_left))
		{
			self.adjustSelection(-1);
		}

		if(keyboard_check_pressed(vk_right))
		{
			self.adjustSelection(1);
		}


		var count = array_length(menu.items);

		if(count > 0 && selectedIndex >= 0 && selectedIndex < count && selectedIndex != lastSelectedIndex)
		{
			if(lastSelectedIndex != -1)
			{
				var item = menu.items[selectedIndex];
				if(self.isItemInteractive(item))
				{
					self.playHoverSound();
				}
			}

			lastSelectedIndex = selectedIndex;
		}

		if(keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space))
		{
			self.activateSelection();
		}

		if(keyboard_check_pressed(vk_escape))
		{
			if(currentMenuId == "main")
			{
				self.show("confirmExit");
				return;
			}

			self.back();
		}

		if(mouse_check_button_pressed(mb_left))
		{
			if(hoverIndex != -1)
			{
				self.activateSelection();
			}
		}
	};

	drawGui = function()
	{
		if(!isOpen)
		{
			return;
		}

		guiW = display_get_gui_width();
		guiH = display_get_gui_height();

		var menu = self.getMenu();
		if(is_undefined(menu))
		{
			return;
		}

		draw_set_alpha(1);
		gpu_set_blendmode(bm_normal);
		draw_set_font(-1);

		// background
		if(menu.background)
		{
			var a = 1;

			if(menu.id == "pause")
			{
				a = 0.6;
			}

			draw_set_alpha(a);
			draw_set_color(c_black);
			draw_rectangle(0, 0, guiW, guiH, false);
			draw_set_alpha(1);
		}

		// title
		draw_set_halign(fa_center);
		draw_set_valign(fa_top);

		draw_set_color(titleColor);
		draw_text(guiW * 0.5, titleY, menu.title);

		// special menus
		if(menu.id == "intro")
		{
			draw_set_color(itemColor);
			draw_text(guiW * 0.5, itemsY, "Press any key to begin");
			draw_text(guiW * 0.5, itemsY + lineH, versionString);

			currentItemRects = [];
			return;
		}

		if(menu.id == "loading")
		{
			draw_set_color(itemColor);
			draw_text(guiW * 0.5, itemsY, "Loading...");

			currentItemRects = [];
			return;
		}

		// items
		var count = array_length(menu.items);
		currentItemRects = [];

		for(var i = 0; i < count; i += 1)
		{
			var item = menu.items[i];

			var text = item.label;

			if(item.type == "range")
			{
				var v = item.get();
				var pct = string_format(v * 100, 0, 0);
				text = item.label + ": " + pct + "%";
			}
			else if(item.type == "keybind")
			{
				if(isCapturingKey && item.actionName == captureActionName)
				{
					text = item.label + ": [Press key]";
				}
				else
				{
					var fallback = self.fallbackKeyForAction(item.actionName);
					var vk = self.getKeyForAction(item.actionName, fallback);
					text = item.label + ": " + self.keyNameForCode(vk);
				}
			}

			var _y = itemsY + (i * lineH);
			var isSelected = (i == selectedIndex);

			if(variable_struct_exists(item, "enabled") && !item.enabled)
			{
				draw_set_color(c_gray);
			}
			else
			{
				draw_set_color(isSelected ? highlightColor : itemColor);
			}

			draw_text(guiW * 0.5, _y, text);

			var tw = string_width(text);
			var th = string_height(text);

			currentItemRects[i] =
			{
				x1 : (guiW * 0.5) - (tw * 0.5) - 16,
				y1 : _y - 4,
				x2 : (guiW * 0.5) + (tw * 0.5) + 16,
				y2 : _y + th + 4
			};
		}

		draw_set_alpha(1);
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
	};

	buildDefaultMenus = function()
	{
		self.addMenu("intro", "TITLE", { background : true, backAction : "close" });
		self.addMenu("main", "MAIN MENU", { background : true, backAction : "close" });
		self.addMenu("options", "OPTIONS", { background : true, backAction : "pop" });
		self.addMenu("volume", "VOLUME", { background : true, backAction : "pop" });
		self.addMenu("keybinds", "KEYBINDS", { background : true, backAction : "pop" });
		self.addMenu("pause", "PAUSED", { background : false, backAction : "unpause" });
		self.addMenu("loading", "LOADING", { background : true, backAction : "close" });
		self.addMenu("confirmExit", "EXIT GAME?", { background : true, backAction : "main" });


		self.addActionItem("main", "Play", method(self, self.actionPlay));
		self.addSubmenuItem("main", "Options", "options");
		self.addActionItem("main", "Exit Game", method(self, self.actionExitPrompt));


		self.addSubmenuItem("options", "Volume", "volume");
		self.addSubmenuItem("options", "Keybinds", "keybinds");

		self.addRangeItem("volume", "Sound", method(self, self.getSoundVolume), method(self, self.setSoundVolume), { step : 0.05 });
		self.addRangeItem("volume", "Music", method(self, self.getMusicVolume), method(self, self.setMusicVolume), { step : 0.05 });

		self.addKeybindItem("keybinds", "Pause", "pause");
		self.addKeybindItem("keybinds", "Recenter", "recenter");
		self.addKeybindItem("keybinds", "Toggle Fullscreen", "toggleFullscreen");
		self.addLabelItem("keybinds", "(Press Enter to rebind)");

		self.addSubmenuItem("pause", "Options", "options");
		self.addActionItem("pause", "Main Menu", method(self, self.actionMainMenu));
		self.addActionItem("pause", "Return to Game", method(self, self.actionReturnToGame));
		
		self.addActionItem("options", "Back", method(self, self.actionBack));
		self.addActionItem("volume", "Back", method(self, self.actionBack));
		self.addActionItem("keybinds", "Back", method(self, self.actionBack));

		self.addActionItem("confirmExit", "Yes", method(self, self.actionExit));
		self.addActionItem("confirmExit", "No", method(self, self.actionExitCancel));

	};

	actionPlay = function()
	{
		if(!is_undefined(eventBus))
		{
			// TODO: replace "rm_game" with your actual gameplay room asset name
			eventBus.emit("game/start", { sceneId : "rm_game" }, noone);
		}

		self.show("loading");
	};

	actionExitPrompt = function()
	{
		self.show("confirmExit");
	};

	actionExitCancel = function()
	{
		self.show("main");
	};

	actionExit = function()
	{
		game_end();
	};

	actionKeybindsStub = function()
	{
		show_debug_message("[Menu] keybinds stub");
	};

	actionMainMenu = function()
	{
		if(!is_undefined(eventBus))
		{
			eventBus.emit("game/mainMenu", { }, noone);
		}

		self.show("main");
	};

	actionReturnToGame = function()
	{
		if(!is_undefined(eventBus))
		{
			eventBus.emit("game/unpause", { }, noone);
		}

		self.close();
	};

	self.buildDefaultMenus();
}
