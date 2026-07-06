# HFget

`hfget` is a tiny wrapper around the Hugging Face CLI that makes model downloads easier to organize.

Instead of manually picking folder names every time, you give it a Hugging Face repo ID and a base download directory. It downloads the model into a consistent folder name based on:

```text
<ModelName>-<RepoOwner>
```

So this:

```bash
hfget Qwen/Qwen3-4B-Thinking-2507 /mnt/world7/AI/Models/
```

downloads to:

```text
/mnt/world7/AI/Models/Qwen3-4B-Thinking-2507-Qwen
```

## Install

Linux one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/magiccodingman/HFget/main/install.sh | bash
```

The installer tries to install anything needed for `hfget`, including:

- `curl`
- `ca-certificates`
- `pipx`
- Hugging Face CLI through `pipx install huggingface-hub`

It currently attempts to support:

- Ubuntu
- Debian
- Fedora
- Arch Linux

Small note: I have personally tested this on Ubuntu. I tried to make it friendly for Debian, Fedora, and Arch too, but Ubuntu is the known-good path so far.

## Usage

Basic usage:

```bash
hfget <repo_id> <base_local_dir>
```

Example:

```bash
hfget Qwen/Qwen3-4B-Thinking-2507 /mnt/world7/AI/Models/
```

By default, `hfget` does **not** force re-download files. Existing completed files are reused/skipped by the Hugging Face CLI.

If you intentionally want to force a fresh download:

```bash
hfget --force Qwen/Qwen3-4B-Thinking-2507 /mnt/world7/AI/Models/
```

You can also run:

```bash
hfget --help
```

## Naming schema

`hfget` turns:

```text
owner/model-name
```

into:

```text
model-name-owner
```

Examples:

```text
Qwen/Qwen3-4B-Thinking-2507
```

becomes:

```text
Qwen3-4B-Thinking-2507-Qwen
```

And:

```text
unsloth/Qwen3-4B-Instruct-2507
```

becomes:

```text
Qwen3-4B-Instruct-2507-unsloth
```

This keeps model dumps easier to scan because the model name comes first, while still preserving the repo owner/source at the end.

## Uninstall

From a cloned copy of this repo:

```bash
./uninstall.sh
```

Or directly:

```bash
curl -fsSL https://raw.githubusercontent.com/magiccodingman/HFget/main/uninstall.sh | bash
```

The uninstaller removes the global `hfget` command from `/usr/local/bin/hfget`.

It does **not** remove `pipx` or the Hugging Face CLI by default, since other tools may use them. If you want to also remove `huggingface-hub` from `pipx`:

```bash
curl -fsSL https://raw.githubusercontent.com/magiccodingman/HFget/main/uninstall.sh | bash -s -- --purge-hf
```

## Why this exists

This is a small tool I use for easier, faster, and more organized AI model downloads. I tend to download lots of AI models in dumps, and this pattern helped me streamline the process without constantly hand-naming folders.
