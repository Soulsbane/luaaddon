module luaaddon.addonmanager;

import luaaddon.luaaddon;

class LuaAddonManager
{
	void register(LuaAddon addon)
	{
		addons_ ~= addon;
	}

private:
	LuaAddon[] addons_;
}

version(unittest)
{
	class Generator : LuaAddon
	{

	}
}

unittest
{
	LuaAddon addon = new LuaAddon;
	Generator gen = new Generator;
	LuaAddonManager manager = new LuaAddonManager;

	manager.register(addon);
	manager.register(gen);
}
