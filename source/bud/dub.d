/**
   Interoperation with dub, made easy.
 */
module bud.dub;


import bud.build.info: ProjectPath, UserPackagesPath;
import dub.generators.generator: ProjectGenerator;


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


struct Path {
    string value;
}

struct JSONString {
    string value;
}


struct DubPackages {

    import dub.packagemanager: PackageManager;

    private PackageManager _packageManager;
    private string _userPackagesPath;

    this(in UserPackagesPath userPackagesPath) @safe {
        _packageManager = packageManager(userPackagesPath);
        _userPackagesPath = userPackagesPath.value;
    }

    /**
       Takes a path to a zipped dub package and stores it in the appropriate
       user packages path.
       The metadata is usually taken from the dub registry via an HTTP
       API call.
     */
    void storeZip(in Path zip, in JSONString metadata) @safe {
        import dub.internal.vibecompat.data.json: parseJson;
        import dub.internal.vibecompat.inet.path: NativePath;
        import std.path: buildPath;

        auto metadataString = metadata.value.idup;
        auto metadataJson = () @trusted { return parseJson(metadataString); }();
        const name = () @trusted { return cast(string) metadataJson["name"]; }();
        const version_ = () @trusted { return cast(string) metadataJson["version"]; }();

        () @trusted {
            _packageManager.storeFetchedPackage(
                NativePath(zip.value),
                metadataJson,
                NativePath(buildPath(_userPackagesPath, "packages", name ~ "-" ~ version_, name)),
            );
        }();

    }
}

auto generatorSettings() @safe {
    import dub.compilers.compiler: getCompiler;
    import dub.generators.generator: GeneratorSettings;

    GeneratorSettings ret;

    ret.buildType = "debug";
    ret.compiler = () @trusted { return getCompiler("dmd"); }();
    ret.platform.compilerBinary = "dmd";

    return ret;
}


auto project(in ProjectPath projectPath, in UserPackagesPath userPackagesPath)
    @trusted
{
    import dub.project: Project;
    auto pkg = dubPackage(projectPath);
    return new Project(packageManager(userPackagesPath), pkg);
}


private auto dubPackage(in ProjectPath projectPath) @trusted {
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


auto packageManager(in UserPackagesPath userPackagesPath) @trusted {
    import dub.internal.vibecompat.inet.path: NativePath;
    import dub.packagemanager: PackageManager;

    const userPath = NativePath(userPackagesPath.value);
    const systemPath = NativePath("/dev/null");

    const refreshPackages = false;
    return new PackageManager(userPath, systemPath, refreshPackages);
}


class TargetGenerator: ProjectGenerator {
    import bud.build.info: Target;
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
