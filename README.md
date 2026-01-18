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
gh run download <WORKFLOW_RUN_ID> -n legend-apk

# Download AAB
gh run download <WORKFLOW_RUN_ID> -n legend-aab
```

**Note:** Replace `<WORKFLOW_RUN_ID>` with the actual workflow run ID (e.g., `21113943206`). You can find recent workflow runs by visiting the [Actions tab](../../actions) or by running:

```bash
gh run list
```
