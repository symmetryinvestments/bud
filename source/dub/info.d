module dub.info;


struct   ProjectPath { string value; }


auto targets(in ProjectPath projectPath) {
    import dub.generators.generator: ProjectGenerator;

    ProjectGenerator.TargetInfo[string] ret;
    return ret;
}
