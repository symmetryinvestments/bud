/**
   Zip utilities
 */
module test.zip;


import unit_threaded: Sandbox;


struct FileContents {
    string name;
    string contents;
}


void writeZip(ref const(Sandbox) sandbox, in string zipFileName, FileContents[] files) @safe {
    import std.zip: ZipArchive;
    import std.file: write;

    auto zip = new ZipArchive;

    foreach(file; files) {
        zip.addMember(archiveMember(file.name, file.contents));
    }

    sandbox.writeFile(zipFileName, () @trusted { return cast(string) zip.build; }());
}


private auto archiveMember(in string name, in string contents) @safe {
    import std.zip: ArchiveMember;
    import std.string: representation;
    import std.datetime: Clock;

    auto ret = new ArchiveMember;
    ret.name = name;
    ret.expandedData(contents.dup.representation);
    () @trusted { ret.time(Clock.currTime); }();

    return ret;
}
