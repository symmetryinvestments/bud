module dub.info;


// not shared because, for unknown reasons, dub registers compilers
// in thread-local storage so we register the compilers in all
// threads
static this() nothrow {
    import dub.compilers.compiler: registerCompiler;
    import dub.compilers.dmd: DMDCompiler;

    // normally done in dub's static ctor but for some reason
    // that's not working
    try {
        registerCompiler(new DMDCompiler);

    } catch(Exception e) {
        import std.stdio: stderr;
        try
            stderr.writeln("ERROR: ", e);
        catch(Exception _) {}
    }
}

struct ProjectPath { string value; }


Target[] targets(in ProjectPath projectPath) @trusted {
    import dub.generators.generator: ProjectGenerator;
    import dub.internal.vibecompat.inet.path: NativePath;
    import dub.packagemanager: PackageManager;
    import dub.package_: Package;
    import dub.recipe.packagerecipe: PackageRecipe;
    import dub.recipe.sdl: parseSDL;
    import dub.project: Project;
    import dub.generators.generator: GeneratorSettings;
    import dub.compilers.compiler: getCompiler;
    import std.file: readText;
    import std.path: buildPath;

    const userPath = NativePath("/dev/null");
    const systemPath = NativePath("/dev/null");
    auto packageManager = new PackageManager(userPath, systemPath, false);

    const text = readText(buildPath(projectPath.value, "dub.sdl"));
    PackageRecipe recipe;
    parseSDL(recipe, text, "parent", "dub.sdl");

    const nativeProjectPath = NativePath(projectPath.value);
    auto pkg = new Package(recipe, nativeProjectPath);
    auto project = new Project(packageManager, pkg);

    auto settings = GeneratorSettings();
    settings.buildType = "debug";
    settings.compiler = getCompiler("dmd");
    settings.platform.compilerBinary = "dmd";

    Target[] ret;

    class TargetGenerator: ProjectGenerator {
        this(Project project) {
            super(project);
        }

        override void generateTargets(GeneratorSettings settings, in TargetInfo[string] targets) {
            import dub.compilers.buildsettings: BuildSetting;

            foreach(targetName, targetInfo; targets) {

                auto newBuildSettings = targetInfo.buildSettings.dup;
                settings.compiler.prepareBuildSettings(newBuildSettings, BuildSetting.noOptions /*???*/);
                ret ~= Target(targetName, newBuildSettings.dflags);
            }
        }
    }

    auto generator = new TargetGenerator(project);
    generator.generate(settings);

    return ret;
}


struct Target {
    string name;
    string[] dflags;
}
