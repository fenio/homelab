# Renovate Configuration

This directory contains the Renovate configuration for the homelab repository. The configuration is split into multiple files for better organization and maintainability.

## Configuration Files

### Main Configuration
- **`.github/renovate.json5`** - Main configuration file that extends all other configurations

### Core Configurations
- **`automerge-github-actions.json`** - Auto-merge settings for GitHub Actions
- **`allowedVersions.json5`** - Version constraints for specific packages
- **`autoMerge.json5`** - Auto-merge rules for different application types
- **`commitMessage.json5`** - Commit message formatting rules
- **`disabledDatasources.json5`** - Disabled data sources
- **`grafanaDashboards.json5`** - Grafana dashboard update handling
- **`groups.json5`** - Package grouping rules
- **`managers.json5`** - File manager configurations
- **`security.json5`** - Security update handling
- **`oci.json5`** - OCI repository and Helm chart handling

## Key Features

### Scheduling
- Runs on Monday, Wednesday, and Friday before 6 AM (Europe/Warsaw timezone)
- Security updates run at any time
- Vulnerability alerts are processed immediately

### Auto-Merge Strategy
- **Critical Infrastructure**: Manual approval required for all updates
- **Applications**: Auto-merge for minor/patch updates, manual for major
- **Security Updates**: Auto-merge for applications, manual for infrastructure
- **Digest Updates**: Auto-merge for all Docker images

### Package Groups
- **Flux**: Flux CD components
- **Observability**: Grafana, Victoria Metrics, Coroot, etc.
- **Networking**: Ingress-nginx, cert-manager, external-dns
- **Database**: CloudNative PG components
- **Media Applications**: Sonarr, Lidarr, Readarr, Kyoo
- **Self-hosted Applications**: Open WebUI, Ollama, SearXNG
- **Storage and CSI**: Democratic CSI, snapshot controllers
- **Kubernetes System**: Metrics server, reloader, replicator

### Security Controls
- Vulnerability alerts enabled for all packages
- Critical infrastructure requires manual approval
- Database updates require manual approval
- Security patches are prioritized

### Ignored Dependencies
- Flux CD components (managed separately)
- Critical infrastructure components
- Database components (careful updates)

## Usage

The configuration automatically:
1. Detects dependencies in YAML files in the `cluster/` directory
2. Groups related packages together
3. Applies appropriate auto-merge rules
4. Creates PRs with proper commit messages
5. Handles security updates and vulnerability alerts

## Monitoring

- Dependency dashboard is enabled for overview
- PR limits prevent overwhelming the system
- Concurrent limits ensure stability
- Manual approval gates for critical components

## Customization

To modify the configuration:
1. Edit the appropriate configuration file
2. Test changes in a branch
3. Monitor Renovate behavior
4. Adjust rules as needed

## Best Practices

- Keep critical infrastructure updates manual
- Use groups for related packages
- Enable auto-merge for non-critical applications
- Monitor the dependency dashboard regularly
- Review security updates promptly