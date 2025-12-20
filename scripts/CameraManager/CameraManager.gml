function CameraManager() constructor
{
	eventBus = undefined;

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

	init = function(bus)
	{
		eventBus = bus;

		if(is_undefined(eventBus))
		{
			return;
		}

		eventBus.on("camera/recenter", method(self, self.onRecenter));
	};
}
