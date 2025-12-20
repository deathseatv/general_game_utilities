function EventBus() constructor
{
	listeners = {};
	nextId = 0;

	makeUnsubscriber = function(busRef, eventName, subId)
	{
		var token =
		{
			busRef : busRef,
			eventName : eventName,
			subId : subId,

			unsubscribe : function()
			{
				if(is_undefined(self.busRef) || !variable_struct_exists(self.busRef, "off"))
				{
					return false;
				}

				return self.busRef.off(self.eventName, self.subId);
			}
		};

		return method(token, token.unsubscribe);
	};

	addListener = function(eventName, handler, context, isOnce)
	{
		if(is_undefined(eventName) || eventName == "")
		{
			return function() { };
		}

		if(!is_callable(handler))
		{
			return function() { };
		}

		if(!variable_struct_exists(listeners, eventName))
		{
			listeners[$ eventName] = [];
		}

		var boundHandler = is_undefined(context) ? handler : method(context, handler);

		var subId = nextId;
		nextId += 1;

		var bucket = listeners[$ eventName];
		bucket[array_length(bucket)] =
		{
			id : subId,
			fn : boundHandler,
			once : isOnce
		};
		listeners[$ eventName] = bucket;

		return makeUnsubscriber(self, eventName, subId);
	};

	on = function()
	{
		var eventName = (argument_count > 0) ? argument[0] : "";
		var handler = (argument_count > 1) ? argument[1] : undefined;
		var context = (argument_count > 2) ? argument[2] : undefined;

		return addListener(eventName, handler, context, false);
	};

	once = function()
	{
		var eventName = (argument_count > 0) ? argument[0] : "";
		var handler = (argument_count > 1) ? argument[1] : undefined;
		var context = (argument_count > 2) ? argument[2] : undefined;

		return addListener(eventName, handler, context, true);
	};

	off = function(eventName, subId)
	{
		if(is_undefined(eventName) || eventName == "")
		{
			return false;
		}

		if(!variable_struct_exists(listeners, eventName))
		{
			return false;
		}

		var bucket = listeners[$ eventName];

		for(var i = array_length(bucket) - 1; i >= 0; i -= 1)
		{
			if(bucket[i].id == subId)
			{
				bucket = array_delete(bucket, i, 1);
				listeners[$ eventName] = bucket;
				return true;
			}
		}

		return false;
	};

	emit = function()
	{
		var eventName = (argument_count > 0) ? argument[0] : "";
		var payload = (argument_count > 1) ? argument[1] : undefined;
		var sender = (argument_count > 2) ? argument[2] : noone;

		if(is_undefined(eventName) || eventName == "")
		{
			return 0;
		}

		if(!variable_struct_exists(listeners, eventName))
		{
			return 0;
		}

		var bucket = listeners[$ eventName];
		var fired = 0;

		for(var i = array_length(bucket) - 1; i >= 0; i -= 1)
		{
			var sub = bucket[i];

			if(is_callable(sub.fn))
			{
				sub.fn(payload, eventName, sender);
				fired += 1;
			}

			if(sub.once)
			{
				bucket = array_delete(bucket, i, 1);
			}
		}

		listeners[$ eventName] = bucket;
		return fired;
	};

	clear = function(eventName)
	{
		if(is_undefined(eventName))
		{
			listeners = {};
			return;
		}

		if(eventName == "")
		{
			return;
		}

		if(variable_struct_exists(listeners, eventName))
		{
			listeners[$ eventName] = [];
		}
	};
}
