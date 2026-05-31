# Android Release Signing Setup

This document explains how to configure Android release signing for the ScanAiRZ application in GitHub Actions.

## Overview

The build-release.yml workflow supports both release and debug builds:
- **Release builds**: Signed with a proper keystore for production distribution
- **Debug builds**: Unsigned, for development/testing purposes

If GitHub Secrets are not configured, the workflow will automatically fall back to debug builds.

## Required GitHub Secrets

To enable release signing, you need to add the following secrets to your GitHub repository:

1. `KEYSTORE_BASE64` - Base64 encoded keystore file
2. `KEYSTORE_PASSWORD` - Password for the keystore
3. `KEY_ALIAS` - Key alias name
4. `KEY_PASSWORD` - Password for the key

## How to Generate and Configure the Keystore

### Step 1: Generate a Keystore

```bash
keytool -genkey -v -keystore scanairz-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias scanairz-key
```

### Step 2: Encode Keystore to Base64

```bash
base64 -i scanairz-key.jks -o scanairz-key.base64
```

### Step 3: Add Secrets to GitHub

1. Go to your repository on GitHub
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret" for each of the following:
   - `KEYSTORE_BASE64` - Content of scanairz-key.base64 file
   - `KEYSTORE_PASSWORD` - Password used when generating the keystore
   - `KEY_ALIAS` - The alias name (e.g., "scanairz-key")
   - `KEY_PASSWORD` - Password for the key

## Workflow Behavior

- If all secrets are present: Build uses release signing
- If any secret is missing: Build falls back to debug build
- Debug builds are unsigned and suitable for development/testing
- Release builds are properly signed for production distribution

## Testing the Setup

After adding the secrets:
1. Push a change to the main branch
2. Monitor the GitHub Actions workflow
3. Verify that the build uses release signing
4. Check that the generated APK is properly signed

## Troubleshooting

### Common Issues

1. **Build fails with signing errors**: Verify all secrets are correctly set
2. **Build falls back to debug**: Check that all required secrets are present
3. **Base64 encoding issues**: Ensure the keystore file is properly encoded

### Verification

You can verify a signed APK using:
```bash
keytool -list -keystore scanairz-key.jks
```

## Security Notes

- Keep your keystore file secure and never commit it to version control
- The base64 encoded version should be stored as a GitHub secret
- Regularly rotate your keystore passwords for security