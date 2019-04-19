import unit_threaded.runner: runTestsMain;

mixin runTestsMain!(
    "it.build",
    "it.fetch",
);
