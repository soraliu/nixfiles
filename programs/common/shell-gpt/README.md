## Introduce

> [Github Repo](https://github.com/TheR1D/shell_gpt)

A command-line productivity tool powered by AI large language models (LLM). This command-line tool offers streamlined generation of shell commands, code snippets, documentation, eliminating the need for external resources (like Google search). Supports Linux, macOS, Windows and compatible with all major Shells like PowerShell, CMD, Bash, Zsh, etc.

## Useage

- Ask question once

```sh
sgpt "What is ChatGPT"
git diff --cached | sgpt "help me generate a unordered list of git commit message, for my changes" --no-cache
```

- Ask for shell commands

```sh
sgpt -s "find all json files in current folder"
```

- Shell Integration

```sh
sgpt --install-integration
```

or manually add codes into `~/.zshrc`

```sh
_sgpt_zsh() {
if [[ -n "$BUFFER" ]]; then
    _sgpt_prev_cmd=$BUFFER
    BUFFER+="⌛"
    zle -I && zle redisplay
    BUFFER=$(sgpt --shell <<< "$_sgpt_prev_cmd")
    zle end-of-line
fi
}
zle -N _sgpt_zsh
bindkey ^S _sgpt_zsh
```

- Chat Mode

```sh
sgpt --chat conversation_1 "please remember my favorite number: 4"
# -> I will remember that your favorite number is 4.
sgpt --chat conversation_1 "what would be my favorite number + 4?"
# -> Your favorite number is 4, so if we add 4 to it, the result would be 8.
```

- Repl Mode

```sh
sgpt --repl temp
# -> Entering REPL mode, press Ctrl+C to exit.
>>> What is REPL?
# -> REPL stands for Read-Eval-Print Loop. It is a programming environment ...
>>> How can I use Python with REPL?
# -> To use Python with REPL, you can simply open a terminal or command prompt ...
```
