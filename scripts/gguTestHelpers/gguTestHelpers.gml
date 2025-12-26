function gguTestGlobalUnset(name)
{
	var k = string(name);

	if(is_struct(global) && variable_struct_exists(global, k))
	{
		variable_struct_remove(global, k);
		return;
	}

	variable_global_set(k, undefined);
}

function gguTestSnapshotGlobals(names)
{
	var snap =
	{
		names : names,
		exists : [],
		values : []
	};

	var n = array_length(names);

	for(var i = 0; i < n; i += 1)
	{
		var k = names[i];
		snap.exists[i] = variable_global_exists(k);

		if(snap.exists[i])
		{
			snap.values[i] = variable_global_get(k);
		}
		else
		{
			snap.values[i] = undefined;
		}
	}

	return snap;
}

function gguTestRestoreGlobals(snap)
{
	var n = array_length(snap.names);

	for(var i = 0; i < n; i += 1)
	{
		var k = snap.names[i];

		if(snap.exists[i])
		{
			variable_global_set(k, snap.values[i]);
		}
		else
		{
			gguTestGlobalUnset(k);
		}
	}
}

function gguTestMakeAppStub(booted)
{
	return
	{
		booted : booted,

		init : function(){ },
		update : function(){ },

		draw : function(){ },
		drawGui : function(){ }
	};
}

function gguTestMakeEventSpy()
{
	var spy =
	{
		count : 0,
		lastPayload : undefined,
		lastEventName : "",

		onEvent : function(payload, eventName, sender)
		{
			self.count += 1;
			self.lastPayload = payload;
			self.lastEventName = eventName;
		}
	};

	spy.handler = method(spy, spy.onEvent);
	return spy;
}
