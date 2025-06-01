#import "Basic";
#import "String";

// Define a struct to hold the command-line arguments
Command :: struct {
    name: string;
    short_name: string;
    description: string;
    arguments: [..]Argument;
    subcommands: [..]Command;
    options: [..]Option;
    global_options: [..]Option;  // Options that apply to all subcommands
    action: (*void) -> ();
    ctx_data: *void;  // Pointer to context data for the action
}

// Define a struct to hold information about an argument
Argument :: struct {
    name: string;
    description: string;
    arg_type: Type; // Jai's type reflection can be used here
    type_name: string; // Store the type name as a string for runtime comparison
    required: bool;
    value: *void;   // Pointer to store the parsed value
}

// Define a struct to hold information about an option
Option :: struct {
    name: string;
    short_name: string;
    description: string;
    option_type: Type; // Jai's type reflection can be used here
    type_name: string; // Store the type name as a string for runtime comparison
    default_value: *void; // Use a void pointer for generic default values
    required: bool;
    value: *void;   // Pointer to store the parsed value
}

// Result of parsing arguments
ParseResult :: struct {
    success: bool;
    error_message: string;
    command: *Command;
    help_shown: bool;
}

// Function to parse the command-line arguments
parse_args :: (command: *Command, args: []string = .[]) -> ParseResult {
    local_args := args;
    if local_args.count == 0 local_args = get_command_line_arguments();
    result: ParseResult;
    result.success = true;
    result.command = command;
    
    if local_args.count <= 1 {
        // No arguments provided, execute the root command's action
        if command.action {
            command.action(command.ctx_data);
        }
        return result;
    }
    
    // Skip the program name (local_args[0])
    current_index := 1;
    current_command := command;
    
    while current_index < local_args.count {
        arg := local_args[current_index];
        current_index += 1;
        
        // Check if it's a subcommand
        subcommand_found := false;
        for * subcommand: current_command.subcommands {
            if arg == subcommand.name || (subcommand.short_name.count > 0 && arg == subcommand.short_name) {
                current_command = subcommand;
                result.command = current_command;
                subcommand_found = true;
                
                // Check if the next arg is --help
                if current_index < local_args.count && local_args[current_index] == "--help" {
                    print_help(current_command);
                    result.help_shown = true;
                    return result;
                }
                
                break;
            }
        }
        
        if subcommand_found continue;
        
        // Check if it's an option (either long or short form)
        if starts_with(arg, "--") || (starts_with(arg, "-") && arg.count > 1) {
            option_found := false;
            
            // Handle long options (--option)
            if starts_with(arg, "--") {
                option_name := slice(arg, 2, arg.count - 2);
                
                // Handle the help option
                if option_name == "help" {
                    print_help(current_command);
                    result.help_shown = true;
                    return result;
                }
                
                // Check current command options
                for * option: current_command.options {
                    if option_name == option.name {
                        option_found = true;
                        
                        if option.type_name == "bool" {
                            // Boolean flag
                            (cast(*bool)option.value).* = true;
                        } else {
                            // Option with value
                            if current_index >= local_args.count {
                                result.success = false;
                                result.error_message = tprint("Option % requires a value", option.name);
                                return result;
                            }
                            
                            value_str := local_args[current_index];
                            current_index += 1;
                            
                            if option.type_name == "string" {
                                (cast(*string)option.value).* = value_str;
                            } else if option.type_name == "int" || option.type_name == "s64" {
                                value, success := string_to_int(value_str);
                                if !success {
                                    result.success = false;
                                    result.error_message = tprint("Failed to parse % as int", value_str);
                                    return result;
                                }
                                
                                if option.type_name == "int" {
                                    (cast(*int)option.value).* = value;
                                } else { // s64
                                    (cast(*s64)option.value).* = value;
                                }
                            } else if option.type_name == "float" {
                                value, success := string_to_float(value_str);
                                if !success {
                                    result.success = false;
                                    result.error_message = tprint("Failed to parse % as float", value_str);
                                    return result;
                                }
                                (cast(*float)option.value).* = value;
                            }
                        }
                        
                        break;
                    }
                }
                
                // If not found in current command options, check global options
                if !option_found {
                    for * option: current_command.global_options {
                        if option_name == option.name {
                            option_found = true;
                            
                            if option.type_name == "bool" {
                                // Boolean flag
                                (cast(*bool)option.value).* = true;
                            } else {
                                // Option with value
                                if current_index >= local_args.count {
                                    result.success = false;
                                    result.error_message = tprint("Option % requires a value", option.name);
                                    return result;
                                }
                                
                                value_str := local_args[current_index];
                                current_index += 1;
                                
                                if option.type_name == "string" {
                                    (cast(*string)option.value).* = value_str;
                                } else if option.type_name == "int" || option.type_name == "s64" {
                                    value, success := string_to_int(value_str);
                                    if !success {
                                        result.success = false;
                                        result.error_message = tprint("Failed to parse % as int", value_str);
                                        return result;
                                    }
                                    
                                    if option.type_name == "int" {
                                        (cast(*int)option.value).* = value;
                                    } else { // s64
                                        (cast(*s64)option.value).* = value;
                                    }
                                } else if option.type_name == "float" {
                                    value, success := string_to_float(value_str);
                                    if !success {
                                        result.success = false;
                                        result.error_message = tprint("Failed to parse % as float", value_str);
                                        return result;
                                    }
                                    (cast(*float)option.value).* = value;
                                }
                            }
                            
                            break;
                        }
                    }
                }
            } else if starts_with(arg, "-") { // Handle short options (-o)
                short_option_name := slice(arg, 1, arg.count - 1);
                
                // Check current command options
                for * option: current_command.options {
                    if short_option_name == option.short_name {
                        option_found = true;
                        
                        if option.type_name == "bool" {
                            // Boolean flag
                            (cast(*bool)option.value).* = true;
                        } else {
                            // Option with value
                            if current_index >= local_args.count {
                                result.success = false;
                                result.error_message = tprint("Option % requires a value", option.short_name);
                                return result;
                            }
                            
                            value_str := local_args[current_index];
                            current_index += 1;
                            
                            if option.type_name == "string" {
                                (cast(*string)option.value).* = value_str;
                            } else if option.type_name == "int" || option.type_name == "s64" {
                                value, success := string_to_int(value_str);
                                if !success {
                                    result.success = false;
                                    result.error_message = tprint("Failed to parse % as int", value_str);
                                    return result;
                                }
                                
                                if option.type_name == "int" {
                                    (cast(*int)option.value).* = value;
                                } else { // s64
                                    (cast(*s64)option.value).* = value;
                                }
                            } else if option.type_name == "float" {
                                value, success := string_to_float(value_str);
                                if !success {
                                    result.success = false;
                                    result.error_message = tprint("Failed to parse % as float", value_str);
                                    return result;
                                }
                                (cast(*float)option.value).* = value;
                            }
                        }
                        
                        break;
                    }
                }
                
                // Check global options
                for * option: current_command.global_options {
                    if short_option_name == option.short_name {
                        option_found = true;
                        
                        if option.type_name == "bool" {
                            // Boolean flag
                            (cast(*bool)option.value).* = true;
                        } else {
                            // Option with value
                            if current_index >= local_args.count {
                                result.success = false;
                                result.error_message = tprint("Option % requires a value", option.short_name);
                                return result;
                            }
                            
                            value_str := local_args[current_index];
                            current_index += 1;
                            
                            if option.type_name == "string" {
                                (cast(*string)option.value).* = value_str;
                            } else if option.type_name == "int" || option.type_name == "s64" {
                                value, success := string_to_int(value_str);
                                if !success {
                                    result.success = false;
                                    result.error_message = tprint("Failed to parse % as int", value_str);
                                    return result;
                                }
                                
                                if option.type_name == "int" {
                                    (cast(*int)option.value).* = value;
                                } else { // s64
                                    (cast(*s64)option.value).* = value;
                                }
                            } else if option.type_name == "float" {
                                value, success := string_to_float(value_str);
                                if !success {
                                    result.success = false;
                                    result.error_message = tprint("Failed to parse % as float", value_str);
                                    return result;
                                }
                                (cast(*float)option.value).* = value;
                            }
                        }
                        
                        break;
                    }
                }
            }
            
            // Only report an error if the option wasn't found in either current command options or global options
            if !option_found {
                result.success = false;
                result.error_message = tprint("Unknown option: %", arg);
                return result;
            }
        } else {
            // It's a positional argument
            if current_command.arguments.count > 0 {
                arg_index := 0;
                if arg_index < current_command.arguments.count {
                    argument := *current_command.arguments[arg_index];
                    
                    // Parse the argument based on its type
                    
                    if argument.type_name == "string" {
                        (cast(*string)argument.value).* = arg;
                    } else if argument.type_name == "s64" || argument.type_name == "int" {
                        value, success := string_to_int(arg);
                        if !success {
                            result.success = false;
                            result.error_message = tprint("Failed to parse % as int", arg);
                            return result;
                        }
                        
                        // Handle both int and s64 types based on the type name
                        if argument.type_name == "int" {
                            (cast(*int)argument.value).* = value;
                        } else if argument.type_name == "s64" {
                            (cast(*s64)argument.value).* = value;
                        }
                    } else if argument.type_name == "float" {
                        value, success := string_to_float(arg);
                        if !success {
                            result.success = false;
                            result.error_message = tprint("Failed to parse % as float", arg);
                            return result;
                        }
                        (cast(*float)argument.value).* = value;
                    }
                    // TODO: Handle more argument types and multiple arguments
                    // For now, we only handle the first argument
                } else {
                    result.success = false;
                    result.error_message = tprint("Too many arguments for command: %", current_command.name);
                    return result;
                }
            } else {
                result.success = false;
                result.error_message = tprint("Command % does not accept arguments: %", current_command.name, arg);
                return result;
            }
        }
    }
    
    // Update the result with the final command
    result.command = current_command;
    
    // Execute the action of the final command, but only if help wasn't shown
    if !result.help_shown && current_command.action {
        current_command.action(current_command.ctx_data);
    }
    
    return result;
}

