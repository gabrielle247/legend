# Legend

A new Flutter project.

## Getting Started

## Downloading Build Artifacts

The Android APK and AAB files are automatically built by GitHub Actions and uploaded as artifacts. You can download them using the GitHub CLI.

### Prerequisites

First, authenticate with GitHub CLI:

```bash
gh auth login
```

### Download Artifacts

Download the artifacts by specifying the workflow run ID and artifact name:

```bash
# Download APK
gh run download 21113943206 -n legend-apk

# Download AAB
gh run download 21113943206 -n legend-aab
```

**Note:** Replace `21113943206` with the actual workflow run ID. You can find recent workflow runs by visiting the [Actions tab](../../actions) or by running:

```bash
gh run list
```
