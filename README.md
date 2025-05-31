# Pai - Command Line Interface Library for Jai

Pai (Parse Arg Input) is a library for creating command-line applications in Jai, inspired by [Cobra](https://github.com/spf13/cobra).

## Features

- Define commands, subcommands, arguments, and options
- Support for different types of arguments (string, int, float, bool)
- Automatic help generation
- Error handling

## Using the Module

Pai helps you structure your command-line application by defining commands, which can have subcommands, arguments, and options (also known as flags).

### Commands and Subcommands

A command is the central piece of your application. You start by defining a root command, and then you can add multiple subcommands to it to organize different functionalities.

**Example:**
```jai
// Define the root command
root_cmd: Command;
root_cmd.name = "myapp";
root_cmd.description = "My awesome CLI application";

// Define a subcommand
greet_cmd: Command;
greet_cmd.name = "greet";
greet_cmd.description = "Greets a person";
greet_cmd.action = () => {
    // Action for the greet command
    // For example, if 'name' argument is defined and populated:
    // print("Hello, %!\n", name_variable_associated_with_argument);
};

// Add subcommand to root command
array_add(*root_cmd.subcommands, greet_cmd);
```
This sets up a `myapp` command with a `greet` subcommand. Users would run it like `myapp greet`.

### Arguments

Arguments are positional values that your command or subcommand expects. You can define arguments with specific types (e.g., `string`, `int`, `bool`) and mark them as required. Pai will parse these arguments and store them in variables you provide.

**Example:**
```jai
// Variable to store the argument value
user_name: string;

// Define an argument for the 'greet' command
name_arg: Argument;
name_arg.name = "username"; // Name used in help messages
name_arg.description = "The name of the person to greet";
name_arg.arg_type = type_of(string);
name_arg.required = true;
name_arg.value = *user_name; // Pointer to store the parsed value

array_add(*greet_cmd.arguments, name_arg);

// Update greet_cmd.action to use user_name
greet_cmd.action = () => {
    print("Hello, %!\n", user_name);
};
```
Now, `myapp greet <username>` would expect a name. If `user_name` was "Alice" after parsing, it would print "Hello, Alice!".

### Options (Flags)

Options (or flags) are named parameters that modify the behavior of a command. They can have short names (e.g., `-v`) and long names (e.g., `--verbose`), and can also be typed and have default values. Pai parses these options and stores their values in variables you specify.

**Example:**
```jai
// Variable to store the option value
is_verbose := false;

// Define an option for the root command
verbose_option: Option;
verbose_option.name = "verbose";
verbose_option.short_name = "v";
verbose_option.description = "Enable verbose output";
verbose_option.option_type = type_of(bool);
verbose_option.required = false; // Options are typically not required
verbose_option.value = *is_verbose;

array_add(*root_cmd.options, verbose_option);

// Inside an action, you can check is_verbose
// For example, if root_cmd has an action:
// root_cmd.action = () => {
//     if is_verbose print("Verbose mode enabled.\n");
// };
```
Users can now run `myapp --verbose` or `myapp -v`.

### Parsing and Execution

After defining your commands, arguments, and options, you call `parse_args` with your root command to process the command-line input. Pai will populate the variables you provided via pointers and then execute the appropriate command's `action` if parsing is successful.

**Example:**
```jai
#import "Basic"; // For print
#import "String"; // For string type
#load "pai.jai";  // Assuming pai.jai is in load path

main :: () {
    // Define variables to store parsed values
    is_verbose := false;
    user_name: string;

    // Define the root command
    root_cmd: Command;
    root_cmd.name = "myapp";
    root_cmd.description = "My CLI application";
    // root_cmd.action = () => { if is_verbose print("Verbose mode on for myapp.\n"); }; // Optional root action

    // Add a verbose option to root_cmd
    verbose_option: Option;
    verbose_option.name = "verbose";
    verbose_option.short_name = "v";
    verbose_option.description = "Enable verbose output";
    verbose_option.option_type = type_of(bool);
    verbose_option.required = false;
    verbose_option.value = *is_verbose;
    array_add(*root_cmd.options, verbose_option);

    // Define a subcommand 'greet'
    greet_cmd: Command;
    greet_cmd.name = "greet";
    greet_cmd.description = "Greet a user";
    greet_cmd.action = () => {
        if is_verbose print("Greeting user '%'.\n", user_name);
        print("Hello, %!\n", user_name);
    };

    // Add 'name' argument to 'greet_cmd'
    name_arg: Argument;
    name_arg.name = "name";
    name_arg.description = "The user's name";
    name_arg.arg_type = type_of(string);
    name_arg.required = true;
    name_arg.value = *user_name;
    array_add(*greet_cmd.arguments, name_arg);
    
    // Add the subcommand to the root command
    array_add(*root_cmd.subcommands, greet_cmd);

    // Parse the command-line arguments
    result := parse_args(*root_cmd);

    if !result.success {
        print("Error: %\n", result.error_message);
        // Pai can also print help for the specific command where the error occurred
        if result.command print_help(result.command); 
        else print_help(*root_cmd); // Or print general help
        return;
    }
}
```
This complete example demonstrates setting up a root command with an option, a subcommand with an argument, and parsing the input.

### Automatic Help

Pai automatically generates help messages for your application and for each command. Users can typically access this with flags like `--help` or `-h`. The help message will list available subcommands, arguments, and options with their descriptions.

## Building the Module

The project includes a `build.jai` script to manage the build process for the library and the sample program.

### Build Commands

You can use the following commands with the build script from your project's root directory:

-   `jai build.jai - clean`: Cleans the build artifacts.
-   `jai build.jai - build`: Builds the sample program in debug mode.
-   `jai build.jai - release`: Builds the sample program in release mode.

These commands can be mixed and matched. For example, to clean and then build in release mode:
```sh
jai build.jai - clean release
```
Or to clean and build in debug mode:
```sh
jai build.jai - clean build
```

### Running the Sample Program

Running any of the build commands (e.g., `jai build.jai - build`) will compile the sample program located in `src/sample/sample.jai`. After a successful build, you can execute the sample program from the project's root directory.

**Examples:**

-   Display help for the sample program:
    ```sh
    ./target/sample/sample --help
    ```
-   Run the `greet` subcommand:
    ```sh
    ./target/sample/sample greet World
    ```
-   Run the `count` subcommand:
    ```sh
    ./target/sample/sample count 10
    ```

## License

Pai is released under the MIT license. See [LICENSE](LICENSE)
