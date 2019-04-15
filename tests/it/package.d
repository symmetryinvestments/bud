module it;


public import unit_threaded;
import dub.info;


@("exe.simple")
@safe unittest {
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
        const keys = () @trusted { return tgts.keys.dup; }();

        keys.should == ["default"];
    }
}
