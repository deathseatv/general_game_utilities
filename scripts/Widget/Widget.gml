function Widget() constructor
{
	enabled = true;
	visible = true;

	drawX = 0;
	drawY = 0;

	width = 0;
	height = 0;

	layer = 0;

	gui = undefined;
	events = undefined;

	surfaceHandle = -1;
	dirty = true;

	unsubscribers = [];

	init = function(guiRef, busRef)
	{
		gui = guiRef;
		events = busRef;
		onInit();
	};

	onInit = function()
	{
	};

	addSubscription = function(eventName, handlerFn)
	{
		if(is_undefined(events) || !is_struct(events) || !variable_struct_exists(events, "on"))
		{
			return;
		}

		var token = events.on(eventName, handlerFn);

		var n = array_length(unsubscribers);
		unsubscribers[n] = token;
	};

	setPosition = function(posX, posY)
	{
		drawX = posX;
		drawY = posY;
	};

	setSize = function(w, h)
	{
		width = w;
		height = h;
		dirty = true;
		_ensureSurface();
	};

	markDirty = function()
	{
		dirty = true;
	};

	update = function()
	{
		if(!enabled)
		{
			return;
		}

		onUpdate();
	};

	onUpdate = function()
	{
	};

	drawGui = function()
	{
		if(!visible)
		{
			return;
		}

		_ensureSurface();

		if(surfaceHandle == -1 || !surface_exists(surfaceHandle))
		{
			return;
		}

		if(dirty)
		{
			_renderToSurface();
			dirty = false;
		}

		draw_surface(surfaceHandle, drawX, drawY);
	};

	onRender = function()
	{
	};

	onGuiResize = function(newGuiW, newGuiH)
	{
	};

	destroy = function()
	{
		for(var i = 0; i < array_length(unsubscribers); i += 1)
		{
			var token = unsubscribers[i];

			if(!is_undefined(token) && is_struct(token) && variable_struct_exists(token, "unsubscribe"))
			{
				token.unsubscribe();
			}
		}

		unsubscribers = [];

		if(surfaceHandle != -1 && surface_exists(surfaceHandle))
		{
			surface_free(surfaceHandle);
			surfaceHandle = -1;
		}

		onDestroy();
	};

	onDestroy = function()
	{
	};

	_ensureSurface = function()
	{
		if(width <= 0 || height <= 0)
		{
			return;
		}

		if(surfaceHandle != -1 && surface_exists(surfaceHandle))
		{
			var curW = surface_get_width(surfaceHandle);
			var curH = surface_get_height(surfaceHandle);

			if(curW == width && curH == height)
			{
				return;
			}

			surface_free(surfaceHandle);
			surfaceHandle = -1;
		}

		surfaceHandle = surface_create(width, height);
		dirty = true;
	};

	_renderToSurface = function()
	{
		if(surfaceHandle == -1 || !surface_exists(surfaceHandle))
		{
			return;
		}

		surface_set_target(surfaceHandle);
		draw_clear_alpha(c_black, 0);
		onRender();
		surface_reset_target();
	};
}
