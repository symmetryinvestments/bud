module it.fetch;


import it;
import test.zip;
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
