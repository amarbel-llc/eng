# Claude-Sandboxed Filesystem Configuration Proposal

## Overview

This proposal defines a TOML-based configuration file format for `claude-sandboxed` that specifies filesystem access permissions and path mappings between the Claude virtual environment and the host system. The configuration provides fine-grained control over what directories and files Claude can access.

## Configuration File Format

### File Structure

```toml
# claude-sandboxed.toml
version = "1.0"

[metadata]
name = "claude-workspace"
description = "Standard development environment"
created = "2025-01-15"

# Path mappings between virtual and real filesystems
[filesystem.mounts]
# Mount host directories into the virtual environment
# Format: virtual_path = { host_path = "/real/path", mode = "permission" }

"/workspace" = { host_path = "/home/user/projects/myapp", mode = "rw" }
"/data" = { host_path = "/home/user/datasets", mode = "ro" }
"/output" = { host_path = "/tmp/claude-output", mode = "rw" }
"/tools" = { host_path = "/usr/local/bin", mode = "rx" }

# Virtual environment filesystem structure
[filesystem]
# Base working directory inside virtual environment
workspace = "/workspace"

# Read-only access patterns (within virtual environment)
read_only = [
    "/data/**",
    "/workspace/src/**",
    "/workspace/docs/**",
    "/tools/**"
]

# Read-write access patterns (within virtual environment)
read_write = [
    "/workspace/output/**",
    "/workspace/tmp/**",
    "/output/**"
]

# Execute permissions (within virtual environment)
executable = [
    "/tools/git",
    "/tools/node",
    "/tools/python3",
    "/workspace/scripts/**"
]

# Explicitly denied paths (within virtual environment)
denied = [
    "/workspace/.env",
    "/workspace/.secrets/**",
    "/workspace/node_modules/.cache/**"
]

# Path resolution rules
[filesystem.resolution]
# How to handle symlinks
follow_symlinks = false

# Path canonicalization
canonicalize_paths = true

# Maximum path depth to prevent traversal attacks
max_path_depth = 20

# Whether to create missing directories
create_missing_dirs = true

# Default permissions for created files/directories
default_file_mode = "0644"
default_dir_mode = "0755"

# Filesystem constraints
[filesystem.limits]
# Maximum file size for reads/writes
max_file_size = "100MB"

# Maximum number of files that can be accessed
max_files = 10000

# Maximum total disk usage
max_disk_usage = "1GB"

# File operation rate limiting
max_operations_per_second = 100
```

## Configuration Sections

### 1. Path Mounts

The `[filesystem.mounts]` section defines how paths in the Claude virtual environment map to real paths on the host system:

- **Virtual Path**: The path as seen inside Claude's environment (e.g., `/workspace`)
- **Host Path**: The actual path on the host filesystem (e.g., `/home/user/projects/myapp`)
- **Mode**: Access permissions for the mount:
  - `"ro"`: Read-only access
  - `"rw"`: Read-write access
  - `"rx"`: Read and execute access
  - `"rwx"`: Full read, write, and execute access

### 2. Access Control Patterns

Within the virtual environment, additional access controls are applied:

- **read_only**: Paths with read-only access (supports glob patterns)
- **read_write**: Paths with read-write access
- **executable**: Paths with execute permissions
- **denied**: Explicitly blocked paths

### 3. Path Resolution

The `[filesystem.resolution]` section controls how paths are resolved:

- **follow_symlinks**: Whether to follow symbolic links (security consideration)
- **canonicalize_paths**: Convert paths to canonical form to prevent traversal
- **max_path_depth**: Limit path depth to prevent deeply nested attacks
- **create_missing_dirs**: Auto-create directories when needed
- **default_file_mode/default_dir_mode**: Permissions for newly created files/dirs

### 4. Filesystem Limits

The `[filesystem.limits]` section enforces resource constraints:

- **max_file_size**: Maximum size for individual file operations
- **max_files**: Total number of files that can be accessed
- **max_disk_usage**: Total disk space usage limit
- **max_operations_per_second**: Rate limiting for file operations

## Path Resolution Examples

### Example 1: Development Project

```toml
[filesystem.mounts]
"/workspace" = { host_path = "/home/user/myproject", mode = "rw" }
"/node_modules" = { host_path = "/home/user/myproject/node_modules", mode = "ro" }
```

When Claude accesses `/workspace/src/app.js`, it resolves to `/home/user/myproject/src/app.js` on the host.

### Example 2: Data Analysis

