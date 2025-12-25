function SettingsManager() constructor
{
	eventBus = undefined;

	unsubs = [];

	defaults =
	{
		masterVolume : 1.0,
		musicVolume : 1.0,
		sfxVolume : 1.0,
		uiVolume : 1.0,
		fullscreen : false
	};

	values =
	{
		masterVolume : defaults.masterVolume,
		musicVolume : defaults.musicVolume,
		sfxVolume : defaults.sfxVolume,
		uiVolume : defaults.uiVolume,
		fullscreen : defaults.fullscreen
	};

	fileName = "settings.json";

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
		else if(key == "fullscreen")
		{
			if(is_bool(next))
			{
				// ok
			}
			else if(is_real(next))
			{
				next = (next != 0);
			}
			else
			{
				return false;
			}
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
		applyAudio();
		applyVideo();

		if(!is_undefined(eventBus))
		{
			eventBus.emit("settings/applied", { }, noone);
		}

		save();
	};

	applyAudio = function()
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
	};

	applyVideo = function()
	{
		window_set_fullscreen(values.fullscreen);
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

	setFullscreen = function(isFullscreen)
	{
		if(set("fullscreen", isFullscreen))
		{
			applyVideo();
			save();
		}
	};

	toggleFullscreen = function()
	{
		setFullscreen(!values.fullscreen);
	};

	getSavePath = function()
	{
		return fileName;
	};

	toStruct = function()
	{
		return
		{
			masterVolume : values.masterVolume,
			musicVolume : values.musicVolume,
			sfxVolume : values.sfxVolume,
			uiVolume : values.uiVolume,
			fullscreen : values.fullscreen
		};
	};

	setSilently = function(key, value)
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
		else if(key == "fullscreen")
		{
			if(is_bool(next))
			{
				// ok
			}
			else if(is_real(next))
			{
				next = (next != 0);
			}
			else
			{
				return false;
			}
		}

		if(values[$ key] == next)
		{
			return false;
		}

		values[$ key] = next;
		return true;
	};

	fromStruct = function(s)
	{
		if(!is_struct(s))
		{
			return false;
		}

		var keys = variable_struct_get_names(defaults);
		var n = array_length(keys);
		var changed = false;

		for(var i = 0; i < n; i += 1)
		{
			var k = keys[i];
			if(variable_struct_exists(s, k))
			{
				if(setSilently(k, s[$ k]))
				{
					changed = true;
				}
			}
		}

		return changed;
	};

	readTextFile = function(path)
	{
		if(!file_exists(path))
		{
			return "";
		}

		var f = file_text_open_read(path);
		if(f < 0)
		{
			return "";
		}

		var text = "";

		while(!file_text_eof(f))
		{
			text += file_text_readln(f);
			if(!file_text_eof(f))
			{
				text += "\n";
			}
		}

		file_text_close(f);
		return text;
	};

	writeTextFile = function(path, text)
	{
		var f = file_text_open_write(path);
		if(f < 0)
		{
			return false;
		}

		file_text_write_string(f, string(text));
		file_text_close(f);
		return true;
	};

	safeWrite = function(path, text)
	{
		var tmp = path + ".tmp";
		var bak = path + ".bak";

		if(file_exists(tmp))
		{
			file_delete(tmp);
		}

		if(!writeTextFile(tmp, text))
		{
			return false;
		}

		var hadExisting = file_exists(path);

		if(hadExisting)
		{
			if(file_exists(bak))
			{
				file_delete(bak);
			}

			if(!file_rename(path, bak))
			{
				if(file_exists(tmp))
				{
					file_delete(tmp);
				}

				return false;
			}
		}

		if(!file_rename(tmp, path))
		{
			if(hadExisting && file_exists(bak) && !file_exists(path))
			{
				file_rename(bak, path);
			}

			if(file_exists(tmp))
			{
				file_delete(tmp);
			}

			return false;
		}

		return true;
	};

	load = function()
	{
		var path = getSavePath();
		if(!file_exists(path))
		{
			return false;
		}

		var raw = readTextFile(path);
		if(raw == "")
		{
			return false;
		}

		var data = json_parse(raw);
		if(!is_struct(data))
		{
			return false;
		}

		if(variable_struct_exists(data, "settings") && is_struct(data.settings))
		{
			return fromStruct(data.settings);
		}

		return fromStruct(data);
	};

	save = function()
	{
		var path = getSavePath();
		var data =
		{
			version : 1,
			settings : toStruct()
		};

		var raw = json_stringify(data);
		return safeWrite(path, raw);
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

	clearWiring = function()
	{
		var n = array_length(unsubs);
		for(var i = 0; i < n; i += 1)
		{
			var fn = unsubs[i];
			if(is_callable(fn)) fn();
		}
		unsubs = [];
	};

	destroy = function()
	{
		self.clearWiring();
		eventBus = undefined;
		return true;
	};

	init = function(bus)
	{
		eventBus = bus;
		self.clearWiring();

		if(is_undefined(eventBus))
		{
			return;
		}

		array_push(unsubs, eventBus.on("settings/set", method(self, self.onSettingsSet)));
		array_push(unsubs, eventBus.on("settings/apply", method(self, self.onSettingsApply)));
		array_push(unsubs, eventBus.on("settings/reset", method(self, self.onSettingsReset)));
	};
}
