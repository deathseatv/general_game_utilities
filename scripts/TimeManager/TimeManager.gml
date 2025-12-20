function TimeManager() constructor
{
	eventBus = undefined;

	isPaused = false;
	timeScale = 1.0;

	clamp01 = function(v)
	{
		if(v < 0) { return 0; }
		if(v > 1) { return 1; }
		return v;
	};

	setEventBus = function(bus)
	{
		eventBus = bus;
	};

	getTimeScale = function()
	{
		return timeScale;
	};

	getIsPaused = function()
	{
		return isPaused;
	};

	emitPaused = function(paused)
	{
		if(is_undefined(eventBus))
		{
			return;
		}

		eventBus.emit("time/paused", { paused : paused }, noone);
	};

	emitScaleChanged = function(prev, next)
	{
		if(is_undefined(eventBus))
		{
			return;
		}

		eventBus.emit("time/scaleChanged", { prev : prev, value : next }, noone);
	};

	apply = function()
	{
		var effective = isPaused ? 0.0 : timeScale;
		game_set_speed(room_speed * effective, gamespeed_fps);
	};

	setPaused = function(paused)
	{
		if(!is_bool(paused))
		{
			return false;
		}

		if(isPaused == paused)
		{
			return false;
		}

		isPaused = paused;

		apply();
		emitPaused(isPaused);

		return true;
	};

	setTimeScale = function(v)
	{
		if(!is_real(v))
		{
			return false;
		}

		var next = clamp01(v);

		if(timeScale == next)
		{
			return false;
		}

		var prev = timeScale;
		timeScale = next;

		apply();
		emitScaleChanged(prev, next);

		return true;
	};

	onPauseEntered = function(payload, eventName, sender)
	{
		setPaused(true);
	};

	onPauseExited = function(payload, eventName, sender)
	{
		setPaused(false);
	};

	onSetTimeScale = function(payload, eventName, sender)
	{
		if(!is_struct(payload))
		{
			return;
		}

		if(!variable_struct_exists(payload, "value"))
		{
			return;
		}

		setTimeScale(payload.value);
	};

	init = function(bus)
	{
		setEventBus(bus);

		if(is_undefined(eventBus))
		{
			return;
		}

		eventBus.on("pause/entered", method(self, self.onPauseEntered));
		eventBus.on("pause/exited", method(self, self.onPauseExited));
		eventBus.on("time/setScale", method(self, self.onSetTimeScale));
	};
}
