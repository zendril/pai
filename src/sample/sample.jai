#import "Basic";
#import "String";

#import, file "../../module.jai";

main :: () {
    // Define context structs to hold command variables
    RootContext :: struct {
        verbose: *bool;
    }
    
    GreetContext :: struct {
        verbose: *bool;
        name: *string;
    }
    
    CountContext :: struct {
        verbose: *bool;
        count: *s64;
    }
    
    // Define variables to store parsed values
    verbose := false;
    name: string;
    count: s64;
    
    // Define the root command
    root_cmd: Command;
    root_cmd.name = "sample";
    root_cmd.description = "A sample CLI application using the Pai library";
    
    // Add a verbose option to the root command
    verbose_option: Option;
    verbose_option.name = "verbose";
    verbose_option.short_name = "v";
    verbose_option.description = "Enable verbose output";
    verbose_option.option_type = type_of(bool);
    verbose_option.type_name = "bool";
    verbose_option.required = false;
    verbose_option.value = *verbose;
    array_add(*root_cmd.options, verbose_option);
    
    // Create context for the root command
    root_context := New(RootContext);
    root_context.verbose = *verbose;
    root_cmd.ctx_data = root_context;
    
    // Define the root command's action
    root_cmd.action = (ctx: *void) {
        ctx_data := cast(*RootContext)ctx;
        print("Hello from the sample CLI application!\n");
        if ctx_data.verbose.* print("Verbose mode is enabled.\n");
    };
    
    // Define a "greet" subcommand
    greet_cmd: Command;
    greet_cmd.name = "greet";
    greet_cmd.short_name = "g";
    greet_cmd.description = "Greet a user";
    
    // Add a name argument to the greet command
    name_arg: Argument;
    name_arg.name = "name";
    name_arg.description = "The user's name";
    name_arg.arg_type = type_of(string);
    name_arg.type_name = "string";
    name_arg.required = true;
    name_arg.value = *name;
    array_add(*greet_cmd.arguments, name_arg);
    
    // Create context for the greet command
    greet_context := New(GreetContext);
    greet_context.verbose = *verbose;
    greet_context.name = *name;
    greet_cmd.ctx_data = greet_context;
    
    // Define the greet command's action
    greet_cmd.action = (ctx: *void) {
        ctx_data := cast(*GreetContext)ctx;
        print("Hello, %!\n", ctx_data.name.*);
        if ctx_data.verbose.* print("Greeting with verbose mode enabled.\n");
    };
    
    // Define a "count" subcommand
    count_cmd: Command;
    count_cmd.name = "count";
    count_cmd.short_name = "c";
    count_cmd.description = "Count to a number";
    
    // Add a count argument to the count command
    count_arg: Argument;
    count_arg.name = "count";
    count_arg.description = "The number to count to";
    
    count_arg.arg_type = type_of(s64);
    count_arg.type_name = "s64";  // Set the type name explicitly
    count_arg.required = true;
    count_arg.value = *count;
    
    array_add(*count_cmd.arguments, count_arg);
    
    // Create context for the count command
    count_context := New(CountContext);
    count_context.verbose = *verbose;
    count_context.count = *count;
    count_cmd.ctx_data = count_context;
    
    // Define the count command's action
    count_cmd.action = (ctx: *void) {
        ctx_data := cast(*CountContext)ctx;
        count_value := ctx_data.count.*;
        
        print("Counting to %:\n", count_value);
        for i: 1..count_value {
            print("%\n", i);
        }
        if ctx_data.verbose.* print("Counting with verbose mode enabled.\n");
    };
    
    // Add the subcommands to the root command
    array_add(*root_cmd.subcommands, greet_cmd);
    array_add(*root_cmd.subcommands, count_cmd);
    
    // Parse the command-line arguments
    result := parse_args(*root_cmd);
    
    if !result.success {
        print("Error: %\n", result.error_message);
        print_help(result.command);
        return;
    }
}
