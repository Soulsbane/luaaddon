module luaaddon.addonpaths;

/**
	Provides various path related API functions for use with Lua.
*/
import std.file : exists, getcwd, thisExePath;
import std.path : dirName, buildNormalizedPath;

import dfileutils;
import dpathutils;

class AddonPaths
{
public:

	this(const string addonName, const string applicationName, const string organizationName = string.init)
	{
		create(addonName, applicationName, organizationName);
	}

	void create(const string addonName, const string applicationName, const string organizationName = string.init)
	{
		addonName_ = addonName;
		configPath_ .create(organizationName, applicationName);
	}

	string getInstallDir()
	{
		return dirName(thisExePath());
	}

	string getBaseAddonDir()
	{
		debug
		{
			return buildNormalizedPath(getInstallDir(), "addons");
		}
		else
		{
			return configPath_.getDir("generators");
		}
	}

	string getAddonDirFor(const string language = string.init, const string generatorName = string.init)
	{
		debug
		{
			return buildNormalizedPath(getInstallDir(), "generators", language, generatorName);
		}
		else
		{
			return configPath_.getDir("generators", language, generatorName);
		}
	}

	// TODO: Perhaps support these methods?
	/*string getOutputDir()
	{
		return buildNormalizedPath(getcwd(), getValueFor("ProjectName"));
	}

	bool createDirInOutputDir(const(char)[][] params...)
	{
		immutable string path = buildNormalizedPath(params);
		return ensurePathExists(buildNormalizedPath(getOutputDir(), path));
	}

	bool removeDirFromOutputDir(const string dir)
	{
		return removePathIfExists(getOutputDir(), dir);
	}

	bool outputDirExists(const string dir)
	{
		string file = buildNormalizedPath(getOutputDir(), dir);
		return file.exists;
	}
	*/

	string getModuleDir()
	{
		debug
		{
			return buildNormalizedPath(getInstallDir(), "modules");
		}
		else
		{
			return configPath_.getDir("modules");
		}
	}

	string getTemplatesDir()
	{
		debug
		{
			return buildNormalizedPath(getInstallDir(), "templates");
		}
		else
		{
			return configPath_.getDir("templates");
		}
	}

	string getNormalizedPath(const(char)[][] params...)
	{
		return buildNormalizedPath(params);
	}

	bool createDirInAddonDir(const string language, const string generatorName)
	{
		return ensurePathExists(buildNormalizedPath(getBaseAddonDir(), language, generatorName));
	}

	bool dirExists(const string dir) const
	{
		return dir.exists;
	}

	string getAddonDir()
	{
		return getAddonDirFor(addonName_);
	}

	string getAddonModulesDir()
	{
		return buildNormalizedPath(getAddonDir(), "modules");
	}

	string getAddonTemplatesDir()
	{
		return buildNormalizedPath(getAddonDir(), "templates");
	}

private:
	string addonName_;
	ConfigPath configPath_;
}

unittest
{
	//auto paths = new AddonPaths("myaddon", "mycoolapp");
	//writeln(paths.getBaseAddonDir());
}
