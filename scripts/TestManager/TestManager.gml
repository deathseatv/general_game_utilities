function gmtlSnapshotGlobals(names)
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
		snap.exists[i] = variable_struct_exists(global, key);
		snap.values[i] = snap.exists[i] ? global[$ key] : undefined;
	}

	return snap;
}

function gmtlRestoreGlobals(snap)
{
	var n = array_length(snap.names);
	for(var i = 0; i < n; i += 1)
	{
		var key = snap.names[i];
		if(snap.exists[i])
		{
			global[$ key] = snap.values[i];
		}
		else if(variable_struct_exists(global, key))
		{
			variable_struct_remove(global, key);
		}
	}
}

function TestManager()
{
	// managers
	gmtlEventBusTests();
	gmtlInputManagerTests();
	gmtlMenuManagerTests();
	gmtlAudioManagerTests();
	gmtlSceneManagerTests();
	gmtlGameStateManagerTests();
	gmtlKeybindsTests();
	gmtlSettingsTests();
	gmtlTimeTests();
	gmtlSaveGameTests();
	

	// integration
	gmtlAppControllerTests_safe4();
	gmtlInitInputInSystemsTests_safe3();
	gmtlPauseFlowTests_safe1();
	
	// debug console
	gmtlDebugConsoleTests();
	gmtlDebugLogTests();
	
	gmtlGuiManagerTests();
}
