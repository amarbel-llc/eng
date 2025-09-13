package main

import (
	"fmt"
	"os"
	"runtime"
	"strconv"
	"strings"
	"time"
)

func getTotalMem() uint64 {
	data, err := os.ReadFile("/proc/meminfo")
	if err != nil {
		return 0
	}
	for _, line := range strings.Split(string(data), "\n") {
		if strings.HasPrefix(line, "MemTotal:") {
			fields := strings.Fields(line)
			if len(fields) >= 2 {
				kb, _ := strconv.ParseUint(fields[1], 10, 64)
				return kb * 1024 // convert to bytes
			}
		}
	}
	return 0
}

func main() {
	defer func() {
		if r := recover(); r != nil {
			fmt.Println(r)
		}
	}()

	fmt.Println("starting")

	const unit = 10 * 1024
	var data [][unit]byte
	for i := 0; ; i++ {
		var m runtime.MemStats
		runtime.ReadMemStats(&m)

		total := getTotalMem()

		if total == 0 {
			fmt.Println("Could not determine total system memory.")
		}

		inUse := m.Alloc
		percent := float64(inUse) / float64(total) * 100

		fmt.Printf("Memory in use: %.2f%% (%s of %s)\n",
			percent, GetWrittenHumanString(inUse), GetWrittenHumanString(total))

		cgroupVersion := checkCgroupVersion()
		fmt.Println("Cgroup version:", cgroupVersion)

		// Step 2: Get the memory limit imposed on the container
		limit, err := getMemoryLimit()

		if err != nil || limit == 0 {
			fmt.Println("Error: Could not determine memory limit:", err)
		}

		fmt.Printf("Container memory limit: %.2f MB\n", float64(limit)/(1024*1024))

		var block [unit]byte
		data = append(data, block)
		fmt.Printf("Allocated %s\n", GetWrittenHumanString(uint64(len(block)*i)))
		time.Sleep(time.Millisecond)

	}

	fmt.Println("done")
}

func GetWrittenHumanString(written uint64) string {
	const unit = 1000

	if written < unit {
		return fmt.Sprintf("%d B", written)
	}

	div, exp := int64(unit), 0

	for n := written / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}

	return fmt.Sprintf("%.1f %cB", float64(written)/float64(div), "kMGTPE"[exp])
}

// Read cgroup version from /proc/cgroups to determine if we're using cgroup v1 or v2
func checkCgroupVersion() string {
	data, err := os.ReadFile("/proc/cgroups")
	if err != nil {
		fmt.Println("Error reading /proc/cgroups:", err)
		return "unknown"
	}

	if strings.Contains(string(data), "memory") {
		return "cgroup v1"
	}
	return "cgroup v2"
}

// Read memory limit from the appropriate cgroup file
func getMemoryLimit() (uint64, error) {
	paths := []string{
		"/sys/fs/cgroup/memory.max",                   // cgroups v2
		"/sys/fs/cgroup/memory/memory.limit_in_bytes", // cgroups v1
	}

	for _, path := range paths {
		data, err := os.ReadFile(path)
		if err == nil {
			str := strings.TrimSpace(string(data))
			if str == "max" {
				return 0, fmt.Errorf("no memory limit set")
			}
			val, err := strconv.ParseUint(str, 10, 64)
			if err == nil {
				return val, nil
			}
		}
	}
	return 0, fmt.Errorf("memory limit not found")
}

// Get the current memory usage of the Go process
func getProcessMemoryUsage() uint64 {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	return m.Alloc
}
