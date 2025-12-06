# Contributing to Colabri Deploy

Thank you for your interest in contributing to the Colabri deployment infrastructure!

## Project Overview

This repository contains Kubernetes configurations and deployment scripts for the Colabri platform. We use Kustomize for configuration management and support both GKE (production) and Minikube (development) environments.

## How to Contribute

### Reporting Issues

If you encounter bugs or have feature requests:

1. Check existing issues to avoid duplicates
2. Open a new issue with:
   - Clear description of the problem/request
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Environment details (GKE/Minikube, versions, etc.)

### Making Changes

1. **Fork the repository**
   ```bash
   git clone https://github.com/karstenda/colabri-deploy.git
   cd colabri-deploy
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow existing patterns and conventions
   - Test your changes on both Minikube and GKE if applicable
   - Update documentation as needed

4. **Test your changes**
   ```bash
   # Validate YAML syntax
   python3 -c "import yaml; yaml.safe_load(open('path/to/file.yaml'))"
   
   # Test Kustomize builds
   kubectl kustomize kubernetes/overlays/gke
   kubectl kustomize kubernetes/overlays/minikube
   
   # Test scripts
   bash -n scripts/your-script.sh
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "Brief description of changes"
   ```

6. **Push and create a pull request**
   ```bash
   git push origin feature/your-feature-name
   ```

## Coding Standards

### YAML Files

- Use 2 spaces for indentation
- Follow Kubernetes manifest conventions
- Include comments for complex configurations
- Keep resource limits reasonable

### Shell Scripts

- Include shebang: `#!/bin/bash`
- Use `set -e` to exit on errors
- Add usage comments at the top
- Use descriptive variable names
- Add error checking for required tools
- Print informative messages during execution

### Documentation

- Use clear, concise language
- Include examples where helpful
- Keep quick start guides simple
- Provide detailed explanations in full guides
- Update all affected docs when making changes

## Directory Structure

```
colabri-deploy/
├── kubernetes/
│   ├── base/              # Base manifests
│   └── overlays/
│       ├── gke/           # Production configs
│       └── minikube/      # Development configs
├── scripts/               # Deployment scripts
├── docs/                  # Documentation
├── .gitignore            # Git ignore rules
└── README.md             # Main readme
```

## Adding New Features

### Adding a New Kubernetes Resource

1. Add base manifest to `kubernetes/base/`
2. Reference it in `kubernetes/base/kustomization.yaml`
3. Add environment-specific patches if needed
4. Test with `kubectl kustomize`

### Adding a New Script

1. Create script in `scripts/` directory
2. Make it executable: `chmod +x scripts/your-script.sh`
3. Follow existing script patterns
4. Document usage in comments
5. Update relevant documentation

### Adding New Documentation

1. Create markdown file in `docs/` directory
2. Link from main README.md
3. Follow existing documentation structure
4. Include examples and code snippets

## Testing

### Local Testing with Minikube

```bash
# Start Minikube
minikube start

# Deploy
cd scripts
./deploy-minikube.sh

# Verify
./status.sh

# Clean up
./teardown.sh minikube
```

### Testing Kustomize Changes

```bash
# Build and review output
kubectl kustomize kubernetes/overlays/gke > /tmp/output.yaml
kubectl kustomize kubernetes/overlays/minikube > /tmp/output.yaml

# Validate (dry-run)
kubectl apply -k kubernetes/overlays/gke --dry-run=client
```

### Testing Scripts

```bash
# Check syntax
bash -n scripts/your-script.sh

# Test execution (use test environment)
cd scripts
./your-script.sh --help
```

## Best Practices

### Configuration Management

- Use Kustomize for environment-specific configs
- Keep secrets out of version control
- Document all configuration options
- Provide sensible defaults

### Resource Management

- Set appropriate resource requests/limits
- Test with realistic workloads
- Consider both small (Minikube) and large (GKE) deployments

### Security

- Never commit secrets or credentials
- Use Kubernetes Secrets for sensitive data
- Follow principle of least privilege
- Keep dependencies updated

### Documentation

- Update docs with every feature change
- Provide examples for complex features
- Keep quick-start guides simple
- Include troubleshooting tips

## Getting Help

- Review existing [documentation](docs/)
- Check [issues](https://github.com/karstenda/colabri-deploy/issues)
- Ask questions in issue comments
- Reach out to maintainers

## Code Review Process

Pull requests will be reviewed for:

- Functionality and correctness
- Code quality and style
- Documentation completeness
- Test coverage
- Security considerations

## License

By contributing, you agree that your contributions will be licensed under the same license as this project.

## Questions?

Feel free to open an issue for questions about contributing!
