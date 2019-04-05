void main() {
    import dub.recipe.sdl: parseSDL;
    import dub.recipe.packagerecipe: PackageRecipe;
    import std.file: readText, thisExePath;
    import std.stdio: writeln;
    import std.path: buildNormalizedPath, dirName, expandTilde;

    const text = readText("dub.sdl");
    PackageRecipe recipe;
    parseSDL(recipe, text, "parent", "dub.sdl");
    writeln(recipe, "\n\n");

    import dub.package_: Package;
    import dub.internal.vibecompat.inet.path: NativePath;

    const path = NativePath(buildNormalizedPath(thisExePath.dirName, ".."));
    auto pkg = new Package(recipe, path);

    writeln("package: ", pkg, "\n\n");

    import dub.packagemanager: PackageManager;
    import dub.project: Project;
    import dub.compilers.dmd: DMDCompiler;
    import dub.compilers.compiler: registerCompiler, getCompiler;
    import dub.generators.generator: GeneratorSettings;

    const userPath = NativePath("~/.dub".expandTilde);
    const systemPath = NativePath("/not/using/this");
    auto pman = new PackageManager(userPath, systemPath, false);
    auto proj = new Project(pman, pkg);

    auto settings = GeneratorSettings();
    settings.config = "executable";
    settings.buildType = "debug";
    // settings.compiler = new DMDCompiler doesn't work. They need to be
    // registered and for some reason the dub static ctor that does this
    // isn't being called.
    registerCompiler(new DMDCompiler);
    settings.compiler = getCompiler("dmd");
    settings.platform.compilerBinary = "dmd";

    writeln("describe: ", proj.describe(settings), "\n\n");
}
