function gmtlInputManagerMakeSpyMapper()
{
	var spy =
	{
		count : 0,
		lastRaw : undefined,
		nextValue : 0,

		map : function(raw)
		{
			count += 1;
			lastRaw = raw;
			return nextValue;
		}
	};

	spy.bound = method(spy, spy.map);
	return spy;
}

function gmtlInputManagerMakeCallOrderRecorder()
{
	var rec =
	{
		order : [],

		clearConsumed : function()
		{
			array_push(self.order, "clearConsumed");
		},

		captureRaw : function()
		{
			array_push(self.order, "captureRaw");
		},

		updateSignals : function()
		{
			array_push(self.order, "updateSignals");
		},

		dispatchEvents : function()
		{
			array_push(self.order, "dispatchEvents");
		}
	};

	rec.clearConsumedBound = method(rec, rec.clearConsumed);

	rec.captureRawBound = method(rec, rec.captureRaw);
	rec.updateSignalsBound = method(rec, rec.updateSignals);
	rec.dispatchEventsBound = method(rec, rec.dispatchEvents);

	return rec;
}

function gmtlInputManagerMakeFakeEventBus()
{
	return
	{
		calls : [],

		emit : function(eventName, payload, sender)
		{
			var entry =
			{
				eventName : eventName,
				payload : payload,
				sender : sender
			};

			array_push(self.calls, entry);
			return 1;
		}
	};
}

function gmtlInputManagerMakeCaptureRawStub(input, frames)
{
	var token =
	{
		input : input,
		frames : frames,
		frameIndex : 0,

		capture : function()
		{
			var im = self.input;

			var idx = self.frameIndex;
			if(idx >= array_length(self.frames))
			{
				idx = array_length(self.frames) - 1;
			}

			var f = self.frames[idx];

			var keyCount = array_length(im.watchedKeys);
			for(var i = 0; i < keyCount; i += 1)
			{
				var key = im.watchedKeys[i];

				im.raw.keyDown[key] = false;
				im.raw.keyPressed[key] = false;
				im.raw.keyReleased[key] = false;
			}

			var downCount = array_length(f.keyDown);
			for(var d = 0; d < downCount; d += 1)
			{
				var kDown = f.keyDown[d];
				im.raw.keyDown[kDown] = true;
			}

			var pressCount = array_length(f.keyPressed);
			for(var p = 0; p < pressCount; p += 1)
			{
				var kPress = f.keyPressed[p];
				im.raw.keyPressed[kPress] = true;
			}

			var relCount = array_length(f.keyReleased);
			for(var r = 0; r < relCount; r += 1)
			{
				var kRel = f.keyReleased[r];
				im.raw.keyReleased[kRel] = true;
			}

			var btnCount = array_length(im.watchedMouseButtons);
			for(var j = 0; j < btnCount; j += 1)
			{
				var btn = im.watchedMouseButtons[j];

				im.raw.mouseDown[btn] = false;
				im.raw.mousePressed[btn] = false;
				im.raw.mouseReleased[btn] = false;
			}

			var mDownCount = array_length(f.mouseDown);
			for(var md = 0; md < mDownCount; md += 1)
			{
				var bDown = f.mouseDown[md];
				im.raw.mouseDown[bDown] = true;
			}

			var mPressCount = array_length(f.mousePressed);
			for(var mp = 0; mp < mPressCount; mp += 1)
			{
				var bPress = f.mousePressed[mp];
				im.raw.mousePressed[bPress] = true;
			}

			var mRelCount = array_length(f.mouseReleased);
			for(var mr = 0; mr < mRelCount; mr += 1)
			{
				var bRel = f.mouseReleased[mr];
				im.raw.mouseReleased[bRel] = true;
			}

			self.frameIndex += 1;
		}
	};

	return method(token, token.capture);
}

