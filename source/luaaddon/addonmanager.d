module luaaddon.addonmanager;

import luaaddon.luaaddon;

class LuaAddonManager
{
	void register(LuaAddon addon)
	{
		addons_ ~= addon;
	}

	T callFunction(T = void, S...)(const string name, S args)
	{
		foreach(addon; addons_)
		{
			if(addon.hasFunction(name))
			{
				static if(is(T == void))
				{
					addon.callFunction(name, args);
				}
				else
				{
					auto value = addon.callFunction(name, args);
					return value[0].to!T;
				}
			}
			else
			{
				static if(!is(T == void))
				{
					return T.init;
				}
			}
		}

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
