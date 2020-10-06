/**
   This package has functionality to query the build.
   That will mean information such as which files,
   which compiler options, etc.
 */
module bud.api;


/// What it says on the tin
struct ProjectPath {
    string value;
}

/// Normally ~/.dub
struct UserPackagesPath {
    string value = "/dev/null";
}

/// Normally ~/.dub
UserPackagesPath userPackagesPath() {
    import std.process: environment;
    import std.path: buildPath, isAbsolute;
    import std.file: getcwd;

    version(Windows)
        const path = buildPath(environment.get("LOCALAPPDATA", appDataDir), "dub");
    else version(Posix) {
        string path = buildPath(environment.get("HOME"), ".dub/");
        if(!path.isAbsolute)
            path = buildPath(getcwd(), path);
    } else
          static assert(false, "Unknown system");

    return UserPackagesPath(path);
}


struct SystemPackagesPath {
    string value = "/dev/null";
}


SystemPackagesPath systemPackagesPath() {
    import std.process: environment;
    import std.path: buildPath;

    version(Windows)
        const path = buildPath(environment.get("ProgramData"), "dub/");
    else version(Posix)
        const path = "/var/lib/dub/";
    else
        static assert(false, "Unknown system");

    return SystemPackagesPath(path);
}


struct DubPackage {
    string name;
    string[] dflags;
}


enum Compiler {
    dmd,
    ldc,
    gdc,
}


struct DubConfigurations {
    string[] configurations;
    string default_;
}
