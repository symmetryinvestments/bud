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
                `targetType "executable"`
            ]
        );

        writeFile("dub.selections.json",
                  `{ "fileVersion": 1, "versions": {} }`);

        writeFile("source/app.d",
                  "void main() {}");

        const tgts = targets(ProjectPath(testPath));
        tgts.should == [
            Target("foo", ["-debug", "-g", "-w"]),
        ];
    }
}
