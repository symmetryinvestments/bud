/**
   This package has functionality to query the build.
   That will mean information such as which files,
   which compiler options, etc.
 */
module bud.build.info;


/// What it says on the tin
struct ProjectPath {
    string value;
}

/// Normally ~/.dub
struct UserPackagesPath {
    string value = "/dev/null";
}


struct Target {
    string name;
    string[] dflags;
}


Target[] targets(in ProjectPath projectPath, in UserPackagesPath userPackagesPath)
    @trusted  // dub...
{
    import bud.dub: project, generatorSettings, TargetGenerator;

    auto proj = project(projectPath, userPackagesPath);
    auto generator = new TargetGenerator(proj);
    generator.generate(generatorSettings);

    return generator.targets;
}
