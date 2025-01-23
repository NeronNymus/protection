import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.Arrays;
import java.util.List;

public class InstallProtection {
	public static void main(String[] args){
        String os = System.getProperty("os.name").toLowerCase();

        if (os.contains("win")) {
            WindowsInstall();
        } else if (os.contains("nix") || os.contains("nux") || os.contains("mac")) {
            LinuxInstall();
        } else {
            System.out.println("Unsupported operating system: " + os);
        }
	}

	private static void WindowsInstall() {
        if (!isRunningAsAdmin()) {
            System.out.println("This script must be run as an administrator.");
            System.exit(1);
        }

        // Create a list of commands
        List<String> commands = Arrays.asList(
            "set-executionpolicy remotesigned", 
            "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/install_protection.ps1' -OutFile '$env:TEMP\\install_protection.ps1'",
            "& '$env:TEMP\\install_protection.ps1'"
        );

        // Iterate through the list and execute each command
        for (String command : commands) {
            String output = Execute(command);
            if (output == null) {
                break;
            }
            System.out.println();
            System.out.println(output);
        }
    }

    // Method to check if the program is running with administrator privileges on Windows
    private static boolean isRunningAsAdmin() {
        try {
            // Check if we can run a command that requires administrator rights
            Process process = new ProcessBuilder("cmd.exe", "/c", "net session").start();
            process.waitFor();
            return process.exitValue() == 0;
        } catch (Exception e) {
            return false;
        }
    }

	private static void LinuxInstall(){
		if (!isRunningAsSudo()) {
            System.out.println("This script must be run with sudo.");
            System.exit(1);
        }

		// Create a list of commands
		List<String> commands = Arrays.asList(
            "curl -O https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/install_protection.py", 
            "sudo python3 install_protection.py"
        );

        // Iterate through the list and execute each command
        for (String command : commands) {
            String output = Execute(command);
			if (output == null){
				break;
			}
            System.out.println();
            System.out.println(output);
        }
	}

	private static boolean isRunningAsSudo() {
        try {
            String userName = System.getProperty("user.name");
            return "root".equals(userName);  // Check if the user is root (which means sudo is used)
        } catch (Exception e) {
            return false;  // Return false if an error occurs
        }
    }

	public static String Execute(String command) {
		StringBuilder output = new StringBuilder();  // Use StringBuilder to accumulate the output
		try {
			// Split the command into the command and its arguments
			String[] commandArray = command.split(" ");

			// Pass the command and arguments separately to ProcessBuilder
			ProcessBuilder processBuilder = new ProcessBuilder(commandArray);
			processBuilder.redirectErrorStream(true); // Redirect error stream to the standard output stream

			// Start the process
			Process process = processBuilder.start();

			// Reading the output of the command
			BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
			String line;
			boolean firstLine = true;  // Flag to handle newline between lines
			while ((line = reader.readLine()) != null) {
				if (!firstLine) {
					output.append(System.lineSeparator());  // Append newline only if it's not the first line
				}
				output.append(line);
				firstLine = false;  // After the first line, set the flag to false
			}

			// Wait for the process to complete and get its exit code
			int exitCode = process.waitFor();

		} catch (Exception e) {
			e.printStackTrace();
		}

		return output.toString();  // Return the accumulated output as a string
	}
}
