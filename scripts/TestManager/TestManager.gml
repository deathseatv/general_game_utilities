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
	
	// debug console
	gmtlDebugConsoleTests();
	gmtlDebugLogTests();
	
	gmtlGuiManagerTests();
}
