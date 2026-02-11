# Building GCP Images with Packer

This directory contains a Packer configuration to build Google Cloud Platform images with your dotfiles pre-configured.

## Prerequisites

1. **Install Packer**: https://www.packer.io/downloads
2. **Install Just**: Already included in `install.sh`
3. **GCP Authentication**: Authenticate with Google Cloud
   ```bash
   gcloud auth application-default login
   ```
4. **GCP Project**: Have a GCP project ID ready

## Quick Start

1. **Initialize Packer** (first time only):
   ```bash
   just packer-init
   ```

2. **Validate configuration**:
   ```bash
   just packer-validate
   ```

3. **Build the image**:
   ```bash
   # Option 1: Pass project ID directly
   just packer-build YOUR_GCP_PROJECT_ID

   # Option 2: Use environment variable
   export GCP_PROJECT_ID=YOUR_GCP_PROJECT_ID
   just packer-build
   ```

## Configuration

You can customize the build by setting variables:

```bash
packer build \
  -var="project_id=my-project" \
  -var="zone=us-west1-a" \
  -var="machine_type=n1-standard-4" \
  -var="disk_size=30" \
  image.pkr.hcl
```

### Available Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `project_id` | `$GCP_PROJECT_ID` | GCP project ID |
| `zone` | `us-central1-a` | GCP zone for build VM |
| `source_image_family` | `ubuntu-2404-lts-amd64` | Base image family |
| `image_name` | `dotfiles-dev-{{timestamp}}` | Output image name |
| `image_family` | `dotfiles-dev` | Image family |
| `machine_type` | `n1-standard-2` | Build VM machine type |
| `disk_size` | `20` | Disk size in GB |
| `ssh_username` | `packer` | SSH username |

## Using the Image

Once built, create a new VM instance from the image:

```bash
gcloud compute instances create dev-vm \
  --project=YOUR_PROJECT_ID \
  --zone=us-central1-a \
  --machine-type=n1-standard-4 \
  --image-family=dotfiles-dev \
  --boot-disk-size=50GB \
  --boot-disk-type=pd-ssd
```

Or use the latest image directly:

```bash
# Get the latest image name
IMAGE=$(gcloud compute images list \
  --filter="family:dotfiles-dev" \
  --sort-by=~creationTimestamp \
  --limit=1 \
  --format="value(name)")

# Create instance
gcloud compute instances create dev-vm \
  --image=$IMAGE \
  --machine-type=n1-standard-4
```

## What Gets Installed

The image includes everything from `install.sh`:
- Development tools: Go, Node.js, Rust
- CLI utilities: eza, bat, zoxide, fzf, ripgrep, fd, delta, difftastic
- Editors: Neovim (with AstroNvim v5 plugins pre-installed)
- Version control: Git, Tig, Jujutsu
- Infrastructure: Docker, gcloud, awscli
- AI tools: Claude Code, Gemini CLI
- And more: tmux, direnv, jq, gh, gnupg, keepassxc, bitwarden-cli

All dotfiles are symlinked to the home directory via `setup.sh`.

## Updating the Image

To update the image with new dotfiles changes:

1. Commit and push your dotfiles changes
2. Run the build again with `just packer-build`
3. A new image will be created with the timestamp in the name
4. The image family `dotfiles-dev` will point to the latest image

## Troubleshooting

**Build fails during install.sh**:
- Increase the timeout in the provisioner section
- Check the Packer build logs for specific package failures

**Authentication errors**:
- Run `gcloud auth application-default login`
- Verify your GCP project ID is correct

**Neovim plugin installation issues**:
- The build allows plugin installation to fail gracefully
- Plugins will auto-install on first manual Neovim launch if needed

**SSH connection issues**:
- Check your VPC firewall rules allow SSH (port 22)
- Verify the build VM can access the internet

## Cost Optimization

- The build VM runs for approximately 20-30 minutes
- Using `n1-standard-2` minimizes cost while maintaining reasonable build speed
- Images are stored as GCP Custom Images (charged per GB per month)
- Consider deleting old images to reduce storage costs:
  ```bash
  gcloud compute images delete OLD_IMAGE_NAME
  ```
