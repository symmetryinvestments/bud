module it.fetch;


import it;
import test.zip;
import bud.build.info: UserPackagesPath;
import bud.dub: Packages, Path, JSONString;


@("store.zip")
@safe unittest {
    import std.array: join;
    import std.file: readText;
    import std.path: buildPath;

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

    with(sandbox) {
        auto pkgs = Packages(UserPackagesPath(inSandboxPath("userpath")));
        pkgs.storeZip(Path(inSandboxPath(buildPath("zips", "foo.zip"))),
                      JSONString(metadataStr));

        const dubJson = inSandboxPath(buildPath("userpath", "foo-1.2.3", "foo", "dub.json"));
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
