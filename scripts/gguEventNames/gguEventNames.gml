function gguEventNamesDefaults()
{
	return
	{
		videoToggleFullscreen : "video/toggleFullscreen",

		cameraRecenter : "camera/recenter",

		flowBoot : "flow/boot",
		flowStartGame : "flow/startGame",
		flowMainMenu : "flow/mainMenu",
		flowPause : "flow/pause",
		flowUnpause : "flow/unpause",
		flowQuit : "flow/quit",
		flowTogglePause : "flow/togglePause",

		gameStart : "game/start",
		gameMainMenu : "game/mainMenu",
		gamePause : "game/pause",
		gameUnpause : "game/unpause",

		menuShow : "menu/show",
		menuClose : "menu/close",

		sceneLoad : "scene/load",
		sceneWillLoad : "scene/willLoad",
		sceneDidLoad : "scene/didLoad",
		sceneNext : "scene/next",
		sceneReload : "scene/reload",

		settingsChanged : "settings/changed",
		settingsSet : "settings/set",
		settingsApply : "settings/apply",
		settingsReset : "settings/reset",
		settingsApplied : "settings/applied",

		audioPlayUi : "audio/playUi",
		audioPlaySfx : "audio/playSfx",
		audioPlayMusic : "audio/playMusic",
		audioStopMusic : "audio/stopMusic",
		audioSetVolume : "audio/setVolume",

		assetsRegister : "assets/register",
		assetsWarmup : "assets/warmup",
		assetsClearCache : "assets/clearCache",
		assetsUnloadDynamic : "assets/unloadDynamic",

		saveGameSave : "saveGame/save",
		saveGameLoad : "saveGame/load",
		saveGameDelete : "saveGame/delete",
		saveGameSetSlot : "saveGame/setSlot",
		saveGameSaved : "saveGame/saved",
		saveGameSaveFailed : "saveGame/saveFailed",
		saveGameLoaded : "saveGame/loaded",
		saveGameLoadFailed : "saveGame/loadFailed",

		stateChanged : "state/changed",
		pauseEntered : "pause/entered",
		pauseExited : "pause/exited",

		timePaused : "time/paused",
		timeScaleChanged : "time/scaleChanged",
		timeSetScale : "time/setScale",

		lifecycleBooted : "lifecycle/booted",
		gameplayEnter : "gameplay/enter",
		gameplayExit : "gameplay/exit"
	};
}

function gguEventNamesEnsure()
{
	var defaults = gguEventNamesDefaults();

	if(!variable_global_exists("eventNames") || !is_struct(global.eventNames))
	{
		global.eventNames = defaults;
		return global.eventNames;
	}

	var names = variable_struct_get_names(defaults);
	for(var i = 0; i < array_length(names); i += 1)
	{
		var k = names[i];
		if(!variable_struct_exists(global.eventNames, k))
		{
			global.eventNames[$ k] = defaults[$ k];
		}
	}

	return global.eventNames;
}

function gguEventName(key, fallback)
{
	gguEventNamesEnsure();

	var k = string(key);

	if(variable_struct_exists(global.eventNames, k))
	{
		var v = variable_struct_get(global.eventNames, k);
		return is_string(v) ? v : "";
	}

	var defaults = gguEventNamesDefaults();
	if(variable_struct_exists(defaults, k))
	{
		var v2 = variable_struct_get(defaults, k);
		return is_string(v2) ? v2 : "";
	}

	if(!is_undefined(fallback))
	{
		return string(fallback);
	}

	return "";
}



