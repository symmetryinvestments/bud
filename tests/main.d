import unit_threaded.runner: runTestsMain;

mixin runTestsMain!(
    "it.build.info.dflags",
    "it.build.info.configs",
    "it.fetch",
);
