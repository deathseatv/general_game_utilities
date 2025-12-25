function CameraManager() constructor
{
	eventBus = undefined;

	unsubs = [];

	target = noone;

	getCameraId = function()
	{
		if(array_length(view_camera) > 0)
		{
			return view_camera[0];
		}

		return -1;
	};

	setTarget = function(inst)
	{
		target = inst;
	};

	recenter = function()
	{
		if(target == noone || !instance_exists(target))
		{
			return;
		}

		var cam = getCameraId();
		if(cam < 0)
		{
			return;
		}

		var w = camera_get_view_width(cam);
		var h = camera_get_view_height(cam);

		camera_set_view_pos(cam, target.x - (w * 0.5), target.y - (h * 0.5));
	};

	onRecenter = function(payload, eventName, sender)
	{
		recenter();
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

		array_push(unsubs, eventBus.on("camera/recenter", method(self, self.onRecenter)));
	};
}
