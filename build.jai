#import "Compiler";
#import "BuildCpp";
#import "File_Utilities";
#import "Basic";
#import "String";
#import "Bindings_Generator";

#run {
    set_build_options_dc(.{do_output=false});

    srcs := enum_cpp_files("src");
    defer free_cpp_files(srcs);

    debug := false;
    build_options := get_build_options();
    for build_options.compile_time_command_line {
        if it == "debug" then debug = true;
    }

    #if OS == .WINDOWS {
        extra := string.["/I", "src", "/Zi", "/std:c++17", "/EHsc", "/MT"];
    } else {
        extra := "";
    }

    print("srcs:  %\n", srcs);
    print("debug: %\n", debug);
    print("extra: %\n", extra);

    print("-------------------------- BUILDING STATIC LIBRARY --------------------------\n");
    build_cpp_static_lib("win/miniz", ..srcs, debug=debug, extra=extra);

    output_filename: string;
    opts: Generate_Bindings_Options;
    {
        using opts;

        #if OS == .WINDOWS {
            output_filename          = "windows.jai";
            array_add(*libnames,      "minizlib");
        } else #if OS == .LINUX {
            output_filename          = "linux.jai";
        } else #if OS == .MACOS {
            // @ToDo: Determine dynamically? Customize?
            array_add(*system_include_paths, "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include");
            output_filename          = "macos.jai";
        } else {
            assert(false);
        }

        array_add(*libpaths,       ".");
        array_add(*system_include_paths, GENERATOR_DEFAULT_SYSTEM_INCLUDE_PATH);
        array_add(*source_files,  "src/miniz.h");
        strip_flags = 0;
        // strip_flags &= ~(Strip_Flags.CONSTRUCTORS | .DESTRUCTORS);
    }

    generate_bindings(opts, output_filename);
};
