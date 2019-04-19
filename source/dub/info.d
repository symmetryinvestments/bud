module dub.info;


// Not shared because, for unknown reasons, dub registers compilers
// in thread-local storage so we register the compilers in all
// threads. In normal dub usage it's done in of one dub's static
// constructors. In one thread.
static this() nothrow {
    import dub.compilers.compiler: registerCompiler;
    import dub.compilers.dmd: DMDCompiler;

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
/// Normally ~/.dub
struct UserPackagesPath { string value = "/dev/null"; }


Target[] targets(in Settings settings)
    @trusted  // dub...
{
    import dub.generators.generator: ProjectGenerator;

    static class TargetGenerator: ProjectGenerator {
        import dub.project: Project;
        import dub.generators.generator: GeneratorSettings;

        Target[] targets;

        this(Project project) {
            super(project);
        }

        override void generateTargets(GeneratorSettings settings, in TargetInfo[string] targets) {
            import dub.compilers.buildsettings: BuildSetting;

            foreach(targetName, targetInfo; targets) {

                auto newBuildSettings = targetInfo.buildSettings.dup;
                settings.compiler.prepareBuildSettings(newBuildSettings,
                                                       BuildSetting.noOptions /*???*/);
                this.targets ~= Target(targetName, newBuildSettings.dflags);
            }
        }
    }

    auto project = project(settings.projectPath, settings.userPackagesPath);
    auto generator = new TargetGenerator(project);
    generator.generate(settingsToGeneratorSettings(settings));

    return generator.targets;
}


struct Target {
    string name;
    string[] dflags;
}

struct Settings {
    ProjectPath projectPath;
    UserPackagesPath userPackagesPath;
}


private auto settingsToGeneratorSettings(in Settings settings) @safe {
    import dub.compilers.compiler: getCompiler;
    import dub.generators.generator: GeneratorSettings;

    GeneratorSettings ret;

    ret.buildType = "debug";
    ret.compiler = () @trusted { return getCompiler("dmd"); }();
    ret.platform.compilerBinary = "dmd";

    return ret;
}

private auto project(in ProjectPath projectPath, in UserPackagesPath userPackagesPath)
    @trusted
{
    import dub.project: Project;
    auto pkg = dubPackage(projectPath);
    return new Project(packageManager(userPackagesPath), pkg);
}

private auto dubPackage(in ProjectPath projectPath) @trusted  {
    import dub.internal.vibecompat.inet.path: NativePath;
    import dub.package_: Package;

    const nativeProjectPath = NativePath(projectPath.value);
    return new Package(recipe(projectPath), nativeProjectPath);
}


private auto recipe(in ProjectPath projectPath) @safe {
    import dub.recipe.packagerecipe: PackageRecipe;
    import dub.recipe.sdl: parseSDL;
    import std.file: readText;
    import std.path: buildPath;

    const text = readText(buildPath(projectPath.value, "dub.sdl"));
    PackageRecipe recipe;
    () @trusted { parseSDL(recipe, text, "parent", "dub.sdl"); }();

    return recipe;
}


private auto packageManager(in UserPackagesPath userPackagesPath) @trusted {
    import dub.internal.vibecompat.inet.path: NativePath;
    import dub.packagemanager: PackageManager;

    const userPath = NativePath(userPackagesPath.value);
    const systemPath = NativePath("/dev/null");

    const refreshPackages = false;
    return new PackageManager(userPath, systemPath, refreshPackages);
}