```toml
[filesystem.mounts]
"/data" = { host_path = "/datasets/customer-data", mode = "ro" }
"/output" = { host_path = "/results/analysis-2025-01", mode = "rw" }
"/workspace" = { host_path = "/tmp/claude-workspace", mode = "rw" }
```

Claude can read data from `/data/customers.csv` (maps to `/datasets/customer-data/customers.csv`) and write results to `/output/report.json` (maps to `/results/analysis-2025-01/report.json`).

### Example 3: Restricted Environment

```toml
[filesystem.mounts]
"/workspace" = { host_path = "/safe/sandbox", mode = "rw" }

[filesystem]
denied = [
    "/workspace/../**",  # Prevent traversal attempts
    "/workspace/.ssh/**", # Block SSH keys
    "/workspace/.*"      # Block hidden files
]
```

## Usage Examples

### Development Environment

```toml
version = "1.0"

[metadata]
name = "dev-environment"

[filesystem.mounts]
"/workspace" = { host_path = "/home/dev/project", mode = "rw" }
"/tools" = { host_path = "/usr/bin", mode = "rx" }

[filesystem]
workspace = "/workspace"
executable = ["/tools/git", "/tools/node", "/tools/npm"]
read_write = ["/workspace/**"]

[filesystem.limits]
max_file_size = "50MB"
max_disk_usage = "2GB"
```

### Data Analysis Environment

```toml
version = "1.0"

[metadata]
name = "analysis-environment"

[filesystem.mounts]
"/data" = { host_path = "/secure/datasets", mode = "ro" }
"/output" = { host_path = "/results/claude", mode = "rw" }
"/workspace" = { host_path = "/tmp/analysis", mode = "rw" }

[filesystem]
workspace = "/workspace"
read_only = ["/data/**"]
read_write = ["/workspace/**", "/output/**"]
denied = ["/workspace/.env", "/workspace/secrets/**"]

[filesystem.limits]
max_file_size = "500MB"
max_files = 5000
max_disk_usage = "5GB"
```

### Restricted Sandbox

```toml
version = "1.0"

[metadata]
name = "restricted-sandbox"

[filesystem.mounts]
"/workspace" = { host_path = "/isolated/sandbox", mode = "rw" }

[filesystem]
workspace = "/workspace"
read_write = ["/workspace/output/**"]
read_only = ["/workspace/input/**"]
denied = [
    "/workspace/../**",
    "/workspace/.*",
    "/workspace/output/../**"
]

[filesystem.resolution]
follow_symlinks = false
max_path_depth = 10

[filesystem.limits]
max_file_size = "10MB"
max_files = 100
max_disk_usage = "100MB"
max_operations_per_second = 50
```

## Implementation Considerations

### 1. Security

- **Path Traversal Protection**: Canonicalize all paths and enforce depth limits
- **Symlink Handling**: Control whether symlinks are followed to prevent escapes
- **Permission Validation**: Verify mount permissions match access patterns
- **Audit Logging**: Log all file operations for security monitoring

### 2. Performance

- **Path Caching**: Cache resolved paths to avoid repeated lookups
- **Permission Caching**: Cache permission checks for frequently accessed paths
- **Rate Limiting**: Prevent excessive file system operations
- **Lazy Mount**: Only establish mounts when first accessed

### 3. User Experience

- **Clear Error Messages**: Provide helpful feedback for permission denials
- **Path Validation**: Validate configuration at startup
- **Hot Reloading**: Allow configuration updates without restart
- **Template System**: Provide common configuration templates

### 4. Platform Compatibility

- **Cross-Platform Paths**: Handle Windows vs. Unix path differences
- **Permission Mapping**: Map file permissions across different systems
- **Mount Technologies**: Support various mount mechanisms (bind mounts, overlays, etc.)

## Benefits

1. **Clear Path Mapping**: Explicit control over virtual-to-real path resolution
2. **Granular Security**: Multiple layers of access control within virtual environment
3. **Resource Protection**: Limits prevent resource exhaustion attacks
4. **Audit Trail**: Complete visibility into file system access patterns
5. **Flexibility**: Configurable for various use cases and security requirements

## Future Extensions

- **Dynamic Mounts**: Add/remove mounts during runtime based on context
- **Encryption**: Support for encrypted mount points
- **Network Filesystems**: Integration with remote/cloud storage
- **Version Control Integration**: Special handling for Git repositories
- **Backup/Snapshot**: Automatic backup of modified files