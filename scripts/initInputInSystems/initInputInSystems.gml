function initInputInSystems(input, events)
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

	var pauseMapper = undefined;
	var recenterMapper = undefined;

	var hasKeyPressed = variable_struct_exists(input, "keyPressed") && is_callable(input.keyPressed);

	if(hasKeyPressed)
	{
		pauseMapper = input.keyPressed(vk_escape);
		recenterMapper = input.keyPressed(vk_space);
	}

	if(!is_callable(pauseMapper) || !is_callable(recenterMapper))
	{
		var pauseToken =
		{
			run : function(raw)
			{
				return keyboard_check_pressed(vk_escape) ? 1 : 0;
			}
		};

		var recenterToken =
		{
			run : function(raw)
			{
				return keyboard_check_pressed(vk_space) ? 1 : 0;
			}
		};

		pauseMapper = method(pauseToken, pauseToken.run);
		recenterMapper = method(recenterToken, recenterToken.run);
	}

	input.addSignal("pause", pauseMapper);
	input.addSignal("recenter", recenterMapper);

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
	}

	return true;
}
