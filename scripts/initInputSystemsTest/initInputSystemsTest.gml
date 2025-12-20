function gmtlInitInputInSystemsTests_safe3()
{
	suite(function()
	{
		section("initInputInSystems_safe3", function()
		{
			test("returns false when input invalid and no global.input", function()
			{
				global.input = undefined;
				global.events = undefined;
				global.eventBus = undefined;

				var bus =
				{
					emit : function(eventName, payload, sender) { return 1; },
					on : function(eventName, handler, ctx) { return function() { }; }
				};

				var ok = initInputInSystems(undefined, bus);
				expect(ok).toBeFalsy();
			});

			test("falls back to global.input when input arg invalid", function()
			{
				global.events = undefined;
				global.eventBus = undefined;

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
				expect(array_length(global.input.addCalls)).toBe(2);
			});

			test("when bus valid, sets bus and binds pause/recenter", function()
			{
				global.events = undefined;
				global.eventBus = undefined;

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
				expect(array_length(input.addCalls)).toBe(2);

				expect(array_length(input.setBusCalls)).toBe(1);
				expect(input.eventBus).toBe(bus);

				expect(array_length(input.bindCalls)).toBe(2);
				expect(input.bindCalls[0].signalName).toBe("pause");
				expect(input.bindCalls[0].pressedEventName).toBe("game/pause");
				expect(input.bindCalls[1].signalName).toBe("recenter");
				expect(input.bindCalls[1].pressedEventName).toBe("camera/recenter");
			});

			test("uses global.events when events arg invalid", function()
			{
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
				expect(array_length(input.bindCalls)).toBe(2);
			});
		});
	});
}
