#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
    #include <windows.h>
#else
    #include <unistd.h>
    #include <sys/types.h>
#endif

int is_running_as_admin();
void windows_install();
void linux_install();
char* execute(const char* command);

int main() {
#ifdef _WIN32
    windows_install();
#else
    linux_install();
#endif
    return 0;
}

int is_running_as_admin() {
#ifdef _WIN32
    BOOL isAdmin = FALSE;
    SID_IDENTIFIER_AUTHORITY NtAuthority = SECURITY_NT_AUTHORITY;
    PSID AdministratorsGroup;
    if (AllocateAndInitializeSid(&NtAuthority, 2, SECURITY_BUILTIN_DOMAIN_RID, 
        DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0, &AdministratorsGroup)) {
        CheckTokenMembership(NULL, AdministratorsGroup, &isAdmin);
        FreeSid(AdministratorsGroup);
    }
    return isAdmin;
#else
    return geteuid() == 0;
#endif
}

void windows_install() {
    if (!is_running_as_admin()) {
        printf("This script must be run as an administrator.\n");
        exit(1);
    }
    
    const char* commands[] = {
        "powershell -Command \"Set-ExecutionPolicy RemoteSigned\"",
        "powershell -Command \"Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/install_protection.ps1' -OutFile $env:TEMP\\install_protection.ps1\"",
        "powershell -Command \"& $env:TEMP\\install_protection.ps1\""
    };
    
    for (int i = 0; i < 3; i++) {
        char* output = execute(commands[i]);
        if (output) {
            printf("%s\n", output);
            free(output);
        } else {
            break;
        }
    }
}

void linux_install() {
    if (!is_running_as_admin()) {
        printf("This script must be run with sudo.\n");
        exit(1);
    }
    
    const char* check_apt = "command -v apt";
    const char* check_pacman = "command -v pacman";
    const char* check_yum = "command -v yum";
    const char* install_command = NULL;
    
    if (system(check_apt) == 0) {
        install_command = "sudo apt install curl python3 python3-pip python3-venv -y";
    } else if (system(check_pacman) == 0) {
        install_command = "sudo pacman -Sy --noconfirm curl python python-pip";
    } else if (system(check_yum) == 0) {
        install_command = "sudo yum install -y curl python3 python3-pip";
    } else {
        printf("Unsupported package manager.\n");
        exit(1);
    }
    
    const char* commands[] = {
        install_command,
        "curl -O https://raw.githubusercontent.com/NeronNymus/protection/refs/heads/main/light/install_protection.py",
        "sudo python3 install_protection.py"
    };
    
    for (int i = 0; i < 3; i++) {
        char* output = execute(commands[i]);
        if (output) {
            printf("%s\n", output);
            free(output);
        } else {
            break;
        }
    }
}

char* execute(const char* command) {
    FILE* fp;
    char buffer[128];
    size_t output_size = 1;
    char* output = malloc(output_size);
    if (!output) return NULL;
    output[0] = '\0';
    
    fp = popen(command, "r");
    if (fp == NULL) {
        free(output);
        return NULL;
    }
    
    while (fgets(buffer, sizeof(buffer), fp) != NULL) {
        size_t buffer_len = strlen(buffer);
        char* temp = realloc(output, output_size + buffer_len);
        if (!temp) {
            free(output);
            pclose(fp);
            return NULL;
        }
        output = temp;
        strcpy(output + output_size - 1, buffer);
        output_size += buffer_len;
    }
    
    pclose(fp);
    return output;
}

