function SettingsManager() constructor
{
	eventBus = undefined;

	defaults =
	{
		masterVolume : 1.0,
		musicVolume : 1.0,
		sfxVolume : 1.0,
		uiVolume : 1.0
	};

	values =
	{
		masterVolume : defaults.masterVolume,
		musicVolume : defaults.musicVolume,
		sfxVolume : defaults.sfxVolume,
		uiVolume : defaults.uiVolume
	};

	clamp01 = function(v)
	{
		if(v < 0) { return 0; }
		if(v > 1) { return 1; }
		return v;
	};

	hasKey = function(key)
	{
		if(is_undefined(key) || key == "")
		{
			return false;
		}

		return variable_struct_exists(values, key);
	};

	get = function(key)
	{
		if(!hasKey(key))
		{
			return undefined;
		}

		return values[$ key];
	};

	set = function(key, value)
	{
		if(!hasKey(key))
		{
			return false;
		}

		var next = value;

		if(key == "masterVolume" || key == "musicVolume" || key == "sfxVolume" || key == "uiVolume")
		{
			if(!is_real(next))
			{
				return false;
			}

			next = clamp01(next);
		}

		var prev = values[$ key];

		if(prev == next)
		{
			return false;
		}

		values[$ key] = next;

		emitChanged(key, prev, next);

		return true;
	};

	emitChanged = function(key, prev, next)
	{
		if(is_undefined(eventBus))
		{
			return;
		}

		eventBus.emit("settings/changed", { key : key, prev : prev, value : next }, noone);
	};

	apply = function()
	{
		if(is_undefined(eventBus))
		{
			return;
		}

		eventBus.emit(
			"audio/setVolume",
			{
				master : values.masterVolume,
				music : values.musicVolume,
				sfx : values.sfxVolume,
				ui : values.uiVolume
			},
			noone
		);

		eventBus.emit("settings/applied", { }, noone);
	};

	resetDefaults = function()
	{
		var keys = variable_struct_get_names(defaults);
		var n = array_length(keys);

		for(var i = 0; i < n; i += 1)
		{
			var k = keys[i];
			set(k, defaults[$ k]);
		}

		apply();
	};

	setMasterVolume = function(v)
	{
		if(set("masterVolume", v))
		{
			apply();
		}
	};

	setMusicVolume = function(v)
	{
		if(set("musicVolume", v))
		{
			apply();
		}
	};

	setSfxVolume = function(v)
	{
		if(set("sfxVolume", v))
		{
			apply();
		}
	};

	setUiVolume = function(v)
	{
		if(set("uiVolume", v))
		{
			apply();
		}
	};

	onSettingsSet = function(payload, eventName, sender)
	{
		if(!is_struct(payload))
		{
			return;
		}

		if(!variable_struct_exists(payload, "key"))
		{
			return;
		}

		if(!variable_struct_exists(payload, "value"))
		{
			return;
		}

		set(payload.key, payload.value);
	};

	onSettingsApply = function(payload, eventName, sender)
	{
		apply();
	};

	onSettingsReset = function(payload, eventName, sender)
	{
		resetDefaults();
	};

	init = function(bus)
	{
		eventBus = bus;

		if(is_undefined(eventBus))
		{
			return;
		}

		eventBus.on("settings/set", method(self, self.onSettingsSet));
		eventBus.on("settings/apply", method(self, self.onSettingsApply));
		eventBus.on("settings/reset", method(self, self.onSettingsReset));
	};
}
