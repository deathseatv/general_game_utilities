function VolumeMenu() : Menu("volume", "VOLUME", { background : true, backAction : "pop" }) constructor
{
	build = function(menuManager)
	{
		self.addRange(menuManager, "Sound", method(menuManager, menuManager.getSoundVolume), method(menuManager, menuManager.setSoundVolume), { step : 0.05 });
		self.addRange(menuManager, "Music", method(menuManager, menuManager.getMusicVolume), method(menuManager, menuManager.setMusicVolume), { step : 0.05 });
		self.addAction(menuManager, "Back", method(menuManager, menuManager.actionBack));
	};
}
