module it.build.info.configs;


import it;
import bud.api;
import bud.build.info;


@("implicit")
@safe unittest {
    with(immutable BudSandbox()) {
        writeFile(
            "dub.sdl",
            [
                `name "theproj"`,
            ]
        );
        writeFile("source/app.d", q{void main() {}});

        dubConfigurations(ProjectPath(testPath), UserPackagesPath()).should ==
            DubConfigurations(["application", "library"], "application");
    }
}


@("explicit")
@safe unittest {
    with(immutable BudSandbox()) {
        writeFile(
            "dub.sdl",
            [
                `name "theproj"`,
                `configuration "exe" {`,
                    `targetType "executable"`,
                `}`,
                `configuration "lib" {`,
                 `    targetType "staticLibrary"`,
                `}`,
            ]
        );
        writeFile("source/app.d", q{void main() {}});

        dubConfigurations(ProjectPath(testPath), UserPackagesPath()).should ==
            DubConfigurations(["exe", "lib"], "exe");
    }
}
