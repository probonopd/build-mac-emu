package main

import (
        "bufio"
        "fmt"
        "io"
        "log"
        "net/http"
        "os"
        "os/exec"
        "strings"
        "syscall"
)

// mountSpecial handles mounting of a special filesystem using the syscall.Mount call.
func mountSpecial(source, target, fstype, data string, flags uintptr) error {
        if err := syscall.Mount(source, target, fstype, flags, data); err != nil {
                return err
        }
        return nil
}

// ensureDir makes sure that the directory exists; if not, it creates it.
func ensureDir(path string, perm os.FileMode) error {
        return os.MkdirAll(path, perm)
}

// fileExists checks if a file exists.
func fileExists(filename string) bool {
        _, err := os.Stat(filename)
        return err == nil
}

// downloadFile downloads the file from the specified URL and saves it as outputPath.
func downloadFile(url, outputPath string) error {
        out, err := os.Create(outputPath)
        if err != nil {
                return fmt.Errorf("failed to create file %s: %v", outputPath, err)
        }
        defer out.Close()

        resp, err := http.Get(url)
        if err != nil {
                return fmt.Errorf("http.Get error: %v", err)
        }
        defer resp.Body.Close()

        if resp.StatusCode != http.StatusOK {
                return fmt.Errorf("bad status: %s", resp.Status)
        }

        _, err = io.Copy(out, resp.Body)
        if err != nil {
                return fmt.Errorf("failed writing to file %s: %v", outputPath, err)
        }
        return nil
}

func main() {

        // Remount root file system as read-write.
        if err := syscall.Mount("", "/", "", uintptr(syscall.MS_REMOUNT), "rw"); err != nil {
                log.Fatalf("Failed to remount / as rw: %v", err)
        }

        // Ensure required mount points exist.
        mountPoints := []string{"/proc", "/sys", "/dev"}
        for _, dir := range mountPoints {
                if err := ensureDir(dir, 0755); err != nil {
                        // Optional log: log.Fatalf("Failed to create directory %s: %v", dir, err)
                }
        }

        // Mount necessary filesystems.
        if err := mountSpecial("proc", "/proc", "proc", "", 0); err != nil {
                // log.Printf("Failed to mount proc on /proc: %v", err)
        }
        if err := mountSpecial("sysfs", "/sys", "sysfs", "", 0); err != nil {
                // log.Printf("Failed to mount sysfs on /sys: %v", err)
        }

        // Set PATH.
        path := "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games"
        if err := os.Setenv("PATH", path); err != nil {
                fmt.Printf("Failed to set PATH: %v\n", err)
                return
        }

        // Define and set HOME directory.
        home := "/home/mac"
        if err := os.MkdirAll(home, 0755); err != nil {
                log.Fatalf("Failed to create directory %s: %v", home, err)
        }
        if err := os.Chdir(home); err != nil {
                log.Fatalf("Failed to change directory to %s: %v", home, err)
        }
        if err := os.Setenv("HOME", home); err != nil {
                log.Fatalf("Failed to set HOME environment variable: %v", err)
        }

        // Download ROM if not present.
        romFile := "ROM"
        if !fileExists(romFile) {
                romURL := "https://github.com/adamhope/rpi-basilisk2-sdl2-nox/raw/refs/heads/main/Quadra800.ROM"
                fmt.Printf("File %s does not exist. Downloading from %s\n", romFile, romURL)
                if err := downloadFile(romURL, romFile); err != nil {
                        log.Fatalf("Failed to download ROM: %v", err)
                }
        }

        // Download system.img if not present.
        systemImg := "system.img"
        if !fileExists(systemImg) {
                systemURL := "https://github.com/mihaip/infinite-mac/raw/refs/heads/main/Images/Mac%20OS%207.6%20HD.dsk"
                fmt.Printf("File %s does not exist. Downloading from %s\n", systemImg, systemURL)
                if err := downloadFile(systemURL, systemImg); err != nil {
                        log.Fatalf("Failed to download system.img: %v", err)
                }
        }

        // Define the prefs file.
        prefsFile := "prefs"

        // Prepare to preserve existing non-disk lines.
        var preservedLines []string
        // Track if these options exist.
        hasFrameskip := false
        hasScreen := false
        hasRamsize := false

        // If the prefs file exists, read its content.
        if fileExists(prefsFile) {
                f, err := os.Open(prefsFile)
                if err != nil {
                        log.Fatalf("Failed to open prefs file for reading: %v", err)
                }
                scanner := bufio.NewScanner(f)
                for scanner.Scan() {
                        line := scanner.Text()
                        trimLine := strings.TrimSpace(line)
                        // Preserve any line that does not start with "disk"
                        if !strings.HasPrefix(trimLine, "disk") {
                                preservedLines = append(preservedLines, trimLine)
                        }
                        // Check for configuration options presence (ignore case and extra spaces)
                        if strings.HasPrefix(strings.ToLower(trimLine), "frameskip") {
                                hasFrameskip = true
                        }
                        if strings.HasPrefix(strings.ToLower(trimLine), "screen") {
                                hasScreen = true
                        }
                        if strings.HasPrefix(strings.ToLower(trimLine), "ramsize") {
                                hasRamsize = true
                        }
                        if strings.HasPrefix(strings.ToLower(trimLine), "seriala") {
                                hasSeriala = true
                        }
                }
                if err := scanner.Err(); err != nil {
                        log.Fatalf("Error reading prefs file: %v", err)
                }
                f.Close()
        }

        // Scan current directory for *.img files to build disk configuration lines.
        entries, err := os.ReadDir(".")
        if err != nil {
                log.Fatalf("Failed to read current directory: %v", err)
        }

        var diskLines []string
        for _, entry := range entries {
                if !entry.IsDir() && strings.HasSuffix(strings.ToLower(entry.Name()), ".img") {
                        diskLines = append(diskLines, "disk "+entry.Name())
                }
        }

        // If the file did not exist previously, we want to add defaults.
        // Also add the default lines if they are missing.
        if !hasFrameskip {
                preservedLines = append(preservedLines, "frameskip 0")
        }
        if !hasScreen {
                preservedLines = append(preservedLines, "screen dga/0/0")
        }
        if !hasRamsize {
                preservedLines = append(preservedLines, "ramsize 134217728")
        }
        if !hasSeriala {
                preservedLines = append(preservedLines, "seriala /tmp/vmodem")
        }

        // Combine disk lines (first) and then preserved lines.
        // Order: all disk lines first, then other configuration lines.
        newPrefsLines := append(diskLines, preservedLines...)
        newPrefsContent := strings.Join(newPrefsLines, "\n") + "\n"

        // Write the updated prefs file.
        if err := os.WriteFile(prefsFile, []byte(newPrefsContent), 0644); err != nil {
                log.Fatalf("Failed to write prefs file %s: %v", prefsFile, err)
        }

        // Execute BasiliskII with the specified configuration.
        cmd := exec.Command("BasiliskII", "--config", prefsFile)
        cmd.Env = append(os.Environ(), "TERM=vt100")
        // Optionally set cmd.Stdout and cmd.Stderr as needed.
        // cmd.Stdout = os.Stdout
        // cmd.Stderr = os.Stderr
        cmd.Stdout = nil
        cmd.Stderr = nil
        if err := cmd.Run(); err != nil {
                log.Fatalf("BasiliskII exited with error: %v", err)
        }
}
