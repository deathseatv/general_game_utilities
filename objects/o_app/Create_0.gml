persistent = true;
if(!variable_global_exists("app") || is_undefined(global.app))
{
	global.app = new AppController();
	global.app.init();
}