function gmtlInputManagerTests()
{
	suite(function()
	{
		section("InputManager", function()
		{
			test("constructs with expected empty state", function()
			{
				var im = new InputManager();

				expect(is_struct(im.raw)).toBeTruthy();
				expect(is_array(im.raw.keyDown)).toBeTruthy();
				expect(is_array(im.raw.keyPressed)).toBeTruthy();
				expect(is_array(im.raw.keyReleased)).toBeTruthy();
				expect(is_array(im.raw.mouseDown)).toBeTruthy();
				expect(is_array(im.raw.mousePressed)).toBeTruthy();
				expect(is_array(im.raw.mouseReleased)).toBeTruthy();

				expect(is_struct(im.signalDefs)).toBeTruthy();
				expect(is_struct(im.signals)).toBeTruthy();
				expect(is_struct(im.bindings)).toBeTruthy();

			expect(is_struct(im.consumedSignals)).toBeTruthy();
			expect(im.consumeAllSignals).toBeFalsy();

				expect(is_array(im.watchedKeys)).toBeTruthy();
				expect(is_struct(im.watchedKeysSet)).toBeTruthy();
				expect(is_array(im.watchedMouseButtons)).toBeTruthy();
				expect(is_struct(im.watchedMouseButtonsSet)).toBeTruthy();

				expect(array_length(im.signalNames)).toBe(0);
				expect(im.signalNamesDirty).toBeTruthy();
			});

			test("keyPressed/keyDown/keyReleased register watched keys without duplicates", function()
			{
				var im = new InputManager();

				var m1 = im.keyPressed(vk_escape);
				var m2 = im.keyDown(vk_escape);
				var m3 = im.keyReleased(vk_escape);

				expect(is_callable(m1)).toBeTruthy();
				expect(is_callable(m2)).toBeTruthy();
				expect(is_callable(m3)).toBeTruthy();

				expect(array_length(im.watchedKeys)).toBe(1);
				expect(im.watchedKeys[0]).toBe(vk_escape);

				var m4 = im.keyPressed(vk_escape);
				expect(is_callable(m4)).toBeTruthy();
				expect(array_length(im.watchedKeys)).toBe(1);
			});

			test("mousePressed/mouseDown/mouseReleased register watched buttons without duplicates", function()
			{
				var im = new InputManager();

				var m1 = im.mousePressed(mb_left);
				var m2 = im.mouseDown(mb_left);
				var m3 = im.mouseReleased(mb_left);

				expect(is_callable(m1)).toBeTruthy();
				expect(is_callable(m2)).toBeTruthy();
				expect(is_callable(m3)).toBeTruthy();

				expect(array_length(im.watchedMouseButtons)).toBe(1);
				expect(im.watchedMouseButtons[0]).toBe(mb_left);

				var m4 = im.mousePressed(mb_left);
				expect(is_callable(m4)).toBeTruthy();
				expect(array_length(im.watchedMouseButtons)).toBe(1);
			});

			test("addSignal registers definition and initializes signal state", function()
			{
				var im = new InputManager();
				var mapper = function(raw) { return 0; };

				im.addSignal("jump", mapper);

				expect(variable_struct_exists(im.signalDefs, "jump")).toBeTruthy();
				expect(variable_struct_exists(im.signals, "jump")).toBeTruthy();

				var s = im.signals[$ "jump"];
				expect(s.value).toBe(0);
				expect(s.prevValue).toBe(0);
				expect(s.pressed).toBeFalsy();
				expect(s.released).toBeFalsy();

				expect(im.signalNamesDirty).toBeTruthy();
			});

			test("addSignal ignores invalid name or mapper", function()
			{
				var im = new InputManager();

				im.addSignal("", function(raw) { return 1; });
				expect(variable_struct_exists(im.signalDefs, "")).toBeFalsy();

				im.addSignal("a", undefined);
				expect(variable_struct_exists(im.signalDefs, "a")).toBeFalsy();
			});

			test("removeSignal removes from defs/signals/bindings", function()
			{
				var im = new InputManager();
				var mapper = function(raw) { return 0; };

				im.addSignal("jump", mapper);
				im.bindSignal("jump", "x", "y", "z");

				expect(variable_struct_exists(im.bindings, "jump")).toBeTruthy();

				im.removeSignal("jump");

				expect(variable_struct_exists(im.signalDefs, "jump")).toBeFalsy();
				expect(variable_struct_exists(im.signals, "jump")).toBeFalsy();
				expect(variable_struct_exists(im.bindings, "jump")).toBeFalsy();
				expect(im.signalNamesDirty).toBeTruthy();
			});

			test("updateSignals rebuilds signalNames when dirty", function()
			{
				var im = new InputManager();
				im.signalNamesDirty = false;

				im.addSignal("a", function(raw) { return 0; });
				im.addSignal("b", function(raw) { return 0; });

				expect(im.signalNamesDirty).toBeTruthy();

				im.updateSignals();

				expect(im.signalNamesDirty).toBeFalsy();
				expect(array_length(im.signalNames)).toBe(2);
				expect(array_contains(im.signalNames, "a")).toBeTruthy();
				expect(array_contains(im.signalNames, "b")).toBeTruthy();
			});

			test("updateSignals calls mapper with raw and updates value", function()
			{
				var im = new InputManager();
				var spy = gmtlInputManagerMakeSpyMapper();

				im.addSignal("a", spy.bound);
				im.raw.foo = 99;

				spy.nextValue = 7;
				im.updateSignals();

				expect(spy.count).toBe(1);
				expect(spy.lastRaw.foo).toBe(99);

				var s = im.signals[$ "a"];
				expect(s.value).toBe(7);
				expect(s.pressed).toBeTruthy();
				expect(s.released).toBeFalsy();
			});

			test("pressed/released transitions via keyDown mapper over frames", function()
			{
				var im = new InputManager();

				im.addSignal("hold", im.keyDown(vk_space));

				var frames =
				[
					{ keyDown : [], keyPressed : [], keyReleased : [], mouseDown : [], mousePressed : [], mouseReleased : [] },
					{ keyDown : [vk_space], keyPressed : [], keyReleased : [], mouseDown : [], mousePressed : [], mouseReleased : [] },
					{ keyDown : [vk_space], keyPressed : [], keyReleased : [], mouseDown : [], mousePressed : [], mouseReleased : [] },
					{ keyDown : [], keyPressed : [], keyReleased : [], mouseDown : [], mousePressed : [], mouseReleased : [] }
				];

				im.captureRaw = gmtlInputManagerMakeCaptureRawStub(im, frames);

				im.update();
				var s0 = im.signals[$ "hold"];
				expect(s0.value).toBe(0);
				expect(s0.pressed).toBeFalsy();
				expect(s0.released).toBeFalsy();

				im.update();
				var s1 = im.signals[$ "hold"];
				expect(s1.value).toBe(1);
				expect(s1.pressed).toBeTruthy();
				expect(s1.released).toBeFalsy();

				im.update();
				var s2 = im.signals[$ "hold"];
				expect(s2.value).toBe(1);
				expect(s2.pressed).toBeFalsy();
				expect(s2.released).toBeFalsy();

				im.update();
				var s3 = im.signals[$ "hold"];
				expect(s3.value).toBe(0);
				expect(s3.pressed).toBeFalsy();
				expect(s3.released).toBeTruthy();
			});

			test("dispatchEvents emits bound pressed event once for keyPressed signal", function()
			{
				var im = new InputManager();
				var bus = gmtlInputManagerMakeFakeEventBus();

				im.setEventBus(bus);

				im.addSignal("menu", im.keyPressed(vk_escape));
				im.bindSignal("menu", "menu/open", undefined, undefined);

				var frames =
				[
					{ keyDown : [], keyPressed : [vk_escape], keyReleased : [], mouseDown : [], mousePressed : [], mouseReleased : [] },
					{ keyDown : [], keyPressed : [], keyReleased : [], mouseDown : [], mousePressed : [], mouseReleased : [] }
				];

				im.captureRaw = gmtlInputManagerMakeCaptureRawStub(im, frames);

				im.update();
				im.update();

				expect(array_length(bus.calls)).toBe(1);
				expect(bus.calls[0].eventName).toBe("menu/open");
				expect(bus.calls[0].payload.signal).toBe("menu");
				expect(bus.calls[0].payload.value).toBe(1);
			});

			test("pause falls back to game/pause when flow/togglePause has no listeners", function()
			{
				var im = new InputManager();
				var bus = new EventBus();

				im.setEventBus(bus);
				im.addSignal("pause", im.keyPressed(vk_escape));
				im.bindSignal("pause", "flow/togglePause", undefined, undefined);

				var token =
				{
					count : 0,
					hit : function(payload, eventName, sender)
					{
						self.count += 1;
					}
				};

				bus.on("game/pause", method(token, token.hit));

				var frames =
				[
					{ keyDown : [], keyPressed : [vk_escape], keyReleased : [], mouseDown : [], mousePressed : [], mouseReleased : [] },
					{ keyDown : [], keyPressed : [], keyReleased : [], mouseDown : [], mousePressed : [], mouseReleased : [] }
				];

				im.captureRaw = gmtlInputManagerMakeCaptureRawStub(im, frames);

				im.update();
				im.update();

				expect(token.count).toBe(1);
			});

				test("pause does not fall back when flow/togglePause is handled", function()
			{
				var im = new InputManager();
				var bus = new EventBus();

				im.setEventBus(bus);
				im.addSignal("pause", im.keyPressed(vk_escape));
				im.bindSignal("pause", "flow/togglePause", undefined, undefined);

					var pauseToken =
					{
						count : 0,
						hit : function(payload, eventName, sender)
						{
							self.count += 1;
						}
					};

					var flowToken =
					{
						count : 0,
						hit : function(payload, eventName, sender)
						{
							self.count += 1;
						}
					};

				bus.on("game/pause", method(pauseToken, pauseToken.hit));
				bus.on("flow/togglePause", method(flowToken, flowToken.hit));

				var frames =
				[
					{ keyDown : [], keyPressed : [vk_escape], keyReleased : [], mouseDown : [], mousePressed : [], mouseReleased : [] },
					{ keyDown : [], keyPressed : [], keyReleased : [], mouseDown : [], mousePressed : [], mouseReleased : [] }
				];

				im.captureRaw = gmtlInputManagerMakeCaptureRawStub(im, frames);

				im.update();
				im.update();

				expect(flowToken.count).toBe(1);
				expect(pauseToken.count).toBe(0);
			});

			test("dispatchEvents skips consumed signals", function()
			{
				var im = new InputManager();
				var bus = gmtlInputManagerMakeFakeEventBus();

				im.setEventBus(bus);

				im.addSignal("pause", im.keyPressed(vk_escape));
				im.bindSignal("pause", "game/pause", undefined, undefined);

				var frames =
				[
					{ keyDown : [], keyPressed : [vk_escape], keyReleased : [], mouseDown : [], mousePressed : [], mouseReleased : [] }
				];

				im.captureRaw = gmtlInputManagerMakeCaptureRawStub(im, frames);
				im.clearConsumed();
				im.beginFrame();
				im.consume("pause");
				im.dispatchEvents();

				expect(array_length(bus.calls)).toBe(0);
			});

			test("consumeAll prevents any emits", function()
			{
				var im = new InputManager();
				var bus = gmtlInputManagerMakeFakeEventBus();

				im.setEventBus(bus);

				im.addSignal("pause", im.keyPressed(vk_escape));
				im.bindSignal("pause", "game/pause", undefined, undefined);

				var frames =
				[
					{ keyDown : [], keyPressed : [vk_escape], keyReleased : [], mouseDown : [], mousePressed : [], mouseReleased : [] }
				];

				im.captureRaw = gmtlInputManagerMakeCaptureRawStub(im, frames);
				im.clearConsumed();
				im.beginFrame();
				im.consumeAll();
				im.dispatchEvents();

				expect(array_length(bus.calls)).toBe(0);
			});

			test("dispatchEvents emits changed event with prevValue/value", function()
			{
				var im = new InputManager();
				var bus = gmtlInputManagerMakeFakeEventBus();

				im.setEventBus(bus);

				im.addSignal("hold", im.keyDown(vk_space));
				im.bindSignal("hold", undefined, undefined, "input/holdChanged");

				var frames =
				[
					{ keyDown : [], keyPressed : [], keyReleased : [], mouseDown : [], mousePressed : [], mouseReleased : [] },
					{ keyDown : [vk_space], keyPressed : [], keyReleased : [], mouseDown : [], mousePressed : [], mouseReleased : [] },
					{ keyDown : [], keyPressed : [], keyReleased : [], mouseDown : [], mousePressed : [], mouseReleased : [] }
				];

				im.captureRaw = gmtlInputManagerMakeCaptureRawStub(im, frames);

				im.update();
				im.update();
				im.update();

				expect(array_length(bus.calls)).toBe(2);

				expect(bus.calls[0].eventName).toBe("input/holdChanged");
				expect(bus.calls[0].payload.prevValue).toBe(0);
				expect(bus.calls[0].payload.value).toBe(1);

				expect(bus.calls[1].eventName).toBe("input/holdChanged");
				expect(bus.calls[1].payload.prevValue).toBe(1);
				expect(bus.calls[1].payload.value).toBe(0);
			});

			test("multiple signals update independently", function()
			{
				var im = new InputManager();

				im.addSignal("a", im.keyDown(ord("A")));
				im.addSignal("b", im.keyDown(ord("B")));

				var frames =
				[
					{ keyDown : [ord("A")], keyPressed : [], keyReleased : [], mouseDown : [], mousePressed : [], mouseReleased : [] },
					{ keyDown : [ord("B")], keyPressed : [], keyReleased : [], mouseDown : [], mousePressed : [], mouseReleased : [] }
				];

				im.captureRaw = gmtlInputManagerMakeCaptureRawStub(im, frames);

				im.update();
				var sa1 = im.signals[$ "a"];
				var sb1 = im.signals[$ "b"];
				expect(sa1.pressed).toBeTruthy();
				expect(sb1.pressed).toBeFalsy();

				im.update();
				var sa2 = im.signals[$ "a"];
				var sb2 = im.signals[$ "b"];
				expect(sa2.released).toBeTruthy();
				expect(sb2.pressed).toBeTruthy();
			});

			test("update calls captureRaw then updateSignals then dispatchEvents", function()
			{
				var im = new InputManager();
				var rec = gmtlInputManagerMakeCallOrderRecorder();

				im.clearConsumed = rec.clearConsumedBound;
				im.captureRaw = rec.captureRawBound;
				im.updateSignals = rec.updateSignalsBound;
				im.dispatchEvents = rec.dispatchEventsBound;

				im.update();

				expect(array_length(rec.order)).toBe(4);
				expect(rec.order[0]).toBe("clearConsumed");
				expect(rec.order[1]).toBe("captureRaw");
				expect(rec.order[2]).toBe("updateSignals");
				expect(rec.order[3]).toBe("dispatchEvents");
			});

			test("updateSignals is safe when no signals exist", function()
			{
				var im = new InputManager();
				im.signalNamesDirty = false;
				im.signalNames = [];

				im.updateSignals();

				expect(true).toBeTruthy();
			});
		});
	});
}
