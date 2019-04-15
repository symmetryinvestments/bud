void main() {
    import dub.recipe.sdl: parseSDL;
    import dub.recipe.packagerecipe: PackageRecipe;
    import std.file: readText, thisExePath;
    import std.stdio: writeln;
    import std.path: buildNormalizedPath, dirName, expandTilde;

    const text = readText("dub.sdl");
    PackageRecipe recipe;
    parseSDL(recipe, text, "parent", "dub.sdl");
    //writeln(recipe, "\n\n");

    import dub.package_: Package;
    import dub.internal.vibecompat.inet.path: NativePath;

    const path = NativePath(buildNormalizedPath(thisExePath.dirName, ".."));
    auto pkg = new Package(recipe, path);

    //writeln("package: ", pkg, "\n\n");

    import dub.packagemanager: PackageManager;
    import dub.project: Project;
    import dub.compilers.dmd: DMDCompiler;
    import dub.compilers.compiler: registerCompiler, getCompiler;
    import dub.generators.generator: GeneratorSettings;

    const userPath = NativePath("~/.dub".expandTilde);
    const systemPath = NativePath("/not/using/this");
    auto packageManager = new PackageManager(userPath, systemPath, false);
    auto project = new Project(packageManager, pkg);

    auto settings = GeneratorSettings();
    settings.config = "unittest";
    settings.buildType = "unittest";  // yes, has to be set manually here
    // settings.compiler = new DMDCompiler doesn't work. They need to be
    // registered and for some reason the dub static ctor that does this
    // isn't being called.
    registerCompiler(new DMDCompiler);
    settings.compiler = getCompiler("dmd");
    settings.platform.compilerBinary = "dmd";

    // Ends up being the same as the JSON with `dub describe`
    // The real information is in the generators
    //writeln("describe: ", project.describe(settings), "\n\n");

    auto generator = new MyGenerator(project);
    generator.generate(settings);
}


import dub.generators.generator: ProjectGenerator;

class MyGenerator: ProjectGenerator {

    import dub.project: Project;
    import dub.generators.generator: GeneratorSettings;

    this(Project project) {
        super(project);
    }

    override void generateTargets(GeneratorSettings settings, in TargetInfo[string] targets) {
        import dub.compilers.buildsettings;
        import std.stdio;

        foreach(name, targetInfo; targets) {
            writeln("name: ", name);
            auto newBuildSettings = targetInfo.buildSettings.dup;
            settings.compiler.prepareBuildSettings(newBuildSettings, BuildSetting.noOptions /*???*/);
            writeln("Build settings D flags: ", newBuildSettings.dflags);
            writeln;
        }
    }
}
