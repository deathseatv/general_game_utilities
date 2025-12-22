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

	// integration
	gmtlAppControllerTests_safe4();
	gmtlInitInputInSystemsTests_safe3();
	
	// debug console
	gmtlDebugConsoleTests();
	gmtlDebugLogTests();
}
