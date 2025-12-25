function gmtlIisHasGlobal(name)
{
	return variable_struct_exists(global, name);
}

function gmtlIisGetGlobal(name)
{
	if(!gmtlIisHasGlobal(name))
	{
		return undefined;
	}

	return global[$ name];
}

function gmtlIisSetGlobal(name, value)
{
	global[$ name] = value;
}

function gmtlIisRemoveGlobal(name)
{
	if(gmtlIisHasGlobal(name))
	{
		variable_struct_remove(global, name);
	}
}

function gmtlIisSnapshotGlobals()
{
	var names =
	[
		"input",
		"events",
		"eventBus",
		"eventNames"
	];

	return gmtlSnapshotGlobals(names);
}

function gmtlIisRestoreGlobals(snap)
{
	gmtlRestoreGlobals(snap);
}

function gmtlInitInputInSystemsTests_safe3()
{
	suite(function()
	{
		section("initInputInSystems_safe3", function()
		{
			test("returns false when input invalid and no global.input", function()
			{
				var snap = gmtlIisSnapshotGlobals();

				gmtlIisRemoveGlobal("input");
				gmtlIisRemoveGlobal("events");
				gmtlIisRemoveGlobal("eventBus");

				var bus =
				{
					emit : function(eventName, payload, sender) { return 1; },
					on : function(eventName, handler, ctx) { return function() { }; }
				};

				var ok = initInputInSystems(undefined, bus);
				expect(ok).toBeFalsy();

				gmtlIisRestoreGlobals(snap);
			});

			test("returns false when input missing addSignal", function()
			{
				var snap = gmtlIisSnapshotGlobals();

				var input =
				{
					keyPressed : function(vk)
					{
						return function(raw) { return 0; };
					}
				};

				var bus =
				{
					emit : function(eventName, payload, sender) { return 1; },
					on : function(eventName, handler, ctx) { return function() { }; }
				};

				var ok = initInputInSystems(input, bus);
				expect(ok).toBeFalsy();

				gmtlIisRestoreGlobals(snap);
			});

			test("falls back to global.input when input arg invalid", function()
			{
				var snap = gmtlIisSnapshotGlobals();

				gmtlIisRemoveGlobal("events");
				gmtlIisRemoveGlobal("eventBus");

				global.input =
				{
					addCalls : [],

					keyPressed : function(vk)
					{
						var token =
						{
							run : function(raw) { return 0; }
						};

						return method(token, token.run);
					},

					addSignal : function(signalName, mapperFn)
					{
						var n = array_length(self.addCalls);
						self.addCalls[n] = { signalName : signalName };
					}
				};

				var bus =
				{
					emit : function(eventName, payload, sender) { return 1; },
					on : function(eventName, handler, ctx) { return function() { }; }
				};

				var ok = initInputInSystems(undefined, bus);

				expect(ok).toBeTruthy();
				expect(array_length(global.input.addCalls)).toBe(3);

				gmtlIisRestoreGlobals(snap);
			});

			test("when bus valid, sets bus and binds pause/recenter", function()
			{
				var snap = gmtlIisSnapshotGlobals();

				gmtlIisRemoveGlobal("events");
				gmtlIisRemoveGlobal("eventBus");

				var input =
				{
					addCalls : [],
					bindCalls : [],
					setBusCalls : [],
					eventBus : undefined,

					keyPressed : function(vk)
					{
						var token =
						{
							run : function(raw) { return 0; }
						};

						return method(token, token.run);
					},

					addSignal : function(signalName, mapperFn)
					{
						var n = array_length(self.addCalls);
						self.addCalls[n] = { signalName : signalName };
					},

					setEventBus : function(bus)
					{
						var n = array_length(self.setBusCalls);
						self.setBusCalls[n] = bus;
						self.eventBus = bus;
					},

					bindSignal : function(signalName, pressedEventName, releasedEventName, changedEventName)
					{
						var n = array_length(self.bindCalls);
						self.bindCalls[n] =
						{
							signalName : signalName,
							pressedEventName : pressedEventName
						};
					}
				};

				var bus =
				{
					emit : function(eventName, payload, sender) { return 1; },
					on : function(eventName, handler, ctx) { return function() { }; }
				};

				var ok = initInputInSystems(input, bus);

				expect(ok).toBeTruthy();
				expect(array_length(input.addCalls)).toBe(3);

				expect(array_length(input.setBusCalls)).toBe(1);
				expect(input.eventBus).toBe(bus);

				expect(array_length(input.bindCalls)).toBe(3);
				expect(input.bindCalls[0].signalName).toBe("pause");
				expect(input.bindCalls[0].pressedEventName).toBe("flow/togglePause");
				expect(input.bindCalls[1].signalName).toBe("recenter");
				expect(input.bindCalls[1].pressedEventName).toBe("camera/recenter");

				expect(input.bindCalls[2].signalName).toBe("toggleFullscreen");
				expect(input.bindCalls[2].pressedEventName).toBe("video/toggleFullscreen");

				gmtlIisRestoreGlobals(snap);
			});

			test("when input has no keyPressed, still adds callable mappers", function()
			{
				var snap = gmtlIisSnapshotGlobals();

				var input =
				{
					addCalls : [],

					addSignal : function(signalName, mapperFn)
					{
						var n = array_length(self.addCalls);
						self.addCalls[n] =
						{
							signalName : signalName,
							mapperFn : mapperFn
						};
					}
				};

				var bus =
				{
					emit : function(eventName, payload, sender) { return 1; },
					on : function(eventName, handler, ctx) { return function() { }; }
				};

				var ok = initInputInSystems(input, bus);

				expect(ok).toBeTruthy();
				expect(array_length(input.addCalls)).toBe(3);
				expect(is_callable(input.addCalls[0].mapperFn)).toBeTruthy();
				expect(is_callable(input.addCalls[1].mapperFn)).toBeTruthy();
				expect(is_callable(input.addCalls[2].mapperFn)).toBeTruthy();

				gmtlIisRestoreGlobals(snap);
			});

			test("pause mapper reads raw.keyPressed when available", function()
			{
				var snap = gmtlIisSnapshotGlobals();

				var input =
				{
					addCalls : [],

					addSignal : function(signalName, mapperFn)
					{
						var n = array_length(self.addCalls);
						self.addCalls[n] =
						{
							signalName : signalName,
							mapperFn : mapperFn
						};
					}
				};

				var ok = initInputInSystems(input, 0);
				expect(ok).toBeTruthy();
				expect(array_length(input.addCalls)).toBe(3);

				var mapper = input.addCalls[0].mapperFn;

				var rawFrame =
				{
					keyPressed : array_create(256, false)
				};
				rawFrame.keyPressed[vk_escape] = true;

				expect(mapper(rawFrame)).toBe(1);

				gmtlIisRestoreGlobals(snap);
			});

			test("uses global.events when events arg invalid", function()
			{
				var snap = gmtlIisSnapshotGlobals();

				var bus =
				{
					emit : function(eventName, payload, sender) { return 1; },
					on : function(eventName, handler, ctx) { return function() { }; }
				};

				global.events = bus;

				var input =
				{
					bindCalls : [],
					setBusCalls : [],
					eventBus : undefined,

					addSignal : function(signalName, mapperFn) { },

					setEventBus : function(b)
					{
						var n = array_length(self.setBusCalls);
						self.setBusCalls[n] = b;
						self.eventBus = b;
					},

					bindSignal : function(signalName, pressedEventName, releasedEventName, changedEventName)
					{
						var n = array_length(self.bindCalls);
						self.bindCalls[n] =
						{
							signalName : signalName,
							pressedEventName : pressedEventName
						};
					}
				};

				var ok = initInputInSystems(input, 0);

				expect(ok).toBeTruthy();
				expect(input.eventBus).toBe(bus);
				expect(array_length(input.bindCalls)).toBe(3);

				gmtlIisRestoreGlobals(snap);
			});
		});
	});
}
