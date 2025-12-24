function KeybindsMenu() : Menu("keybinds", "KEYBINDS", { background : true, backAction : "pop" }) constructor
{
	build = function(menuManager)
	{
		self.addKeybind(menuManager, "Pause", "pause");
		self.addKeybind(menuManager, "Recenter", "recenter");
		self.addKeybind(menuManager, "Toggle Fullscreen", "toggleFullscreen");
		self.addLabel(menuManager, "(Press Enter to rebind)");
		self.addAction(menuManager, "Back", method(menuManager, menuManager.actionBack));
	};
}
