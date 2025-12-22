function gmtlDbgHasGlobal(name)
{
	return variable_struct_exists(global, name);
}

function gmtlDbgGetGlobal(name)
{
	if(!gmtlDbgHasGlobal(name))
	{
		return undefined;
	}

	return global[$ name];
}

function gmtlDbgSetGlobal(name, value)
{
	global[$ name] = value;
}

function gmtlDbgRemoveGlobal(name)
{
	if(gmtlDbgHasGlobal(name))
	{
		variable_struct_remove(global, name);
	}
}

function gmtlDbgSnapGlobals(names)
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
		var key = names[i];
		snap.exists[i] = gmtlDbgHasGlobal(key);
		snap.values[i] = gmtlDbgGetGlobal(key);
	}

	return snap;
}

function gmtlDbgRestoreGlobals(snap)
{
	var n = array_length(snap.names);

	for(var i = 0; i < n; i += 1)
	{
		var key = snap.names[i];

		if(snap.exists[i])
		{
			gmtlDbgSetGlobal(key, snap.values[i]);
		}
		else
		{
			gmtlDbgRemoveGlobal(key);
		}
	}
}

function gmtlDebugLogTests()
{
	suite(function()
	{
		section("debugLog", function()
		{
			test("calls global.debugConsole.log when it is a method", function()
			{
				var snap = gmtlDbgSnapGlobals([ "debugConsole" ]);

				var spy =
				{
					msgs : []
				};

				spy.log = method(spy, function(msg)
				{
					self.msgs[array_length(self.msgs)] = msg;
				});

				global.debugConsole = spy;

				debugLog("hello");

				expect(array_length(spy.msgs)).toBe(1);
				expect(spy.msgs[0]).toBe("hello");

				gmtlDbgRestoreGlobals(snap);
			});

			test("does not crash when global.debugConsole is undefined", function()
			{
				var snap = gmtlDbgSnapGlobals([ "debugConsole" ]);

				global.debugConsole = undefined;

				debugLog("fallback path");
				expect(true).toBe(true);

				gmtlDbgRestoreGlobals(snap);
			});

			test("does not crash when global.debugConsole.log is not a method", function()
			{
				var snap = gmtlDbgSnapGlobals([ "debugConsole" ]);

				global.debugConsole =
				{
					log : "not a method"
				};

				debugLog("fallback path");
				expect(true).toBe(true);

				gmtlDbgRestoreGlobals(snap);
			});
		});
	});
}
