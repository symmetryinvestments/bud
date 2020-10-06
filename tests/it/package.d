module it;


public import unit_threaded;


struct BudSandbox {

    alias sandbox this;

    Sandbox sandbox;

    /// pseudo-constructor
    static auto opCall() @safe {
        BudSandbox ret;
        ret.sandbox = Sandbox();
        return ret;
    }

    /// Writes dub.selections.json
    void writeDubSelections(string[string] packages = null) @safe const {
        import std.algorithm: map;
        import std.conv: text;
        import std.array: join;

        sandbox.writeFile("dub.selections.json",
                          [
                              `{`,
                              `    "fileVersion": 1,`,
                              `    "versions": {`,
                           ] ~
                          packages
                              .byKeyValue
                              .map!(p => text(`        "`, p.key, `": "`, p.value, `"`, "\n"))
                              .join(",")
                          ~
                          [
                              `    }`,
                              `}`,
                          ]

        );
    }

    /// Writes a dub.sdl for a downloaded dub dependency akin to the ones in ~/.dub
    void writeDownloadedDubSdl(in string path, in string name, in string version_, in string[] lines) @safe const
    {
        import std.path: buildPath;
        // This is needed: dub places a version field as a
        // dub.json/sdl of the fetched package in ~/.dub where none
        // existed in the original package recipe.
        const versionLine = `version "` ~ version_ ~ `"`;
        const fileName = buildPath(pkgPath(path, name, version_), "dub.sdl");
        writeFile(fileName, lines ~ versionLine);
    }

    static string pkgPath(in string path, in string name, in string version_) @safe {
        import std.path: buildPath;
        // e.g. "userpath/packages/bar-1.2.3/bar/dub.sdl"
        return buildPath(path, "packages", name ~ "-" ~ version_, name);
    }
}
