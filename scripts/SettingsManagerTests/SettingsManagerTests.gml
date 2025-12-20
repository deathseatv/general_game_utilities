function gmtlSettingsMakeEmitBus()
{
	return
	{
		emits : [],

		emit : function(eventName, payload, sender)
		{
			var entry =
			{
				eventName : eventName,
				payload : payload,
				sender : sender
			};

			var n = array_length(self.emits);
			self.emits[n] = entry;

			return 1;
		},

		on : function(eventName, handler, ctx)
		{
			return function() { };
		}
	};
}

function gmtlSettingsMakeApplyToken()
{
	var token =
	{
		calls : 0,

		run : function()
		{
			self.calls += 1;
		}
	};

	token.bound = method(token, token.run);
	return token;
}

function gmtlSettingsTests()
{
	suite(function()
	{
		section("SettingsManager", function()
		{
			test("constructs with defaults copied into values", function()
			{
				var sm = new SettingsManager();

				expect(sm.values.masterVolume).toBe(sm.defaults.masterVolume);
				expect(sm.values.musicVolume).toBe(sm.defaults.musicVolume);
				expect(sm.values.sfxVolume).toBe(sm.defaults.sfxVolume);
				expect(sm.values.uiVolume).toBe(sm.defaults.uiVolume);
			});

			test("get returns undefined for unknown key and value for known key", function()
			{
				var sm = new SettingsManager();

				expect(sm.get("nope")).toBeEqual(undefined);
				expect(sm.get("musicVolume")).toBe(1.0);
			});

			test("set rejects unknown keys and non-real volumes", function()
			{
				var sm = new SettingsManager();

				expect(sm.set("nope", 1)).toBeFalsy();
				expect(sm.set("musicVolume", "loud")).toBeFalsy();

				expect(sm.values.musicVolume).toBe(1.0);
			});

			test("set clamps volumes to [0, 1] and emits settings/changed only on change", function()
			{
				var sm = new SettingsManager();
				var bus = gmtlSettingsMakeEmitBus();

				sm.init(bus);

				var ok = sm.set("musicVolume", 2);
				expect(ok).toBeFalsy();
				expect(sm.values.musicVolume).toBe(1.0);
				expect(array_length(bus.emits)).toBe(0);

				ok = sm.set("musicVolume", 0.75);
				expect(ok).toBeTruthy();
				expect(sm.values.musicVolume).toBe(0.75);

				expect(array_length(bus.emits)).toBe(1);
				expect(bus.emits[0].eventName).toBe("settings/changed");
				expect(bus.emits[0].payload.key).toBe("musicVolume");
				expect(bus.emits[0].payload.prev).toBe(1.0);
				expect(bus.emits[0].payload.value).toBe(0.75);

				ok = sm.set("musicVolume", -5);
				expect(ok).toBeTruthy();
				expect(sm.values.musicVolume).toBe(0.0);

				expect(array_length(bus.emits)).toBe(2);
				expect(bus.emits[1].payload.prev).toBe(0.75);
				expect(bus.emits[1].payload.value).toBe(0.0);
			});

			test("set returns false when value does not change", function()
			{
				var sm = new SettingsManager();

				expect(sm.set("sfxVolume", 1.0)).toBeFalsy();
				expect(sm.values.sfxVolume).toBe(1.0);
			});

			test("apply emits audio/setVolume and settings/applied", function()
			{
				var sm = new SettingsManager();
				var bus = gmtlSettingsMakeEmitBus();

				sm.init(bus);

				sm.set("masterVolume", 0.5);
				sm.set("musicVolume", 0.4);
				sm.set("sfxVolume", 0.3);
				sm.set("uiVolume", 0.2);

				bus.emits = [];

				sm.apply();

				expect(array_length(bus.emits)).toBe(2);

				expect(bus.emits[0].eventName).toBe("audio/setVolume");
				expect(bus.emits[0].payload.master).toBe(0.5);
				expect(bus.emits[0].payload.music).toBe(0.4);
				expect(bus.emits[0].payload.sfx).toBe(0.3);
				expect(bus.emits[0].payload.ui).toBe(0.2);

				expect(bus.emits[1].eventName).toBe("settings/applied");
			});

			test("setMasterVolume/setMusicVolume/setSfxVolume/setUiVolume apply only on change", function()
			{
				var sm = new SettingsManager();
				var token = gmtlSettingsMakeApplyToken();

				sm.apply = token.bound;

				sm.setMasterVolume(1.0);
				expect(token.calls).toBe(0);

				sm.setMasterVolume(0.9);
				expect(token.calls).toBe(1);

				sm.setMusicVolume(0.8);
				expect(token.calls).toBe(2);

				sm.setSfxVolume(0.7);
				expect(token.calls).toBe(3);

				sm.setUiVolume(0.6);
				expect(token.calls).toBe(4);
			});

			test("resetDefaults sets values back to defaults and applies", function()
			{
				var sm = new SettingsManager();
				var token = gmtlSettingsMakeApplyToken();

				sm.apply = token.bound;

				sm.set("musicVolume", 0.25);
				expect(sm.values.musicVolume).toBe(0.25);

				sm.resetDefaults();

				expect(sm.values.masterVolume).toBe(1.0);
				expect(sm.values.musicVolume).toBe(1.0);
				expect(sm.values.sfxVolume).toBe(1.0);
				expect(sm.values.uiVolume).toBe(1.0);

				expect(token.calls).toBe(1);
			});

			test("onSettingsSet calls set, onSettingsApply calls apply, onSettingsReset calls resetDefaults", function()
			{
				var sm = new SettingsManager();
				var setOk = sm.set("musicVolume", 0.25);

				expect(setOk).toBeTruthy();
				expect(sm.values.musicVolume).toBe(0.25);

				var applyToken = gmtlSettingsMakeApplyToken();
				sm.apply = applyToken.bound;

				sm.onSettingsApply({ }, "settings/apply", noone);
				expect(applyToken.calls).toBe(1);

				sm.set("musicVolume", 0.4);
				expect(sm.values.musicVolume).toBe(0.4);

				sm.onSettingsReset({ }, "settings/reset", noone);
				expect(sm.values.musicVolume).toBe(1.0);

				sm.onSettingsSet({ key : "musicVolume", value : 0.33 }, "settings/set", noone);
				expect(sm.values.musicVolume).toBe(0.33);
			});

			test("init subscribes and settings/set routes into set()", function()
			{
				var bus = new EventBus();
				var sm = new SettingsManager();

				sm.init(bus);

				bus.emit("settings/set", { key : "sfxVolume", value : 0.22 }, noone);

				expect(sm.values.sfxVolume).toBe(0.22);
			});
		});
	});
}
