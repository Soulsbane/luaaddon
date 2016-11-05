/**
	Provides functionality for parsing TOC(Table of Contents) files like those found in World of Warcraft.
*/
module luaaddon.tocparser;

import std.stdio;
import std.file;
import std.string;
import std.algorithm : splitter;
import std.conv : to;
import std.array;

/// Parses TOC(Table of Contents) files like those found in World of Warcraft.
struct TocParser
{
	/**
		Processes text containing the TOC format.

		Params:
			text = The text to be processed.
	*/
	void processText(const string text) @safe
	{
		auto lines = text.lineSplitter();

		foreach(line; lines)
		{
			line = strip(line);

			if(line.startsWith("##"))
			{
				auto values = line.chompPrefix("##").strip.splitter(":").array;

				if(values.length == 2)
				{
					immutable string key = values[0].strip;
					immutable string value = values[1].strip;

					fields_[key] = value;
				}
			}
			else if(line.empty || line.startsWith("#")) // Line is a comment or empty.
			{
				continue;
			}
			else // Line is a file name
			{
				if(line.length != line.countchars(" ")) // Make sure line isn't only whitespace
				{
					filesList_ ~= line;
				}
			}
		}
	}

	/**
		Loads and processes a string containing the TOC text.

		Params:
			text = The text to process.

		Returns:
			True if the text has a length(not empty) false otherwise.
	*/
	bool loadString(const string text) @safe
	{
		if(text.length)
		{
			processText(text);
			return true;
		}

		return false;
	}

	/**
		Loads and processes a file that contains the TOC text.

		Params:
			fileName = The name of the file to process.

		Returns:
			True if the file could be found false otherwise.
	*/
	bool loadFile(const string fileName)
	{
		if(fileName.exists)
		{
			processText(fileName.readText);
			return true;
		}

		return false;
	}

	/**
		Checks if a TOC field can be found.

		Params:
			name = The name of the field to find.

		Returns:
			True if the field was found false otherwise.
	*/
	bool hasField(const string name) pure @safe
	{
		if(name in fields_)
		{
			return true;
		}

		return false;
	}

	/**
		Gets the value for a given field.

		Params:
			name = Name of the field to get the value for.
			defaultValue = The default value if the field wasn't found.

		Returns:
			The fields value if it was found otherwise the defaultValue.
	*/
	T getValue(T = string)(const string name, T defaultValue = T.init) pure @safe
	{
		if(hasField(name))
		{
			return fields_[name].to!T;
		}

		return defaultValue;
	}

	/// Useful when you want to use getValue!T to convey the calls meaning better.
	alias as = getValue;

	/**
		Gets the list of file that a TOC file contains.

		Returns:
			A list of files that a TOC file contains.
	*/
	string[] getFilesList() pure @safe
	{
		return filesList_;
	}

private:
	string[] filesList_;
	string[string] fields_;
}
