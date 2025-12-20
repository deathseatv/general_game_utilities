function AudioManager() constructor
{
	eventBus = undefined;

	masterVolume = 1.0;

	busVolumes =
	{
		music : 1.0,
		sfx : 1.0,
		ui : 1.0
	};

	busSounds =
	{
		music : [],
		sfx : [],
		ui : []
	};

	currentMusicSound = noone;

	clamp01 = function(v)
	{
		if(v < 0) { return 0; }
		if(v > 1) { return 1; }
		return v;
	};

	getBusVolume = function(busName)
	{
		if(is_undefined(busName) || busName == "")
		{
			return 1.0;
		}

		if(!variable_struct_exists(busVolumes, busName))
		{
			return 1.0;
		}

		return busVolumes[$ busName];
	};

	setMasterVolume = function(v)
	{
		masterVolume = clamp01(v);
		audio_master_gain(masterVolume);
		applyBusGains(0);
	};

	setBusVolume = function(busName, v, fadeMs)
	{
		if(is_undefined(busName) || busName == "")
		{
			return;
		}

		if(!variable_struct_exists(busVolumes, busName))
		{
			return;
		}

		var fade = 0;
		if(argument_count >= 3 && is_real(fadeMs))
		{
			fade = max(0, fadeMs);
		}

		busVolumes[$ busName] = clamp01(v);
		applyBusGains(fade);
	};

	registerSound = function(soundId, busName)
	{
		if(is_undefined(soundId) || soundId == noone)
		{
			return;
		}

		if(is_undefined(busName) || busName == "")
		{
			return;
		}

		if(!variable_struct_exists(busSounds, busName))
		{
			return;
		}

		var list = busSounds[$ busName];
		var n = array_length(list);

		for(var i = 0; i < n; i += 1)
		{
			if(list[i] == soundId)
			{
				return;
			}
		}

		list[n] = soundId;
		busSounds[$ busName] = list;

		var gain = masterVolume * busVolumes[$ busName];
		audio_sound_gain(soundId, gain, 0);
	};

	applyBusGains = function(fadeMs)
	{
		var fade = 0;
		if(argument_count >= 1 && is_real(fadeMs))
		{
			fade = max(0, fadeMs);
		}

		var busNames = variable_struct_get_names(busSounds);
		var busCount = array_length(busNames);

		for(var b = 0; b < busCount; b += 1)
		{
			var busName = busNames[b];
			var gain = masterVolume * busVolumes[$ busName];

			var list = busSounds[$ busName];
			var n = array_length(list);

			for(var i = 0; i < n; i += 1)
			{
				audio_sound_gain(list[i], gain, fade);
			}
		}
	};

	playSfx = function(soundId, priority, loop)
	{
		var prio = 0;
		var lp = false;

		if(argument_count >= 2 && is_real(priority))
		{
			prio = priority;
		}

		if(argument_count >= 3)
		{
			lp = loop;
		}

		registerSound(soundId, "sfx");

		if(is_undefined(soundId) || soundId == noone)
		{
			return noone;
		}

		return audio_play_sound(soundId, prio, lp);
	};

	playUi = function(soundId, priority)
	{
		var prio = 0;

		if(argument_count >= 2 && is_real(priority))
		{
			prio = priority;
		}

		registerSound(soundId, "ui");

		if(is_undefined(soundId) || soundId == noone)
		{
			return noone;
		}

		return audio_play_sound(soundId, prio, false);
	};

	playMusic = function(soundId, priority, loop)
	{
		var prio = 0;
		var lp = true;

		if(argument_count >= 2 && is_real(priority))
		{
			prio = priority;
		}

		if(argument_count >= 3)
		{
			lp = loop;
		}

		registerSound(soundId, "music");

		if(is_undefined(soundId) || soundId == noone)
		{
			return noone;
		}

		if(currentMusicSound != noone && currentMusicSound != soundId)
		{
			audio_stop_sound(currentMusicSound);
		}

		currentMusicSound = soundId;
		return audio_play_sound(soundId, prio, lp);
	};

	stopMusic = function()
	{
		if(currentMusicSound == noone)
		{
			return;
		}

		audio_stop_sound(currentMusicSound);
		currentMusicSound = noone;
	};

	stopAll = function()
	{
		audio_stop_all();
		currentMusicSound = noone;
	};

	// Event handlers
	onPlaySfx = function(payload, eventName, sender)
	{
		if(!is_struct(payload) || !variable_struct_exists(payload, "sound"))
		{
			return;
		}

		var prio = variable_struct_exists(payload, "priority") ? payload.priority : 0;
		var loop = variable_struct_exists(payload, "loop") ? payload.loop : false;

		playSfx(payload.sound, prio, loop);
	};

	onPlayUi = function(payload, eventName, sender)
	{
		if(!is_struct(payload) || !variable_struct_exists(payload, "sound"))
		{
			return;
		}

		var prio = variable_struct_exists(payload, "priority") ? payload.priority : 0;

		playUi(payload.sound, prio);
	};

	onPlayMusic = function(payload, eventName, sender)
	{
		if(!is_struct(payload) || !variable_struct_exists(payload, "sound"))
		{
			return;
		}

		var prio = variable_struct_exists(payload, "priority") ? payload.priority : 0;
		var loop = variable_struct_exists(payload, "loop") ? payload.loop : true;

		playMusic(payload.sound, prio, loop);
	};

	onStopMusic = function(payload, eventName, sender)
	{
		stopMusic();
	};

	onSetVolume = function(payload, eventName, sender)
	{
		if(!is_struct(payload))
		{
			return;
		}

		if(variable_struct_exists(payload, "master"))
		{
			setMasterVolume(payload.master);
		}

		if(variable_struct_exists(payload, "music"))
		{
			setBusVolume("music", payload.music, 0);
		}

		if(variable_struct_exists(payload, "sfx"))
		{
			setBusVolume("sfx", payload.sfx, 0);
		}

		if(variable_struct_exists(payload, "ui"))
		{
			setBusVolume("ui", payload.ui, 0);
		}
	};

	init = function(bus)
	{
		eventBus = bus;

		if(is_undefined(eventBus))
		{
			return;
		}

		eventBus.on("audio/playSfx", method(self, self.onPlaySfx));
		eventBus.on("audio/playUi", method(self, self.onPlayUi));
		eventBus.on("audio/playMusic", method(self, self.onPlayMusic));
		eventBus.on("audio/stopMusic", method(self, self.onStopMusic));
		eventBus.on("audio/setVolume", method(self, self.onSetVolume));
	};
}