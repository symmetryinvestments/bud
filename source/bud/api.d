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


struct Target {
    string name;
    string[] dflags;
}


enum Compiler {
    dmd,
    ldc,
    gdc,
}
