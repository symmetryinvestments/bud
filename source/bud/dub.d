/**
   Interoperation with dub, made easy.
 */
module bud.dub;


import bud.api: ProjectPath, UserPackagesPath, Compiler;
import dub.generators.generator: ProjectGenerator;


// Not shared because, for unknown reasons, dub registers compilers
// in thread-local storage so we register the compilers in all
// threads. In normal dub usage it's done in of one dub's static
// constructors. In one thread.
static this() nothrow {
    import dub.compilers.compiler: registerCompiler;
    import dub.compilers.dmd: DMDCompiler;
    import dub.compilers.ldc: LDCCompiler;
    import dub.compilers.gdc: GDCCompiler;

    try {
        registerCompiler(new DMDCompiler);
        registerCompiler(new LDCCompiler);
        registerCompiler(new GDCCompiler);
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

auto generatorSettings(in Compiler compiler = Compiler.dmd) @safe {
    import dub.compilers.compiler: getCompiler;
    import dub.generators.generator: GeneratorSettings;
    import std.conv;

    GeneratorSettings ret;

    ret.buildType = "debug";  // FIXME
    const compilerName = compiler.text;
    ret.compiler = () @trusted { return getCompiler(compilerName); }();
    ret.platform.compilerBinary = compilerName;  // FIXME?

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


class InfoGenerator: ProjectGenerator {
    import bud.api: DubPackage;
    import dub.project: Project;
    import dub.generators.generator: GeneratorSettings;

    DubPackage[] dubPackages;

    this(Project project) {
        super(project);
    }

    /** Copied from the dub documentation:

        Overridden in derived classes to implement the actual generator functionality.

        The function should go through all targets recursively. The first target
        (which is guaranteed to be there) is
        $(D targets[m_project.rootPackage.name]). The recursive descent is then
        done using the $(D TargetInfo.linkDependencies) list.

        This method is also potentially responsible for running the pre and post
        build commands, while pre and post generate commands are already taken
        care of by the $(D generate) method.

        Params:
            settings = The generator settings used for this run
            targets = A map from package name to TargetInfo that contains all
                binary targets to be built.
    */
    override void generateTargets(GeneratorSettings settings, in TargetInfo[string] targets) @trusted {
        import dub.compilers.buildsettings: BuildSetting;

        foreach(targetName, targetInfo; targets) {

            auto newBuildSettings = targetInfo.buildSettings.dup;
            settings.compiler.prepareBuildSettings(newBuildSettings,
                                                   BuildSetting.noOptions /*???*/);
            dubPackages ~= DubPackage(targetName, newBuildSettings.dflags);
        }
    }

    string[] configurations() @trusted const {
        return m_project.configurations;
    }

    string defaultConfiguration() @trusted const {
        auto settings = generatorSettings();
        return m_project.getDefaultConfiguration(settings.platform);
    }
}
