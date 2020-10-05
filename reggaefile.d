import reggae;
enum commonFlags = "-w -g -debug";
mixin build!(dubDefaultTarget!(CompilerFlags(commonFlags)),
             dubTestTarget!(CompilerFlags(commonFlags)));
