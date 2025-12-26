function gguServicesEnsure(autoInit)
{
	if(argument_count < 1)
	{
		autoInit = true;
	}

	if(autoInit)
	{
		if(!variable_global_exists("app") || !is_struct(global.app))
		{
			global.app = new AppController();

			if(is_struct(global.app)
				&& variable_struct_exists(global.app, "init")
				&& is_callable(global.app.init))
			{
				global.app.init();
			}
		}
	}

	gguEventNamesEnsure();

	var s =
	{
		app : (variable_global_exists("app") && is_struct(global.app)) ? global.app : undefined,

		events : (variable_global_exists("events") && is_struct(global.events)) ? global.events
			: ((variable_global_exists("eventBus") && is_struct(global.eventBus)) ? global.eventBus : undefined),

		assets : (variable_global_exists("assets") && is_struct(global.assets)) ? global.assets : undefined,
		input : (variable_global_exists("input") && is_struct(global.input)) ? global.input : undefined,
		menus : (variable_global_exists("menus") && is_struct(global.menus)) ? global.menus : undefined,
		audio : (variable_global_exists("audio") && is_struct(global.audio)) ? global.audio : undefined,
		scenes : (variable_global_exists("scenes") && is_struct(global.scenes)) ? global.scenes : undefined,
		gameState : (variable_global_exists("gameState") && is_struct(global.gameState)) ? global.gameState : undefined,
		settings : (variable_global_exists("settings") && is_struct(global.settings)) ? global.settings : undefined,
		keybinds : (variable_global_exists("keybinds") && is_struct(global.keybinds)) ? global.keybinds : undefined,
		time : (variable_global_exists("time") && is_struct(global.time)) ? global.time : undefined,
		camera : (variable_global_exists("camera") && is_struct(global.camera)) ? global.camera : undefined,
		gui : (variable_global_exists("gui") && is_struct(global.gui)) ? global.gui : undefined,

		debugConsole : (variable_global_exists("debugConsole") && is_struct(global.debugConsole)) ? global.debugConsole : undefined,

		saveGame : (variable_global_exists("saveGame") && is_struct(global.saveGame)) ? global.saveGame : undefined,
		flow : (variable_global_exists("flow") && is_struct(global.flow)) ? global.flow : undefined
	};

	global.gguServices = s;
	return s;
}

function gguService(name)
{
	if(!variable_global_exists("gguServices") || !is_struct(global.gguServices))
	{
		gguServicesEnsure(false);
	}

	var k = string(name);

	if(variable_struct_exists(global.gguServices, k))
	{
		return global.gguServices[$ k];
	}

	return undefined;
}
