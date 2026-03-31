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

## vLLM Configuration

### Quick Reference

For detailed vLLM configuration guidelines, troubleshooting, and best practices in WSL Ubuntu environment, see:

**📖 [WSL Ubuntu vLLM Configuration Guide](./docs/agents/wsl-ubuntu-vllm.md)**

### JIT Cache Cleanup Rule

When vLLM model startup fails in `@home/modules/ai/vllm/models/flake.nix`:

- **Automatically clean JIT cache directories**:
  - `~/.cache/flashinfer`
  - `~/.cache/vllm/torch_compile_cache`

- **Cleanup command**: `rm -rf ~/.cache/flashinfer ~/.cache/vllm/torch_compile_cache`

- **When to apply**: Execute cleanup immediately after model startup failure before retry

This resolves Triton JIT compilation errors and stale cache issues.
