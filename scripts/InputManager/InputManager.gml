function InputManager() constructor
{
	raw =
	{
		keyDown : [],
		keyPressed : [],
		keyReleased : [],
		mouseDown : [],
		mousePressed : [],
		mouseReleased : []
	};

	consumedSignals = {};
	consumeAllSignals = false;

	signalDefs = {};
	signals = {};
	bindings = {};
	signalNames = [];
	signalNamesDirty = true;

	eventBus = undefined;

	watchedKeys = [];
	watchedKeysSet = {};

	watchedMouseButtons = [];
	watchedMouseButtonsSet = {};

	setEventBus = function(bus)
	{
		eventBus = bus;
	};

	rebuildSignalNames = function()
	{
		signalNames = variable_struct_get_names(signalDefs);
		signalNamesDirty = false;
	};

	watchKey = function(key)
	{
		var keyName = string(key);

		if(variable_struct_exists(watchedKeysSet, keyName))
		{
			return;
		}

		watchedKeysSet[$ keyName] = true;
		array_push(watchedKeys, key);
	};

	watchMouseButton = function(button)
	{
		var btnName = string(button);

		if(variable_struct_exists(watchedMouseButtonsSet, btnName))
		{
			return;
		}

		watchedMouseButtonsSet[$ btnName] = true;
		array_push(watchedMouseButtons, button);
	};

	clearConsumed = function()
	{
		consumedSignals = {};
		consumeAllSignals = false;
	};

	consume = function(signalName)
	{
		if(is_undefined(signalName) || signalName == "")
		{
			return;
		}

		consumedSignals[$ signalName] = true;
	};

	isConsumed = function(signalName)
	{
		if(consumeAllSignals)
		{
			return true;
		}

		if(is_undefined(signalName) || signalName == "")
		{
			return false;
		}

		return variable_struct_exists(consumedSignals, signalName);
	};

	consumeAll = function()
	{
		consumeAllSignals = true;
	};

	keyDown = function(key)
	{
		watchKey(key);

		var token =
		{
			key : key,

			map : function(r)
			{
				return r.keyDown[self.key] ? 1 : 0;
			}
		};

		return method(token, token.map);
	};

	keyPressed = function(key)
	{
		watchKey(key);

		var token =
		{
			key : key,

			map : function(r)
			{
				return r.keyPressed[self.key] ? 1 : 0;
			}
		};

		return method(token, token.map);
	};

	keyReleased = function(key)
	{
		watchKey(key);

		var token =
		{
			key : key,

			map : function(r)
			{
				return r.keyReleased[self.key] ? 1 : 0;
			}
		};

		return method(token, token.map);
	};

	mouseDown = function(button)
	{
		watchMouseButton(button);

		var token =
		{
			button : button,

			map : function(r)
			{
				return r.mouseDown[self.button] ? 1 : 0;
			}
		};

		return method(token, token.map);
	};

	mousePressed = function(button)
	{
		watchMouseButton(button);

		var token =
		{
			button : button,

			map : function(r)
			{
				return r.mousePressed[self.button] ? 1 : 0;
			}
		};

		return method(token, token.map);
	};

	mouseReleased = function(button)
	{
		watchMouseButton(button);

		var token =
		{
			button : button,

			map : function(r)
			{
				return r.mouseReleased[self.button] ? 1 : 0;
			}
		};

		return method(token, token.map);
	};

	addSignal = function(signalName, mapperFn)
	{
		if(is_undefined(signalName) || signalName == "")
		{
			return;
		}

		if(!is_callable(mapperFn))
		{
			return;
		}

		signalDefs[$ signalName] = mapperFn;
		signals[$ signalName] =
		{
			value : 0,
			prevValue : 0,
			pressed : false,
			released : false
		};

		signalNamesDirty = true;
	};

	bindSignal = function(signalName, pressedEventName, releasedEventName, changedEventName)
	{
		if(is_undefined(signalName) || signalName == "")
		{
			return;
		}

		bindings[$ signalName] =
		{
			pressed : pressedEventName,
			released : releasedEventName,
			changed : changedEventName
		};
	};

	removeSignal = function(signalName)
	{
		if(is_undefined(signalName) || signalName == "")
		{
			return;
		}

		if(variable_struct_exists(signalDefs, signalName))
		{
			variable_struct_remove(signalDefs, signalName);
		}

		if(variable_struct_exists(signals, signalName))
		{
			variable_struct_remove(signals, signalName);
		}

		if(variable_struct_exists(bindings, signalName))
		{
			variable_struct_remove(bindings, signalName);
		}

		signalNamesDirty = true;
	};

	updateSignals = function()
	{
		if(signalNamesDirty)
		{
			rebuildSignalNames();
		}

		var count = array_length(signalNames);

		for(var i = 0; i < count; i += 1)
		{
			var signalName = signalNames[i];
			var mapperFn = signalDefs[$ signalName];
			var state = signals[$ signalName];

			var prevValue = state.value;
			var value = mapperFn(raw);

			state.prevValue = prevValue;
			state.pressed = (value != 0) && (prevValue == 0);
			state.released = (value == 0) && (prevValue != 0);
			state.value = value;

			signals[$ signalName] = state;
		}
	};

	dispatchEvents = function()
	{
		if(!is_struct(eventBus)
			|| !variable_struct_exists(eventBus, "emit")
			|| !is_callable(eventBus.emit))
		{
			return;
		}

		if(consumeAllSignals)
		{
			return;
		}

		if(signalNamesDirty)
		{
			rebuildSignalNames();
		}

		var count = array_length(signalNames);

		for(var i = 0; i < count; i += 1)
		{
			if(consumeAllSignals)
			{
				return;
			}

			var signalName = signalNames[i];

			if(self.isConsumed(signalName))
			{
				continue;
			}

			if(!variable_struct_exists(bindings, signalName))
			{
				continue;
			}

			var state = signals[$ signalName];
			var bind = bindings[$ signalName];

			if(state.pressed && !is_undefined(bind.pressed) && bind.pressed != "" && !self.isConsumed(signalName))
			{
				var fired = eventBus.emit(bind.pressed, { signal : signalName, value : state.value }, noone);
				if(!is_real(fired))
				{
					fired = 0;
				}

				if(fired <= 0 && signalName == "pause" && bind.pressed == "flow/togglePause")
				{
					eventBus.emit("game/pause", { signal : signalName, value : state.value }, noone);
				}
			}

			if(state.released && !is_undefined(bind.released) && bind.released != "" && !self.isConsumed(signalName))
			{
				eventBus.emit(bind.released, { signal : signalName, value : state.value }, noone);
			}

			if(state.value != state.prevValue && !is_undefined(bind.changed) && bind.changed != "" && !self.isConsumed(signalName))
			{
				eventBus.emit(bind.changed, { signal : signalName, value : state.value, prevValue : state.prevValue }, noone);
			}
		}
	};

	beginFrame = function()
	{
		captureRaw();
		updateSignals();
	};

	captureRaw = function()
	{
		var keyCount = array_length(watchedKeys);

		for(var i = 0; i < keyCount; i += 1)
		{
			var key = watchedKeys[i];

			raw.keyDown[key] = keyboard_check(key);
			raw.keyPressed[key] = keyboard_check_pressed(key);
			raw.keyReleased[key] = keyboard_check_released(key);
		}

		var btnCount = array_length(watchedMouseButtons);

		for(var j = 0; j < btnCount; j += 1)
		{
			var btn = watchedMouseButtons[j];

			raw.mouseDown[btn] = mouse_check_button(btn);
			raw.mousePressed[btn] = mouse_check_button_pressed(btn);
			raw.mouseReleased[btn] = mouse_check_button_released(btn);
		}
	};

	update = function()
	{
		clearConsumed();
		beginFrame();
		dispatchEvents();
	};
}
