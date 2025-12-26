function gguLifecycleInstall()
{
	gguEventNamesEnsure();

	var services = gguServicesEnsure(true);
	var events = services.events;

	if(!is_struct(events)
		|| !variable_struct_exists(events, "on") || !is_callable(events.on)
		|| !variable_struct_exists(events, "emit") || !is_callable(events.emit))
	{
		return false;
	}

	if(!variable_global_exists("gguLifecycle") || !is_struct(global.gguLifecycle))
	{
		global.gguLifecycle =
		{
			installed : false,
			paused : false,
			inGameplay : false,
			unsubs : [],
			ctx : undefined
		};
	}

	if(global.gguLifecycle.installed)
	{
		return false;
	}

	global.gguLifecycle.installed = true;

	var ctx =
	{
		events : events,

		nameLifecycleBooted : gguEventName("lifecycleBooted", "lifecycle/booted"),
		nameGameplayEnter : gguEventName("gameplayEnter", "gameplay/enter"),
		nameGameplayExit : gguEventName("gameplayExit", "gameplay/exit"),

		nameGameStart : gguEventName("gameStart", "game/start"),
		nameGameMainMenu : gguEventName("gameMainMenu", "game/mainMenu"),
		nameFlowMainMenu : gguEventName("flowMainMenu", "flow/mainMenu"),

		namePauseEntered : gguEventName("pauseEntered", "pause/entered"),
		namePauseExited : gguEventName("pauseExited", "pause/exited"),
		nameGamePause : gguEventName("gamePause", "game/pause"),
		nameGameUnpause : gguEventName("gameUnpause", "game/unpause"),

		emitSafe : function(eventName, payload)
		{
			if(eventName == "")
			{
				return;
			}

			self.events.emit(eventName, is_undefined(payload) ? { } : payload, noone);
		},

		onGameStart : function(payload, eventName, sender)
		{
			global.gguLifecycle.inGameplay = true;
			self.emitSafe(self.nameGameplayEnter, payload);
		},

		onExit : function(payload, eventName, sender)
		{
			if(global.gguLifecycle.inGameplay)
			{
				global.gguLifecycle.inGameplay = false;
				self.emitSafe(self.nameGameplayExit, payload);
			}
		},

		onPauseEntered : function(payload, eventName, sender)
		{
			global.gguLifecycle.paused = true;
		},

		onPauseExited : function(payload, eventName, sender)
		{
			global.gguLifecycle.paused = false;
		},

		onGamePause : function(payload, eventName, sender)
		{
			if(!global.gguLifecycle.paused)
			{
				global.gguLifecycle.paused = true;
				self.emitSafe(self.namePauseEntered, { });
			}
		},

		onGameUnpause : function(payload, eventName, sender)
		{
			if(global.gguLifecycle.paused)
			{
				global.gguLifecycle.paused = false;
				self.emitSafe(self.namePauseExited, { });
			}
		}
	};

	global.gguLifecycle.ctx = ctx;

	var unsubs = [];

	array_push(unsubs, events.on(ctx.nameGameStart, method(ctx, ctx.onGameStart)));

	array_push(unsubs, events.on(ctx.nameGameMainMenu, method(ctx, ctx.onExit)));
	array_push(unsubs, events.on(ctx.nameFlowMainMenu, method(ctx, ctx.onExit)));

	array_push(unsubs, events.on(ctx.namePauseEntered, method(ctx, ctx.onPauseEntered)));
	array_push(unsubs, events.on(ctx.namePauseExited, method(ctx, ctx.onPauseExited)));

	array_push(unsubs, events.on(ctx.nameGamePause, method(ctx, ctx.onGamePause)));
	array_push(unsubs, events.on(ctx.nameGameUnpause, method(ctx, ctx.onGameUnpause)));

	global.gguLifecycle.unsubs = unsubs;

	var app = services.app;
	if(is_struct(app) && variable_struct_exists(app, "booted") && app.booted)
	{
		ctx.emitSafe(ctx.nameLifecycleBooted, { });
	}

	return true;
}

function gguLifecycleUninstall()
{
	if(!variable_global_exists("gguLifecycle") || !is_struct(global.gguLifecycle))
	{
		return false;
	}

	if(!global.gguLifecycle.installed)
	{
		return false;
	}

	if(variable_struct_exists(global.gguLifecycle, "unsubs") && is_array(global.gguLifecycle.unsubs))
	{
		for(var i = 0; i < array_length(global.gguLifecycle.unsubs); i += 1)
		{
			var u = global.gguLifecycle.unsubs[i];
			if(is_callable(u))
			{
				u();
			}
		}
	}

	global.gguLifecycle.unsubs = [];
	global.gguLifecycle.ctx = undefined;
	global.gguLifecycle.installed = false;
	return true;
}

function gguLifecycleIsInstalled()
{
	return variable_global_exists("gguLifecycle")
		&& is_struct(global.gguLifecycle)
		&& global.gguLifecycle.installed;
}
