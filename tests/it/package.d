module it;


public import unit_threaded;


struct BudSandbox {

    alias sandbox this;

    Sandbox sandbox;

    static auto opCall() @safe {
        BudSandbox ret;
        ret.sandbox = Sandbox();
        return ret;
    }

    /// Writes dub.selections.json
    void writeSelections(string[string] packages = null) @safe const {
        import std.algorithm: map;
        import std.conv: text;
        import std.array: join;

        sandbox.writeFile("dub.selections.json",
                          [
                              `{`,
                              `    "fileVersion": 1,`,
                              `    "versions": {`,
                           ] ~
                          packages
                              .byKeyValue
                              .map!(p => text(`        "`, p.key, `": "`, p.value, `"`, "\n"))
                              .join(",")
                          ~
                          [
                              `    }`,
                              `}`,
                          ]

        );
    }
}
