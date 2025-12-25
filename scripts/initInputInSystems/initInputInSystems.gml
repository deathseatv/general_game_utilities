function initInputInSystems()
{
	var input = (argument_count >= 1) ? argument[0] : undefined;
	var events = (argument_count >= 2) ? argument[1] : undefined;
	var keybinds = (argument_count >= 3) ? argument[2] : undefined;

	if(argument_count < 1 || !is_struct(input))
	{
		if(variable_global_exists("input") && is_struct(global.input))
		{
			input = global.input;
		}
		else
		{
			return false;
		}
	}

	if(!variable_struct_exists(input, "addSignal") || !is_callable(input.addSignal))
	{
		return false;
	}

	var isValidBus = function(bus)
	{
		return is_struct(bus)
			&& variable_struct_exists(bus, "emit")
			&& is_callable(bus.emit);
	};

	if(argument_count < 2 || !isValidBus(events))
	{
		if(variable_global_exists("events") && isValidBus(global.events))
		{
			events = global.events;
		}
		else if(variable_global_exists("eventBus") && isValidBus(global.eventBus))
		{
			events = global.eventBus;
		}
		else
		{
			events = undefined;
		}
	}

	if(argument_count < 3)
	{
		keybinds = undefined;
	}
	else if(!is_struct(keybinds))
	{
		if(variable_global_exists("keybinds") && is_struct(global.keybinds))
		{
			keybinds = global.keybinds;
		}
		else
		{
			keybinds = undefined;
		}
	}

	var makePressedMapper = function(actionName, fallbackKey, inputRef, keybindsRef)
	{
		var token =
		{
			actionName : actionName,
			fallbackKey : fallbackKey,
			lastKey : -1,
			keybinds : keybindsRef,
			watchFn : undefined
		};

		if(is_struct(inputRef)
			&& variable_struct_exists(inputRef, "watchKey")
			&& is_callable(inputRef.watchKey))
		{
			token.watchFn = method(inputRef, inputRef.watchKey);
		}

		var mapper = function(raw)
		{
			var vkKey = self.fallbackKey;

			if(is_struct(self.keybinds)
				&& variable_struct_exists(self.keybinds, "getKey")
				&& is_callable(self.keybinds.getKey))
			{
				var v = self.keybinds.getKey(self.actionName);
				if(is_real(v))
				{
					var loaded = floor(v);
					if(loaded > 0)
					{
						vkKey = loaded;
					}
				}
			}

			if(!is_undefined(self.watchFn)
				&& vkKey != self.lastKey)
			{
				self.watchFn(vkKey);
				self.lastKey = vkKey;
			}

			if(is_struct(raw)
				&& variable_struct_exists(raw, "keyPressed")
				&& is_array(raw.keyPressed)
				&& is_real(vkKey))
			{
				var arr = raw.keyPressed;
				var len = array_length(arr);
				var idx = floor(vkKey);

				if(idx >= 0 && idx < len)
				{
					var pressed = arr[idx];
					if(!is_undefined(pressed))
					{
						return pressed ? 1 : 0;
					}
				}
			}

			return keyboard_check_pressed(vkKey) ? 1 : 0;
		};

		if(!is_undefined(token.watchFn))
		{
			token.watchFn(fallbackKey);

			if(is_struct(keybindsRef)
				&& variable_struct_exists(keybindsRef, "getKey")
				&& is_callable(keybindsRef.getKey))
			{
				var initVal = keybindsRef.getKey(actionName);
				if(is_real(initVal))
				{
					var initKey = floor(initVal);
					if(initKey > 0 && initKey != fallbackKey)
					{
						token.watchFn(initKey);
					}
				}
			}
		}

		return method(token, mapper);
	};


	input.addSignal("pause", makePressedMapper("pause", vk_escape, input, keybinds));
	input.addSignal("recenter", makePressedMapper("recenter", vk_space, input, keybinds));
	input.addSignal("toggleFullscreen", makePressedMapper("toggleFullscreen", vk_f10, input, keybinds));

	if(!isValidBus(events))
	{
		return true;
	}

	if(variable_struct_exists(input, "setEventBus") && is_callable(input.setEventBus))
	{
		input.setEventBus(events);
	}
	else
	{
		input.eventBus = events;
	}

	if(variable_struct_exists(input, "bindSignal") && is_callable(input.bindSignal))
	{
		input.bindSignal("pause", "game/pause", "", "");
		input.bindSignal("recenter", "camera/recenter", "", "");
		input.bindSignal("toggleFullscreen", "video/toggleFullscreen", "", "");
	}

	return true;
}