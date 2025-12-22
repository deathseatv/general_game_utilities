function TestManager()
{
	// managers
	gmtlEventBusTests();
	gmtlInputManagerTests();
	gmtlMenuManagerTests();
	gmtlAudioManagerTests();
	gmtlSceneManagerTests();
	gmtlGameStateManagerTests();
	gmtlSettingsTests();
	gmtlTimeTests();

	// integration
	gmtlAppControllerTests_safe4();
	gmtlInitInputInSystemsTests_safe3();
	gmtlIntegrationTests();
	
	// debug console
	gmtlDebugConsoleTests();
	gmtlDebugLogTests();
}
