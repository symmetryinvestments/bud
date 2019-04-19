module it;


public import unit_threaded;
import dub.info;


@("exe.simple")
@safe unittest {

    import dub.compilers.buildsettings;
    import std.algorithm: map;
    import std.path: buildPath;

    with(immutable Sandbox()) {
        writeFile("dub.sdl",
            [
                `name "foo"`,
                `targetType "executable"`,
            ]
        );

        writeFile("dub.selections.json",
                  `{ "fileVersion": 1, "versions": {} }`);

        writeFile("source/app.d",
                  "void main() {}");

        const tgts = targets(Settings(ProjectPath(testPath)));
        tgts.should == [
            Target("foo", ["-debug", "-g", "-w"]),
        ];
    }
}


@("exe.dependency.proprietary")
@safe unittest {

    import dub.compilers.buildsettings;
    import std.algorithm: map;
    import std.path: buildPath;

    with(immutable Sandbox()) {
        writeFile("dub.sdl",
            [
                `name "foo"`,
                `targetType "executable"`,
                `dependency "bar" version="*"`,
            ]
        );

        writeFile("dub.selections.json",
                  [
                      `{`,
                      `    "fileVersion": 1,`,
                      `    "versions": {`,
                      `        "bar": "1.2.3"`,
                      `    }`,
                      `}`,
                  ]
        );

        writeFile("source/app.d",
                  "void main() {}");

        writeFile("userpath/packages/bar-1.2.3/bar/dub.sdl",
                  [
                      `name "bar"`,
                      `targetType "library"`,
                      `dflags "-preview=dip1000"`,
                      // This is needed: dub places a version field
                      // as a dub.json/sdl of the fetched package
                      // in ~/.dub where none existed in the original
                      // package recipe.
                      `version "1.2.3"`,
                  ]
        );
        writeFile("userpath/packages/bar-1.2.3/bar/source/bar.d",
                  "int add1(int i, int j) { return i + j; }");

        const settings = Settings(
            ProjectPath(testPath),
            UserPackagesPath(inSandboxPath("userpath")),
        );

        const tgts = targets(settings);

        // apparently dflags is viral
        tgts.should == [
            const Target("foo", ["-preview=dip1000", "-debug", "-g", "-w"]),
            const Target("bar", ["-preview=dip1000", "-debug", "-g", "-w"]),
        ];
    }
}


@("storeFetchedPackage")
@safe unittest {
    import dub.internal.vibecompat.data.json: parseJson;
    import std.array: join;
    import std.file: write, readText;
    import std.path: buildPath;
    import std.json: parseJSON;

    const dubSdl = [
        `name "foo"`,
        `targetType "library"`,
    ].join("\n") ~ "\n";

    auto sandbox = immutable Sandbox();
    sandbox.writeZip("zips/foo.zip",
                     [
                         FileContents("dub.sdl", dubSdl),
                         FileContents("source/foo.d", "module foo;\nvoid func() {}\n"),
                     ]
    );

    auto metadataStr =
    `{
        "name": "foo",
        "version": "1.2.3",
        "dependencies": {},
        "configurations": [
            {
                "name": "library",
            }
        ]
    }`;

    auto metadataJson = () @trusted { return parseJson(metadataStr); }();

    with(sandbox) {
        import dub.internal.vibecompat.inet.path: NativePath;
        auto packageManager = packageManager(UserPackagesPath(inSandboxPath("userpath")));

        () @trusted {
            packageManager.storeFetchedPackage(
                NativePath(inSandboxPath(buildPath("zips", "foo.zip"))),
                metadataJson,
                NativePath(inSandboxPath(buildPath("otherpath", "foo-1.2.3", "foo"))),
            );
        }();

        const dubJson = inSandboxPath(buildPath("otherpath", "foo-1.2.3", "foo", "dub.json"));
        shouldExist(dubJson);
        readText(dubJson).shouldBeSameJsonAs(
            `
            {
                "name": "foo",
                "version": "1.2.3",
                "targetType": "library",
                "sourcePaths": ["source/"],
                "importPaths": ["source/"],
                "configurations": [ { "name": "library", "targetType": "library" }]
            }
            `
        );
    }
}


private struct FileContents {
    string name;
    string contents;
}


private void writeZip(ref const(Sandbox) sandbox, in string zipFileName, FileContents[] files) @safe {
    import std.zip: ZipArchive;
    import std.file: write;

    auto zip = new ZipArchive;

    foreach(file; files) {
        zip.addMember(archiveMember(file.name, file.contents));
    }

    sandbox.writeFile(zipFileName, () @trusted { return cast(string) zip.build; }());
}


private auto archiveMember(in string name, in string contents) @safe {
    import std.zip: ArchiveMember;
    import std.string: representation;
    import std.datetime: Clock;

    auto ret = new ArchiveMember;
    ret.name = name;
    ret.expandedData(contents.dup.representation);
    () @trusted { ret.time(Clock.currTime); }();

    return ret;
}
