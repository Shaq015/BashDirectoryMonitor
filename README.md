# BashDirectoryMonitor

This is a Bash script that monitors a specified directory and reports changes between executions — specifically added or deleted files and folders.

## Project Description

The script simulates a "Big Brother" process, tracking a target folder for any changes between runs. It reports:
- Added files/folders to `stdout`
- Deleted files/folders to `stderr`

Changes are detected **only** at the top level (not recursively).

## How to Use

```bash
chmod +x bigBrother.sh
./bigBrother.sh <directory_path> [optional: list of files or directories to monitor]
```

## Example Usage

./bigBrother.sh ~/Documents

./bigBrother.sh abc/ a.txt b
