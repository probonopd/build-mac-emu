package main

import (
        "fmt"
        "io"
        "log"
        "net/http"
        "os"
        "os/exec"
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

// fileExists checks if a file exists in the current directory.
func fileExists(filename string) bool {
        _, err := os.Stat(filename)
        return err == nil
}

// downloadFile downloads the file from the specified URL and saves it as outputPath.
func downloadFile(url, outputPath string) error {
        // Create the output file
        out, err := os.Create(outputPath)
        if err != nil {
                return fmt.Errorf("failed to create file %s: %v", outputPath, err)
        }
        defer out.Close()

        // Request the URL
        resp, err := http.Get(url)
        if err != nil {
                return fmt.Errorf("http.Get error: %v", err)
        }
        defer resp.Body.Close()

        if resp.StatusCode != http.StatusOK {
                return fmt.Errorf("bad status: %s", resp.Status)
        }

        // Write the response body to the file
        _, err = io.Copy(out, resp.Body)
        if err != nil {
                return fmt.Errorf("failed writing to file %s: %v", outputPath, err)
        }
        return nil
}

func main() {

        err := syscall.Mount("", "/", "", uintptr(syscall.MS_REMOUNT), "rw")
        if err != nil {
                log.Fatalf("Failed to remount / as rw: %v", err)
        }

        // Define target mount points.
        mountPoints := []string{"/proc", "/sys", "/dev"}

        // Ensure each mount point directory exists.
        for _, dir := range mountPoints {
                if err := ensureDir(dir, 0755); err != nil {
                        log.Fatalf("Failed to create directory %s: %v", dir, err)
                }
        }

        // Mount proc filesystem (like "mount -t proc proc /proc")
        if err := mountSpecial("proc", "/proc", "proc", "", 0); err != nil {
                log.Println("Failed to mount proc on /proc: %v", err)
        } else {
                log.Println("Mounted proc filesystem successfully on /proc")
        }

        // Mount sysfs filesystem (like "mount -t sysfs sysfs /sys")
        if err := mountSpecial("sysfs", "/sys", "sysfs", "", 0); err != nil {
                log.Println("Failed to mount sysfs on /sys: %v", err)
        } else {
                log.Println("Mounted sysfs filesystem successfully on /sys")
        }

        // Set the PATH environment variable
        path := "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games"
        if err := os.Setenv("PATH", path); err != nil {
                fmt.Printf("Failed to set PATH: %v\n", err)
                return
        }

        // Define the HOME directory path.
        home := "/home/mac"

        // Create the HOME directory if it doesn't exist.
        if err := os.MkdirAll(home, 0755); err != nil {
                log.Fatalf("Failed to create directory %s: %v", home, err)
        }

        // Change working directory to HOME as the very first thing.
        if err := os.Chdir(home); err != nil {
                log.Fatalf("Failed to change directory to %s: %v", home, err)
        }

        // Set the HOME environment variable.
        if err := os.Setenv("HOME", home); err != nil {
                log.Fatalf("Failed to set HOME environment variable: %v", err)
        }

        // Download ROM if it does not exist.
        romFile := "ROM"
        if !fileExists(romFile) {
                romURL := "https://github.com/adamhope/rpi-basilisk2-sdl2-nox/raw/refs/heads/main/Quadra800.ROM"
                fmt.Printf("File %s does not exist. Downloading from %s\n", romFile, romURL)
                if err := downloadFile(romURL, romFile); err != nil {
                        log.Fatalf("Failed to download ROM: %v", err)
                }
        } else {
                fmt.Printf("File %s exists. Skipping download.\n", romFile)
        }

        // Download system.img if it does not exist.
        systemImg := "system.img"
        if !fileExists(systemImg) {
                systemURL := "https://github.com/mihaip/infinite-mac/raw/refs/heads/main/Images/Mac%20OS%207.6%20HD.dsk"
                fmt.Printf("File %s does not exist. Downloading from %s\n", systemImg, systemURL)
                if err := downloadFile(systemURL, systemImg); err != nil {
                        log.Fatalf("Failed to download system.img: %v", err)
                }
        } else {
                fmt.Printf("File %s exists. Skipping download.\n", systemImg)
        }

        // Create the "prefs" file with the desired content.
        prefsContent := "disk system.img\nframeskip 0\n"
        prefsFile := "prefs"
        if err := os.WriteFile(prefsFile, []byte(prefsContent), 0644); err != nil {
                log.Fatalf("Failed to write file %s: %v", prefsFile, err)
        }

        // Execute BasiliskII with the specified configuration.
        cmd := exec.Command("BasiliskII", "--config", prefsFile)
        cmd.Stdout = os.Stdout
        cmd.Stderr = os.Stderr

        fmt.Printf("Executing command: BasiliskII --config %s in directory %s\n", prefsFile, home)
        if err := cmd.Run(); err != nil {
                log.Fatalf("BasiliskII exited with error: %v", err)
        }
}
