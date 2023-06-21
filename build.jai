#import "Compiler";
#import "BuildCpp";
#import "File_Utilities";
#import "Basic";
#import "String";
#import "Bindings_Generator";
#import "File";

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

    log("srcs:  %\n", srcs);
    log("debug: %\n", debug);
    log("extra: %\n", extra);

    log("-------------------------- BUILDING STATIC LIBRARY --------------------------\n");
    make_directory_if_it_does_not_exist("win");
    build_cpp_static_lib("win/miniz", ..srcs, debug=debug, extra=extra);

    output_filename: string;
    opts: Generate_Bindings_Options;
    {
        using opts;
        add_generator_command = false;

        footer = #string DONE
size_t :: u64;
FILE   :: *void;
time_t :: s64;
DONE

        #if OS == .WINDOWS {
            output_filename          = "windows.jai";
            array_add(*libpaths, "win");
            array_add(*libnames, "miniz");
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
        visitor = miniz_visitor;
    }

    ok := generate_bindings(opts, output_filename);
    assert(ok);
};

miniz_visitor :: (decl: *Declaration, parent_decl: *Declaration) -> Declaration_Visit_Result {
    if decl.kind == .MACRO_DEFINITION {
        if decl.output_name == "zlib_version" {
            decl.decl_flags |= .OMIT_FROM_OUTPUT;
        }
    }
    return .RECURSE;
}
