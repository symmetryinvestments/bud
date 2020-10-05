module it.build;


import it;
import bud.build.info;


@("targets.simplest")
@safe unittest {

    import dub.compilers.buildsettings;
    import std.algorithm: map;
    import std.path: buildPath;

    with(immutable BudSandbox()) {
        writeFile("dub.sdl",
            [
                `name "foo"`,
                `targetType "executable"`,
            ]
        );

        writeSelections;

        writeFile("source/app.d",
                  "void main() {}");

        const tgts = targets(
            ProjectPath(testPath),
            UserPackagesPath(),
            Compiler.dmd
        );

        tgts.should == [
            Target("foo", ["-debug", "-g", "-w"]),
        ];
    }
}


@("targets.dependencies")
@safe unittest {

    import dub.compilers.buildsettings;
    import std.algorithm: map;
    import std.path: buildPath;

    with(immutable BudSandbox()) {
        writeFile("dub.sdl",
            [
                `name "foo"`,
                `targetType "executable"`,
                `dependency "bar" version="*"`,
            ]
        );

        writeSelections(["bar": "1.2.3"]);

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

        const tgts = targets(
            ProjectPath(testPath),
            UserPackagesPath(inSandboxPath("userpath")),
            Compiler.dmd,
        );

        // apparently dflags is viral
        tgts.should == [
            const Target("foo", ["-preview=dip1000", "-debug", "-g", "-w"]),
            const Target("bar", ["-preview=dip1000", "-debug", "-g", "-w"]),
        ];
    }
}
