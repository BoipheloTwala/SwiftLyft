# CI/CD Pipeline Documentation

## Overview

This repository uses GitHub Actions for continuous integration and deployment. The pipeline is configured to automatically build, test, and validate code changes for both the Flutter frontend and Node.js backend.

## Workflow File

The main CI/CD workflow is defined in `.github/workflows/ci-cd.yml`.

## Pipeline Stages

### Triggers
- Push to `main` branch
- Pull requests to `main` branch
- Manual trigger via workflow dispatch

### Frontend Pipeline (Flutter)

1. **Lint & Format** (`frontend-lint-and-format`)
   - Checks code formatting with `flutter format`
   - Runs static analysis with `flutter analyze`

2. **Tests** (`frontend-test`)
   - Runs unit and integration tests with `flutter test`

3. **Build** (`frontend-build`)
   - Builds Android APK: `flutter build apk --release`
   - Builds iOS app: `flutter build ios --release --no-codesign`
   - Uploads Android APK as artifact

### Backend Pipeline (Node.js)

1. **Lint & Format** (`backend-lint-and-format`)
   - Runs ESLint for code quality
   - Checks Prettier formatting

2. **Tests** (`backend-test`)
   - Runs Jest test suite
   - Generates coverage reports
   - Uploads coverage to Codecov (optional)

3. **API Tests** (`backend-api-tests`)
   - Runs Postman collection via Newman
   - Tests end-to-end API functionality

4. **Docker Build** (`backend-build`)
   - Builds multi-stage Docker image
   - Pushes to GitHub Container Registry (GHCR)
   - Only pushes on non-PR events

### Quality & Security

1. **Security Scan** (`security-scan`)
   - Uses Snyk to detect vulnerabilities
   - Requires `SNYK_TOKEN` secret

2. **Code Quality** (`code-quality`)
   - Runs SonarQube scan
   - Requires `SONAR_TOKEN` and `SONAR_HOST_URL` secrets

3. **OWASP ZAP Scan** (`owasp-zap-scan`)
   - Runs API security scan on staging environment
   - Only runs on main branch or commits with `[staging]` tag
   - Requires `STAGING_API_URL` secret (optional, defaults to localhost)
   - Generates HTML security report

4. **Quality Gate** (`quality-gate`)
   - Aggregates results from all jobs
   - Fails if critical builds fail

## Required Secrets

To enable all features, configure these secrets in GitHub repository settings:

- `SNYK_TOKEN` - Snyk API token for security scanning
- `SONAR_TOKEN` - SonarQube authentication token
- `SONAR_HOST_URL` - SonarQube server URL (e.g., `https://sonarcloud.io`)
- `STAGING_API_URL` - Staging API URL for OWASP ZAP scans (optional, defaults to `http://localhost:3000/api`)

Note: `GITHUB_TOKEN` is automatically provided by GitHub Actions.

## Setup Requirements

### Backend Dependencies

If you've added new dependencies (like ESLint or Prettier), update `package-lock.json` locally:

```bash
cd Swiftlyft_backend
npm install
git add package-lock.json
git commit -m "chore: update package-lock.json"
```

The CI pipeline includes a fallback (`npm ci || npm install`) but it's best practice to keep `package-lock.json` in sync.

### Node.js Version

The project requires **Node.js 18.x or higher**. The CI pipeline uses Node 18.x to match dependency requirements.

## Docker Image

The backend Docker image is published to:
```
ghcr.io/<owner>/<repo>/swiftlyft-backend
```

Tags are automatically generated based on:
- Branch name
- Commit SHA
- Semantic versioning (if applicable)

## Caching

The pipeline uses GitHub Actions caching to speed up builds:
- Flutter: `~/.pub-cache` cached by `pubspec.lock` hash
- Node.js: `~/.npm` cached by `package-lock.json` hash

## Artifacts

The following artifacts are generated:
- `android-apk` - Release Android APK
- `newman-report` - Postman test results (HTML)
- `zap-results` - OWASP ZAP security scan report (HTML, staging only)

## Troubleshooting

### Tests Failing
- Check test logs for specific error messages
- Ensure all environment variables are set correctly
- Verify database connections for integration tests

### Docker Build Failing
- Verify Dockerfile syntax
- Check that all required files are present
- Ensure `package.json` is valid

### Security/Quality Scans Failing
- Verify secrets are configured correctly
- Check that tokens have appropriate permissions
- Review scan output for specific issues

## Local Testing

You can test most pipeline steps locally:

```bash
# Frontend
cd swiftlyft
flutter pub get
flutter analyze
flutter format --set-exit-if-changed .
flutter test

# Backend
cd Swiftlyft_backend
npm ci
npm run lint
npm run format
npm test

# Docker
docker build -t swiftlyft-backend .
```

