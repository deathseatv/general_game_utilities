function SceneManager() constructor
{
	eventBus = undefined;

	fadeFrames = 20;
	fadeAlpha = 0.0;

	isTransitioning = false;
	isLoading = false;

	phase = "idle"; // idle | fadeOut | switch | fadeIn

	pendingRoom = -1;
	pendingFromRoom = -1;
	pendingMode = ""; // load | reload | next

	setEventBus = function(bus)
	{
		eventBus = bus;
	};

	setFadeFrames = function(frames)
	{
		if(!is_real(frames))
		{
			return;
		}

		fadeFrames = max(1, frames);
	};

	resolveRoom = function(sceneId)
	{
		if(is_real(sceneId))
		{
			return sceneId;
		}

		if(is_string(sceneId))
		{
			return asset_get_index(sceneId);
		}

		return -1;
	};

	emitWillLoad = function(fromRoom, toRoom, mode)
	{
		if(is_undefined(eventBus))
		{
			return;
		}

		eventBus.emit("scene/willLoad", { from : fromRoom, to : toRoom, mode : mode }, noone);
	};

	emitDidLoad = function(roomId, mode)
	{
		if(is_undefined(eventBus))
		{
			return;
		}

		eventBus.emit("scene/didLoad", { room : roomId, mode : mode }, noone);
	};

	load = function(sceneId)
	{
		var roomId = resolveRoom(sceneId);

		if(roomId < 0)
		{
			return false;
		}

		if(isTransitioning)
		{
			return false;
		}

		pendingFromRoom = room;
		pendingRoom = roomId;
		pendingMode = "load";

		isTransitioning = true;
		isLoading = true;
		phase = "fadeOut";
		fadeAlpha = 0.0;

		emitWillLoad(pendingFromRoom, pendingRoom, pendingMode);

		return true;
	};

	reload = function()
	{
		if(isTransitioning)
		{
			return false;
		}

		pendingFromRoom = room;
		pendingRoom = room;
		pendingMode = "reload";

		isTransitioning = true;
		isLoading = true;
		phase = "fadeOut";
		fadeAlpha = 0.0;

		emitWillLoad(pendingFromRoom, pendingRoom, pendingMode);

		return true;
	};

	next = function()
	{
		if(isTransitioning)
		{
			return false;
		}

		pendingFromRoom = room;
		pendingRoom = -1;
		pendingMode = "next";

		isTransitioning = true;
		isLoading = true;
		phase = "fadeOut";
		fadeAlpha = 0.0;

		emitWillLoad(pendingFromRoom, pendingRoom, pendingMode);

		return true;
	};

	onSceneLoad = function(payload, eventName, sender)
	{
		if(!is_struct(payload))
		{
			return;
		}

		if(!variable_struct_exists(payload, "sceneId"))
		{
			return;
		}

		load(payload.sceneId);
	};

	onSceneReload = function(payload, eventName, sender)
	{
		reload();
	};

	onSceneNext = function(payload, eventName, sender)
	{
		next();
	};

	onStateChanged = function(payload, eventName, sender)
	{
		// stub: if your state machine drives scenes, translate state -> room here
	};

	init = function(bus)
	{
		setEventBus(bus);

		if(is_undefined(eventBus))
		{
			return;
		}

		eventBus.on("scene/load", method(self, self.onSceneLoad));
		eventBus.on("scene/reload", method(self, self.onSceneReload));
		eventBus.on("scene/next", method(self, self.onSceneNext));
		eventBus.on("state/changed", method(self, self.onStateChanged));
	};

	update = function()
	{
		if(!isTransitioning)
		{
			return;
		}

		var stepAlpha = 1.0 / fadeFrames;

		if(phase == "fadeOut")
		{
			fadeAlpha = min(1.0, fadeAlpha + stepAlpha);

			if(fadeAlpha >= 1.0)
			{
				phase = "switch";
			}

			return;
		}

		if(phase == "switch")
		{
			if(pendingMode == "reload")
			{
				room_restart();
			}
			else if(pendingMode == "next")
			{
				room_goto_next();
			}
			else
			{
				room_goto(pendingRoom);
			}

			phase = "fadeIn";
			return;
		}

		if(phase == "fadeIn")
		{
			fadeAlpha = max(0.0, fadeAlpha - stepAlpha);

			if(fadeAlpha <= 0.0)
			{
				phase = "idle";
				isTransitioning = false;
				isLoading = false;

				pendingRoom = -1;
				pendingFromRoom = -1;
				pendingMode = "";
			}
		}
	};

	onRoomStart = function()
	{
		if(!isLoading)
		{
			return;
		}

		emitDidLoad(room, pendingMode);
	};

	drawGui = function()
	{
		if(!isTransitioning)
		{
			return;
		}

		if(fadeAlpha <= 0.0)
		{
			return;
		}

		var w = display_get_gui_width();
		var h = display_get_gui_height();

		draw_set_alpha(fadeAlpha);
		draw_set_color(c_black);
		draw_rectangle(0, 0, w, h, false);
		draw_set_alpha(1);
	};
}
