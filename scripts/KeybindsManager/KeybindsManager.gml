function KeybindsManager() constructor
{
	fileName = "keybinds.json";

	defaults =
	{
		pause : vk_escape,
		recenter : vk_space,
		toggleFullscreen : vk_f10
	};

	binds =
	{
		pause : defaults.pause,
		recenter : defaults.recenter,
		toggleFullscreen : defaults.toggleFullscreen
	};

	getSavePath = function()
	{
		return fileName;
	};

	hasAction = function(actionName)
	{
		if(is_undefined(actionName) || actionName == "")
		{
			return false;
		}

		return variable_struct_exists(binds, actionName);
	};

	getActionNames = function()
	{
		return variable_struct_get_names(binds);
	};

	getKey = function(actionName)
	{
		if(!hasAction(actionName))
		{
			return undefined;
		}

		return binds[$ actionName];
	};

	findActionByKey = function(vkCode)
	{
		var names = variable_struct_get_names(binds);
		var n = array_length(names);

		for(var i = 0; i < n; i += 1)
		{
			var a = names[i];
			if(binds[$ a] == vkCode)
			{
				return a;
			}
		}

		return "";
	};

	setKey = function(actionName, vkCode)
	{
		if(!hasAction(actionName))
		{
			return false;
		}

		if(!is_real(vkCode))
		{
			return false;
		}

		var next = floor(vkCode);
		var prev = binds[$ actionName];

		if(prev == next)
		{
			return false;
		}

		var _other = findActionByKey(next);
		if(_other != "" && _other != actionName)
		{
			binds[$ _other] = prev;
		}

		binds[$ actionName] = next;
		return true;
	};

	resetDefaults = function()
	{
		var names = variable_struct_get_names(defaults);
		var n = array_length(names);

		for(var i = 0; i < n; i += 1)
		{
			var a = names[i];
			if(variable_struct_exists(binds, a))
			{
				binds[$ a] = defaults[$ a];
			}
		}
	};

	toStruct = function()
	{
		var out = { };
		var names = variable_struct_get_names(binds);
		var n = array_length(names);

		for(var i = 0; i < n; i += 1)
		{
			var a = names[i];
			out[$ a] = binds[$ a];
		}

		return out;
	};

	fromStruct = function(s)
	{
		if(!is_struct(s))
		{
			return false;
		}

		var names = variable_struct_get_names(binds);
		var n = array_length(names);
		var changed = false;

		for(var i = 0; i < n; i += 1)
		{
			var a = names[i];
			if(variable_struct_exists(s, a) && is_real(s[$ a]))
			{
				var next = floor(s[$ a]);
				if(binds[$ a] != next)
				{
					binds[$ a] = next;
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

		var data = undefined;
		data = json_parse(raw);

		if(!is_struct(data))
		{
			return false;
		}

		if(variable_struct_exists(data, "binds") && is_struct(data.binds))
		{
			return fromStruct(data.binds);
		}

		return fromStruct(data);
	};

	save = function()
	{
		var path = getSavePath();
		var data =
		{
			version : 1,
			binds : toStruct()
		};

		var raw = json_stringify(data);
		return writeTextFile(path, raw);
	};
}
