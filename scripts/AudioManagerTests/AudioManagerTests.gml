function gmtlAudioManagerMakeCallRecorder()
{
	var rec =
	{
		calls : [],

		add : function(a0, a1, a2, a3)
		{
			var entry =
			{
				a0 : a0,
				a1 : a1,
				a2 : a2,
				a3 : a3
			};

			var n = array_length(self.calls);
			self.calls[n] = entry;
		}
	};

	rec.addBound = method(rec, rec.add);

	return rec;
}

function gmtlAudioManagerMakeApplyBusGainsRecorder()
{
	var rec =
	{
		calls : [],

		run : function(fadeMs)
		{
			var entry =
			{
				fadeMs : fadeMs
			};

			var n = array_length(self.calls);
			self.calls[n] = entry;
		}
	};

	rec.bound = method(rec, rec.run);

	return rec;
}

function gmtlAudioManagerMakeSetMasterRecorder()
{
	var rec =
	{
		calls : [],

		run : function(v)
		{
			var entry =
			{
				v : v
			};

			var n = array_length(self.calls);
			self.calls[n] = entry;
		}
	};

	rec.bound = method(rec, rec.run);

	return rec;
}

function gmtlAudioManagerMakeSetBusRecorder()
{
	var rec =
	{
		calls : [],

		run : function(busName, v, fadeMs)
		{
			var entry =
			{
				busName : busName,
				v : v,
				fadeMs : fadeMs
			};

			var n = array_length(self.calls);
			self.calls[n] = entry;
		}
	};

	rec.bound = method(rec, rec.run);

	return rec;
}

function gmtlAudioManagerMakePlayRecorder()
{
	var rec =
	{
		calls : [],

		run : function(soundId, priority, loop)
		{
			var entry =
			{
				soundId : soundId,
				priority : priority,
				loop : loop
			};

			var n = array_length(self.calls);
			self.calls[n] = entry;
		}
	};

	rec.bound = method(rec, rec.run);

	return rec;
}

function gmtlAudioManagerMakeStopMusicStub(callRec)
{
	var token =
	{
		callRec : callRec,

		run : function()
		{
			self.callRec.addBound("stopMusic", 0, 0, 0);
		}
	};

	return method(token, token.run);
}

function gmtlAudioManagerMakeOnSetVolumeStub(callRec)
{
	var token =
	{
		callRec : callRec,

		run : function(payload, eventName, sender)
		{
			self.callRec.addBound(payload, eventName, sender, 0);
		}
	};

	return method(token, token.run);
}

