module it.fetch;


import it;
import bud.build.info: UserPackagesPath;


@("store.zip")
@safe unittest {
    import bud.dub: packageManager;
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
        auto pkgMan = packageManager(UserPackagesPath(inSandboxPath("userpath")));

        () @trusted {
            pkgMan.storeFetchedPackage(
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
