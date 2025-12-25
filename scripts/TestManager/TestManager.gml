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
