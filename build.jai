#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";

Command :: enum_flags u8 {
    CLEAN;
    BUILD;
    RELEASE;
}

#run {
    commands := parse_commands();
    print("Commands: %\n", commands);
    
    // Always run clean first if specified, regardless of argument order
    if commands & .CLEAN {
        print("=== Running clean ===\n");
        clean_target_directory();
    }

    sample_workspace := compiler_create_workspace("sample");
    if !sample_workspace {
        print("Sample workspace creation failed.\n");
        exit(1);
    }

    // Exit early if only clean was requested
    if commands == .CLEAN {
        print("exiting because clean was the only thing requested\n");
        set_build_options_dc(.{do_output=false}, sample_workspace);
        exit(0);
    }
        
    sample_options := get_build_options();

    // Create target directory if it doesn't exist
    sample_dir := "target/sample";
    success := make_directory_if_it_does_not_exist(sample_dir, true);
    if success {
        print("Directory [%] created successfully!\n", sample_dir);
    } else {
        print("Failed to create [%].\n", sample_dir);
    }

    // Configure build options
    sample_options.output_executable_name = "sample";
    sample_options.output_path = "target/sample/";
    sample_options.intermediate_path = "target/sample/.build/";
    
    // Set optimization level if release flag is present
    if commands & .RELEASE {
        set_optimization(*sample_options, .OPTIMIZED);
    }
    
    set_build_options(sample_options, sample_workspace);
    add_build_file(tprint("%/src/sample/sample.jai", #filepath), sample_workspace);

    // Tell the compiler that this build script itself doesn't produce an executable.
    // This prevents the default "Target Program" (Workspace 2) from trying to link.
    set_build_options_dc(.{do_output=false});    

    print("Build complete with optimization: %\n", ifx commands & .RELEASE then "OPTIMIZED" else "DEFAULT");
}

parse_commands :: () -> Command {
    build_options := get_build_options();
    args := build_options.compile_time_command_line;
    commands: Command = 0;
    
    for arg: args {
        if arg == "clean" || arg == "--clean" {
            commands |= .CLEAN;
        } else if arg == "build" || arg == "--build" {
            commands |= .BUILD;
        } else if arg == "release" || arg == "--release" {
            commands |= .RELEASE;
            // Release implies build
            commands |= .BUILD;
        }
    }
    
    // Default to build if no commands specified
    if commands == 0 {
        commands = .BUILD;
    }
    
    return commands;
}

clean_target_directory :: () {
    target_dirs := string.["target", "build", "out"];

    for dir: target_dirs {
        if file_exists(dir) {
            success := delete_directory(dir);
            if success {
                print(" Cleaned: %\n", dir);
            } else {
                print(" Failed to clean: %\n", dir);
            }
        }
    }
}
