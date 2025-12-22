function DebugConsole() constructor
{
	isOpen = false;
	pauseWhenOpen = true;

	openKey = 192;

	consumed = false;

	maxLines = 200;
	lines = [];

	commands = {};

	open = function()
	{
		isOpen = true;
		keyboard_string = "";
		log("Console opened. Type 'help'.");
	};

	close = function()
	{
		isOpen = false;
		keyboard_string = "";
	};

	toggle = function(canOpen)
	{
		if(!canOpen)
		{
			close();
			return;
		}

		if(isOpen)
		{
			close();
			return;
		}

		open();
	};

	log = function(msg)
	{
		var line = string(msg);
		lines[array_length(lines)] = line;

		var count = array_length(lines);
		if(count > maxLines)
		{
			array_delete(lines, 0, count - maxLines);
		}

		show_debug_message(line);
	};

	registerCommand = function(name, usage, fn)
	{
		var key = string_lower(string(name));
		var entry = { usage: usage, fn: fn };
		variable_struct_set(commands, key, entry);
	};

	execLine = function(rawLine)
	{
		var line = string_trim(string(rawLine));
		if(line == "")
		{
			return;
		}

		log("> " + line);

		var parts = string_split(line, " ");
		if(array_length(parts) <= 0)
		{
			return;
		}

		var cmd = string_lower(parts[0]);
		if(!variable_struct_exists(commands, cmd))
		{
			log("Unknown command: " + cmd);
			return;
		}

		var entry = variable_struct_get(commands, cmd);

		var argc = array_length(parts) - 1;
		var args = [];
		if(argc > 0)
		{
			args = array_create(argc);
			for(var i = 0; i < argc; i += 1)
			{
				args[i] = parts[i + 1];
			}
		}

		if(is_struct(entry) && variable_struct_exists(entry, "fn"))
		{
			entry.fn(args, line);
		}
	};

	update = function(canOpen)
	{
		consumed = false;

		if(keyboard_check_pressed(openKey))
		{
			toggle(canOpen);
			consumed = true;
			return;
		}

		if(!isOpen)
		{
			return;
		}

		if(!canOpen)
		{
			close();
			consumed = true;
			return;
		}

		if(keyboard_check_pressed(vk_escape))
		{
			close();
			consumed = true;
			return;
		}

		if(keyboard_check_pressed(vk_enter))
		{
			var line = keyboard_string;
			keyboard_string = "";
			execLine(line);

			consumed = true;
			return;
		}
	};

	drawGui = function(x, y, w, h)
	{
		if(!isOpen)
		{
			return;
		}

		draw_set_color(c_black);
		draw_set_alpha(0.80);
		draw_rectangle(x, y, x + w, y + h, false);
		draw_set_alpha(1);

		draw_set_color(c_white);

		var padding = 8;
		var lineH = 16;

		var maxVisible = floor((h - padding * 2 - lineH) / lineH);
		var start = max(0, array_length(lines) - maxVisible);

		var yy = y + padding;
		for(var i = start; i < array_length(lines); i += 1)
		{
			draw_text(x + padding, yy, lines[i]);
			yy += lineH;
		}

		draw_text(x + padding, y + h - padding - lineH, "> " + keyboard_string);
	};
}