// Function to print help information for a command
print_help :: (command: *Command) {
    print("Usage: %", command.name);
    if command.options.count > 0 print(" [options]");
    if command.arguments.count > 0 {
        for arg: command.arguments print(" <%>", arg.name);
    }
    if command.subcommands.count > 0 print(" [subcommand]");
    print("\n");
    
    print("%\n", command.description);
    
    if command.arguments.count > 0 {
        print("\nArguments:\n");
        for arg: command.arguments {
            print("  %\t%", arg.name, arg.description);
            if arg.required print(" (required)");
            print("\n");
        }
    }
    
    // Print local options
    if command.options.count > 0 {
        print("\nOptions:\n");
        for opt: command.options {
            print("  ");
            if opt.short_name.count > 0 print("-%, ", opt.short_name);
            print("--%\t%", opt.name, opt.description);
            // if opt.default_value != null print(" (default: %)", opt.default_value); // How to print generic default?
            print("\n");
        }
    }
    
    // Print global options
    if command.global_options.count > 0 {
        print("\nGlobal Options:\n");
        for opt: command.global_options {
            print("  ");
            if opt.short_name.count > 0 print("-%, ", opt.short_name);
            print("--%\t%", opt.name, opt.description);
            print("\n");
        }
    }
    
    if command.subcommands.count > 0 {
        print("\nSubcommands:\n");
        for sub: command.subcommands {
            print("  %\t%\n", sub.name, sub.description);
        }
        print("\nRun '% [subcommand] --help' for more information on a subcommand.\n", command.name);
    }
}