function gmtlAudioManagerTests()
{
	suite(function()
	{
		section("AudioManager", function()
		{
			test("constructs with default bus volumes + registries", function()
			{
				var am = new AudioManager();

				expect(am.masterVolume).toBe(1.0);

				expect(variable_struct_exists(am.busVolumes, "music")).toBeTruthy();
				expect(variable_struct_exists(am.busVolumes, "sfx")).toBeTruthy();
				expect(variable_struct_exists(am.busVolumes, "ui")).toBeTruthy();

				expect(am.busVolumes.music).toBe(1.0);
				expect(am.busVolumes.sfx).toBe(1.0);
				expect(am.busVolumes.ui).toBe(1.0);

				expect(variable_struct_exists(am.busSounds, "music")).toBeTruthy();
				expect(variable_struct_exists(am.busSounds, "sfx")).toBeTruthy();
				expect(variable_struct_exists(am.busSounds, "ui")).toBeTruthy();

				expect(is_array(am.busSounds.music)).toBeTruthy();
				expect(is_array(am.busSounds.sfx)).toBeTruthy();
				expect(is_array(am.busSounds.ui)).toBeTruthy();

				expect(am.currentMusicSound).toBe(noone);
			});

			test("clamp01 clamps to [0, 1]", function()
			{
				var am = new AudioManager();

				expect(am.clamp01(-5)).toBe(0);
				expect(am.clamp01(0)).toBe(0);
				expect(am.clamp01(0.5)).toBe(0.5);
				expect(am.clamp01(1)).toBe(1);
				expect(am.clamp01(999)).toBe(1);
			});

			test("getBusVolume returns 1 for invalid/unknown, otherwise returns bus value", function()
			{
				var am = new AudioManager();

				expect(am.getBusVolume("")).toBe(1.0);
				expect(am.getBusVolume("nope")).toBe(1.0);

				am.busVolumes.music = 0.25;
				expect(am.getBusVolume("music")).toBe(0.25);
			});

			test("setBusVolume updates busVolumes and calls applyBusGains with fade", function()
			{
				var am = new AudioManager();
				var gains = gmtlAudioManagerMakeApplyBusGainsRecorder();

				am.applyBusGains = gains.bound;

				am.setBusVolume("sfx", 0.4);
				expect(am.busVolumes.sfx).toBe(0.4);
				expect(array_length(gains.calls)).toBe(1);
				expect(gains.calls[0].fadeMs).toBe(0);

				am.setBusVolume("sfx", 0.9, 250);
				expect(am.busVolumes.sfx).toBe(0.9);
				expect(array_length(gains.calls)).toBe(2);
				expect(gains.calls[1].fadeMs).toBe(250);

				am.setBusVolume("nope", 0.1, 999);
				expect(array_length(gains.calls)).toBe(2);
			});

			test("onPlaySfx forwards payload to playSfx with defaults", function()
			{
				var am = new AudioManager();
				var rec = gmtlAudioManagerMakePlayRecorder();

				am.playSfx = rec.bound;

				am.onPlaySfx({ sound : 123 }, "audio/playSfx", noone);

				expect(array_length(rec.calls)).toBe(1);
				expect(rec.calls[0].soundId).toBe(123);
				expect(rec.calls[0].priority).toBe(0);
				expect(rec.calls[0].loop).toBe(false);

				am.onPlaySfx({ sound : 5, priority : 9, loop : true }, "audio/playSfx", noone);

				expect(array_length(rec.calls)).toBe(2);
				expect(rec.calls[1].soundId).toBe(5);
				expect(rec.calls[1].priority).toBe(9);
				expect(rec.calls[1].loop).toBe(true);
			});

			test("onPlayUi forwards payload to playUi with defaults", function()
			{
				var am = new AudioManager();
				var rec = gmtlAudioManagerMakePlayRecorder();

				am.playUi = rec.bound;

				am.onPlayUi({ sound : 7 }, "audio/playUi", noone);

				expect(array_length(rec.calls)).toBe(1);
				expect(rec.calls[0].soundId).toBe(7);
				expect(rec.calls[0].priority).toBe(0);

				am.onPlayUi({ sound : 8, priority : 3 }, "audio/playUi", noone);

				expect(array_length(rec.calls)).toBe(2);
				expect(rec.calls[1].soundId).toBe(8);
				expect(rec.calls[1].priority).toBe(3);
			});

			test("onPlayMusic forwards payload to playMusic with defaults", function()
			{
				var am = new AudioManager();
				var rec = gmtlAudioManagerMakePlayRecorder();

				am.playMusic = rec.bound;

				am.onPlayMusic({ sound : 11 }, "audio/playMusic", noone);

				expect(array_length(rec.calls)).toBe(1);
				expect(rec.calls[0].soundId).toBe(11);
				expect(rec.calls[0].priority).toBe(0);
				expect(rec.calls[0].loop).toBe(true);

				am.onPlayMusic({ sound : 12, priority : 2, loop : false }, "audio/playMusic", noone);

				expect(array_length(rec.calls)).toBe(2);
				expect(rec.calls[1].soundId).toBe(12);
				expect(rec.calls[1].priority).toBe(2);
				expect(rec.calls[1].loop).toBe(false);
			});

			test("onStopMusic calls stopMusic", function()
			{
				var am = new AudioManager();
				var rec = gmtlAudioManagerMakeCallRecorder();

				am.stopMusic = gmtlAudioManagerMakeStopMusicStub(rec);

				am.onStopMusic({ }, "audio/stopMusic", noone);

				expect(array_length(rec.calls)).toBe(1);
				expect(rec.calls[0].a0).toBe("stopMusic");
			});

			test("onSetVolume calls setMasterVolume and setBusVolume for provided fields", function()
			{
				var am = new AudioManager();

				var masterRec = gmtlAudioManagerMakeSetMasterRecorder();
				var busRec = gmtlAudioManagerMakeSetBusRecorder();

				am.setMasterVolume = masterRec.bound;
				am.setBusVolume = busRec.bound;

				am.onSetVolume({ master : 0.5, music : 0.2, sfx : 0.3 }, "audio/setVolume", noone);

				expect(array_length(masterRec.calls)).toBe(1);
				expect(masterRec.calls[0].v).toBe(0.5);

				expect(array_length(busRec.calls)).toBe(2);

				expect(busRec.calls[0].busName).toBe("music");
				expect(busRec.calls[0].v).toBe(0.2);
				expect(busRec.calls[0].fadeMs).toBe(0);

				expect(busRec.calls[1].busName).toBe("sfx");
				expect(busRec.calls[1].v).toBe(0.3);
				expect(busRec.calls[1].fadeMs).toBe(0);
			});

			test("init subscribes to EventBus and routes audio events", function()
			{
				var bus = new EventBus();
				var am = new AudioManager();

				var sfxRec = gmtlAudioManagerMakePlayRecorder();
				var uiRec = gmtlAudioManagerMakePlayRecorder();
				var musicRec = gmtlAudioManagerMakePlayRecorder();

				var stopRec = gmtlAudioManagerMakeCallRecorder();

				var masterRec = gmtlAudioManagerMakeSetMasterRecorder();
				var busRec = gmtlAudioManagerMakeSetBusRecorder();

				am.playSfx = sfxRec.bound;
				am.playUi = uiRec.bound;
				am.playMusic = musicRec.bound;

				am.stopMusic = gmtlAudioManagerMakeStopMusicStub(stopRec);

				am.setMasterVolume = masterRec.bound;
				am.setBusVolume = busRec.bound;

				am.init(bus);

				bus.emit("audio/playSfx", { sound : 1, priority : 9, loop : true }, noone);
				expect(array_length(sfxRec.calls)).toBe(1);
				expect(sfxRec.calls[0].soundId).toBe(1);

				bus.emit("audio/playUi", { sound : 2, priority : 5 }, noone);
				expect(array_length(uiRec.calls)).toBe(1);
				expect(uiRec.calls[0].soundId).toBe(2);

				bus.emit("audio/playMusic", { sound : 3 }, noone);
				expect(array_length(musicRec.calls)).toBe(1);
				expect(musicRec.calls[0].soundId).toBe(3);

				bus.emit("audio/stopMusic", { }, noone);
				expect(array_length(stopRec.calls)).toBe(1);
				expect(stopRec.calls[0].a0).toBe("stopMusic");

				bus.emit("audio/setVolume", { master : 0.1, sfx : 0.2 }, noone);

				expect(array_length(masterRec.calls)).toBe(1);
				expect(masterRec.calls[0].v).toBe(0.1);

				expect(array_length(busRec.calls)).toBe(1);
				expect(busRec.calls[0].busName).toBe("sfx");
				expect(busRec.calls[0].v).toBe(0.2);
				expect(busRec.calls[0].fadeMs).toBe(0);
			});
		});
	});
}
