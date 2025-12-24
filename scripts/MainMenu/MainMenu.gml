function MainMenu() : Menu("main", "MAIN MENU", { background : true, backAction : "close" }) constructor
{
	build = function(menuManager)
	{
		self.addAction(menuManager, "Play", method(menuManager, menuManager.actionPlay));
		self.addSubmenu(menuManager, "Options", "options");
		self.addAction(menuManager, "Exit Game", method(menuManager, menuManager.actionExitPrompt));
	};
}
