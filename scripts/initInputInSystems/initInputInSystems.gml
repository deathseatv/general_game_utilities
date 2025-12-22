function initInputInSystems(input, events, keybinds)
{
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

	if(argument_count < 3 || !is_struct(keybinds))
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

	var makePressedMapper = function(actionName, fallbackKey)
	{
		var token =
		{
			actionName : actionName,
			fallbackKey : fallbackKey,
			keybinds : keybinds,

			run : function(raw)
			{
				var vk = self.fallbackKey;

				if(is_struct(self.keybinds)
					&& variable_struct_exists(self.keybinds, "getKey")
					&& is_callable(self.keybinds.getKey))
				{
					var v = self.keybinds.getKey(self.actionName);
					if(is_real(v))
					{
						vk = floor(v);
					}
				}

				return keyboard_check_pressed(vk) ? 1 : 0;
			}
		};

		return method(token, token.run);
	};

	input.addSignal("pause", makePressedMapper("pause", vk_escape));
	input.addSignal("recenter", makePressedMapper("recenter", vk_space));
	input.addSignal("toggleFullscreen", makePressedMapper("toggleFullscreen", vk_f10));

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
