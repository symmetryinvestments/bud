/**
   This package has functionality to query the build.
   That will mean information such as which files,
   which compiler options, etc.
 */
module bud.build.info;


import bud.api: ProjectPath, UserPackagesPath, Target, Compiler;


Target[] targets(
    in ProjectPath projectPath,
    in UserPackagesPath userPackagesPath,
    in Compiler compiler,
    )
    @trusted  // dub...
{
    import bud.dub: project, generatorSettings, TargetGenerator;

    auto proj = project(projectPath, userPackagesPath);
    auto generator = new TargetGenerator(proj);

    generator.generate(generatorSettings(compiler));

    return generator.targets;
}
