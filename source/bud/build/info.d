/**
   This package has functionality to query the build.
   That will mean information such as which files,
   which compiler options, etc.
 */
module bud.build.info;


import bud.api: ProjectPath, UserPackagesPath, DubPackage, Compiler, DubConfigurations;


DubPackage[] targets(
    in ProjectPath projectPath,
    in UserPackagesPath userPackagesPath,
    in Compiler compiler,
    )
    @trusted  // dub...
{
    import bud.dub: project, generatorSettings, InfoGenerator;

    auto proj = project(projectPath, userPackagesPath);
    auto generator = new InfoGenerator(proj);

    generator.generate(generatorSettings(compiler));

    return generator.dubPackages;
}


DubConfigurations dubConfigurations(
    in ProjectPath projectPath,
    in UserPackagesPath userPackagesPath,
    )
    @trusted  // dub...
{
    import bud.dub: project, generatorSettings, InfoGenerator;

    auto proj = project(projectPath, userPackagesPath);
    auto generator = new InfoGenerator(proj);

    generator.generate(generatorSettings(Compiler.dmd));

    return DubConfigurations(generator.configurations, generator.defaultConfiguration);
}
