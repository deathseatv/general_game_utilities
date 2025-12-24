function PauseMenu() : Menu("pause", "PAUSED", { background : false, backAction : "unpause" }) constructor
{
	build = function(menuManager)
	{
		self.addSubmenu(menuManager, "Options", "options");
		self.addAction(menuManager, "Main Menu", method(menuManager, menuManager.actionMainMenu));
		self.addAction(menuManager, "Return to Game", method(menuManager, menuManager.actionReturnToGame));
	};
}
