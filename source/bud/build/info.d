/**
   This package has functionality to query the build.
   That will mean information such as which files,
   which compiler options, etc.
 */
module bud.build.info;


import bud.api: ProjectPath, SystemPackagesPath, UserPackagesPath,
    userPackagesPath, DubPackage, Compiler, DubConfigurations;


DubPackage[] dubPackages(
    in ProjectPath projectPath,
    in SystemPackagesPath systemPackagesPath,
    in UserPackagesPath userPackagesPath,
    in Compiler compiler,
    )
    @trusted  // dub...
{
    import bud.dub: project, generatorSettings, InfoGenerator;

    auto proj = project(projectPath, systemPackagesPath, userPackagesPath);
    auto generator = new InfoGenerator(proj);

    generator.generate(generatorSettings(compiler));

    return generator.dubPackages;
}


DubConfigurations dubConfigurations(
    in ProjectPath projectPath,
    in SystemPackagesPath systemPackagesPath,
    in UserPackagesPath userPackagesPath,
    )
    @trusted  // dub...
{
    import bud.dub: project, generatorSettings, InfoGenerator;

    auto proj = project(projectPath, systemPackagesPath, userPackagesPath);
    auto generator = new InfoGenerator(proj);

    generator.generate(generatorSettings(Compiler.dmd));

    return DubConfigurations(generator.configurations, generator.defaultConfiguration);
}
