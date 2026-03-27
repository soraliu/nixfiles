# AI Agent Rules and Guidelines

## WSL Command Execution Rule

When executing commands in WSL (Windows Subsystem for Linux) environments:

- **DO NOT** use `wsl -d {Ubuntu,NixOS}` from Windows PowerShell for every command
- **DO** directly use the appropriate terminal for the target operating system:
  - For Ubuntu/WSL commands: Use the Ubuntu/WSL terminal directly
  - For NixOS commands: Use the NixOS terminal directly
  - For Windows commands: Use PowerShell/Command Prompt directly

### Examples

❌ **Incorrect:**
```powershell
# From Windows PowerShell
wsl -d Ubuntu ls -la
wsl -d NixOS nix-store --query
```

✅ **Correct:**
```bash
# From Ubuntu/WSL terminal
ls -la

# From NixOS terminal  
nix-store --query
```

This approach ensures:
- Better performance and responsiveness
- Proper environment variable handling
- Correct path resolution
- Native shell features and completion
- Reduced overhead from WSL context switching
