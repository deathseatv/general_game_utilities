function GuiManager() constructor
{
	events = undefined;

	widgets = {};
	widgetOrder = [];
	orderDirty = true;

	guiW = display_get_gui_width();
	guiH = display_get_gui_height();

	init = function(bus)
	{
		events = bus;
	};

	addWidget = function(widgetKey, widgetRef, widgetLayer)
	{
		if(!is_string(widgetKey) || widgetKey == "")
		{
			return false;
		}

		if(is_undefined(widgetRef) || !is_struct(widgetRef))
		{
			return false;
		}

		if(variable_struct_exists(widgets, widgetKey))
		{
			removeWidget(widgetKey);
		}

		if(!is_real(widgetLayer))
		{
			widgetLayer = 0;
		}

		widgetRef.layer = widgetLayer;
		widgets[$ widgetKey] = widgetRef;

		if(variable_struct_exists(widgetRef, "init"))
		{
			widgetRef.init(self, events);
		}

		orderDirty = true;
		return true;
	};

	removeWidget = function(widgetKey)
	{
		if(!is_string(widgetKey) || widgetKey == "")
		{
			return false;
		}

		if(!variable_struct_exists(widgets, widgetKey))
		{
			return false;
		}

		var widgetRef = widgets[$ widgetKey];

		if(is_struct(widgetRef) && variable_struct_exists(widgetRef, "destroy"))
		{
			widgetRef.destroy();
		}

		variable_struct_remove(widgets, widgetKey);
		orderDirty = true;

		return true;
	};

	getWidget = function(widgetKey)
	{
		if(!is_string(widgetKey) || widgetKey == "")
		{
			return undefined;
		}

		if(!variable_struct_exists(widgets, widgetKey))
		{
			return undefined;
		}

		return widgets[$ widgetKey];
	};

	update = function()
	{
		var curW = display_get_gui_width();
		var curH = display_get_gui_height();

		if(curW != guiW || curH != guiH)
		{
			guiW = curW;
			guiH = curH;
			_notifyGuiResize(guiW, guiH);
		}

		_rebuildOrderIfNeeded();

		for(var i = 0; i < array_length(widgetOrder); i += 1)
		{
			var widgetKey = widgetOrder[i];
			var widgetRef = widgets[$ widgetKey];

			if(is_struct(widgetRef) && variable_struct_exists(widgetRef, "update"))
			{
				widgetRef.update();
			}
		}
	};

	drawGui = function()
	{
		_rebuildOrderIfNeeded();

		for(var i = 0; i < array_length(widgetOrder); i += 1)
		{
			var widgetKey = widgetOrder[i];
			var widgetRef = widgets[$ widgetKey];

			if(is_struct(widgetRef) && variable_struct_exists(widgetRef, "drawGui"))
			{
				widgetRef.drawGui();
			}
		}
	};

	destroy = function()
	{
		var keys = variable_struct_get_names(widgets);

		for(var i = 0; i < array_length(keys); i += 1)
		{
			var widgetKey = keys[i];
			var widgetRef = widgets[$ widgetKey];

			if(is_struct(widgetRef) && variable_struct_exists(widgetRef, "destroy"))
			{
				widgetRef.destroy();
			}
		}

		widgets = {};
		widgetOrder = [];
		orderDirty = true;
	};

	_notifyGuiResize = function(newGuiW, newGuiH)
	{
		var keys = variable_struct_get_names(widgets);

		for(var i = 0; i < array_length(keys); i += 1)
		{
			var widgetKey = keys[i];
			var widgetRef = widgets[$ widgetKey];

			if(!is_struct(widgetRef))
			{
				continue;
			}

			if(variable_struct_exists(widgetRef, "onGuiResize"))
			{
				widgetRef.onGuiResize(newGuiW, newGuiH);
			}

			if(variable_struct_exists(widgetRef, "markDirty"))
			{
				widgetRef.markDirty();
			}
		}
	};

	_rebuildOrderIfNeeded = function()
	{
		if(!orderDirty)
		{
			return;
		}

		widgetOrder = variable_struct_get_names(widgets);

		var n = array_length(widgetOrder);

		for(var i = 1; i < n; i += 1)
		{
			var keyA = widgetOrder[i];
			var layerA = 0;

			if(is_struct(widgets[$ keyA]) && variable_struct_exists(widgets[$ keyA], "layer"))
			{
				layerA = widgets[$ keyA].layer;
			}

			var j = i - 1;

			while(j >= 0)
			{
				var keyB = widgetOrder[j];
				var layerB = 0;

				if(is_struct(widgets[$ keyB]) && variable_struct_exists(widgets[$ keyB], "layer"))
				{
					layerB = widgets[$ keyB].layer;
				}

				if(layerB <= layerA)
				{
					break;
				}

				widgetOrder[j + 1] = keyB;
				j -= 1;
			}

			widgetOrder[j + 1] = keyA;
		}

		orderDirty = false;
	};
}
