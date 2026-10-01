#!/usr/bin/env python3

import os
import sys
import subprocess
import shutil
import argparse
import time
import logging
import re
from datetime import datetime
from pathlib import Path
from collections import defaultdict

def setup_audit_logging():
    log_dir = os.path.expanduser("~/.agent-cleanup-backup")
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, "cleanup_audit.log")
    
    logger = logging.getLogger("cleanup_audit")
    logger.setLevel(logging.INFO)
    
    if not logger.handlers:
        fh = logging.FileHandler(log_file)
        fh.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
        logger.addHandler(fh)
        
    return logger

def run_cmd(cmd_list, cwd=None, capture=True):
    try:
        result = subprocess.run(cmd_list, cwd=cwd, text=True, capture_output=capture)
        return result.stdout.strip() if capture else result.returncode
    except Exception as e:
        return ""

def find_git_repos(root_dir):
    if os.path.isdir(os.path.join(root_dir, ".git")):
        return [os.path.abspath(root_dir)]
        
    if shutil.which("fd"):
        cmd_list = ["fd", "-H", "-t", "d", "^\\.git$", root_dir]
    else:
        cmd_list = ["find", root_dir, "-type", "d", "(", "-name", ".git", "-o", "-name", "node_modules", ")", "-prune", "-o", "-name", ".git", "-print"]
        
    out = run_cmd(cmd_list)
    if not out:
        return []
        
    repos = []
    for line in out.split('\n'):
        if line.strip():
            repo_path = os.path.dirname(line.strip())
            repos.append(repo_path)
    return repos

def get_git_worktrees(repo_path):
    out = run_cmd(["git", "worktree", "list", "--porcelain"], cwd=repo_path)
    if not out:
        return []
    
    worktrees = []
    current_wt = {}
    
    for line in out.split("\n"):
        line = line.strip()
        if not line:
            if current_wt and "path" in current_wt:
                worktrees.append(current_wt)
            current_wt = {}
            continue
            
        if line.startswith("worktree "):
            current_wt["path"] = line.split(" ", 1)[1]
        elif line.startswith("branch "):
            current_wt["branch"] = line.split(" ", 1)[1].replace("refs/heads/", "")
        elif line.startswith("detached"):
            current_wt["branch"] = "detached"
            
    if current_wt and "path" in current_wt:
        worktrees.append(current_wt)
        
    if worktrees:
        worktrees = worktrees[1:]
        
    for wt in worktrees:
        wt["repo"] = repo_path
        
    return worktrees

def get_worktree_status(path):
    out = run_cmd(["git", "status", "--porcelain"], cwd=path)
    if not out:
        return "Clean (0 uncommitted)"
    
    lines = out.split("\n")
    modified = len([l for l in lines if l.strip() and not l.startswith('??')])
    untracked = len([l for l in lines if l.startswith('??')])
    
    return f"{modified} modified, {untracked} untracked"

def get_upstream_status(path):
    out = run_cmd(["git", "rev-list", "--left-right", "--count", "HEAD...@{u}"], cwd=path)
    if out and "fatal:" not in out:
        parts = out.split()
        if len(parts) == 2:
            return f"{parts[0]} commit(s) not on GitHub, behind by {parts[1]}"
            
    fallback_out = run_cmd(["git", "rev-list", "--count", "HEAD", "^origin/main"], cwd=path)
    if fallback_out and fallback_out.isdigit():
        if int(fallback_out) > 0:
            return f"{fallback_out} commit(s) ahead of origin/main (Not on GitHub)"
        else:
            return "No unique commits vs origin/main"
            
    return "No upstream configured"

def format_timestamp(ts):
    return datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')

def is_active(mtime, threshold_hours=2):
    age_hours = (time.time() - mtime) / 3600
    return age_hours < threshold_hours

def parse_duration(duration_str):
    if not duration_str:
        return 0.0
        
    match = re.match(r"^([\d\.]+)([mhdwy]*)$", str(duration_str).strip().lower())
    if not match:
        raise argparse.ArgumentTypeError(f"Invalid duration format: '{duration_str}'. Use format like 30m, 24h, 5d, 2w.")
        
    val = float(match.group(1))
    unit = match.group(2)
    
    if unit == 'm': return val / 60.0
    elif unit == 'd': return val * 24.0
    elif unit == 'w': return val * 24.0 * 7.0
    elif unit == 'y': return val * 24.0 * 365.25
    else: return val 

def get_item_preview(item, is_dir):
    size_out = run_cmd(["du", "-sh", item])
    size_str = size_out.split()[0] if size_out else "?"
    
    extra_info = ""
    
    if is_dir:
        git_remote = run_cmd(["git", "config", "--get", "remote.origin.url"], cwd=item)
        if git_remote:
            clean_url = git_remote.replace("git@github.com:", "").replace("https://github.com/", "").replace(".git", "")
            extra_info = f" | Remote: {clean_url}"
            
        try:
            contents = os.listdir(item)
            sample = ", ".join(contents[:4]) + ("..." if len(contents) > 4 else "")
            if not sample: sample = "Empty directory"
            return f"Dir ({size_str}){extra_info} | Contents: [{sample}]"
        except Exception:
            return f"Dir ({size_str}){extra_info} | Unreadable"
    else:
        try:
            if os.path.getsize(item) == 0:
                return f"File (0B) | Empty file"
            with open(item, 'r', errors='ignore') as f:
                first_line = f.readline().strip()
                sample = first_line[:60] + "..." if len(first_line) > 60 else first_line
            return f"File ({size_str}) | Preview: \"{sample}\""
        except Exception:
            return f"File ({size_str}) | Unreadable/Binary"

def scan_stray_agent_files(root_dir):
    stray_items = []
    if shutil.which("fd"):
        regex = r"^\.claude$|^\.aider.*$|^\.cursor.*$|^\.gemini$|^agent-workspace.*$|.*\.agent\.log$|^nav-pilot-e2e-bin.*$|^tmp\..*$|^wt-.*$"
        cmd_list = ["fd", "-H", "-a", regex, root_dir]
        out = run_cmd(cmd_list)
        if out:
            for line in out.split("\n"):
                clean_line = line.strip()
                if clean_line:
                    stray_items.append(clean_line)
    else:
        patterns = [
            ".aider*", ".claude", ".cursor", ".cursorrules", ".gemini", 
            "agent-workspace*", "*.agent.log", "nav-pilot-e2e-bin*", "tmp.*", "wt-*"
        ]
        for pattern in patterns:
            cmd_list = ["find", root_dir, "-type", "d", "(", "-name", ".git", "-o", "-name", "node_modules", ")", "-prune", "-o", "-name", pattern, "-print"]
            out = run_cmd(cmd_list)
            if out:
                for line in out.split("\n"):
                    clean_line = line.strip()
                    if clean_line and clean_line not in stray_items:
                        stray_items.append(clean_line)
    return stray_items

def is_safe_global(path):
    safe_globals = [
        os.path.expanduser("~/.gemini"),
        os.path.expanduser("~/.claude"),
        os.path.expanduser("~/.cursor")
    ]
    for sg in safe_globals:
        if path == sg or path.startswith(sg + os.sep):
            return True
    return False

def main():
    parser = argparse.ArgumentParser(description="Clean up agent worktrees and stray files safely.")
    parser.add_argument("paths", nargs="*", help="Target directories or specific repos to scan.")
    parser.add_argument("--dry-run", action="store_true", help="Print actions without executing them")
    parser.add_argument("--min-age", type=parse_duration, default=0.0, help="Minimum age (e.g. 30m, 24h, 5d, 2w)")
    parser.add_argument("--repo", "-r", help="Directly target a specific git repository")
    parser.add_argument("--auto", action="store_true", help="Unattended mode: automatically deletes all matches safely without prompting")
    args = parser.add_argument_parse() if hasattr(parser, 'add_argument_parse') else parser.parse_args()
    
    logger = setup_audit_logging()
    
    targets = []
    if args.repo: targets.append(os.path.abspath(args.repo))
    for p in args.paths: targets.append(os.path.abspath(p))
        
    if not targets:
        targets.append(os.path.abspath("."))
        mac_tmpdir = os.environ.get("TMPDIR", "/tmp")
        for extra in [mac_tmpdir, "/private/tmp", os.path.expanduser("~/tmp")]:
            if os.path.exists(extra) and extra not in targets:
                targets.append(extra)
            
    print("========================================")
    print(f"🤖 Agent Worktree & File Cleanup Script")
    if args.dry_run: print("🛡️  DRY RUN MODE ENABLED - No changes will be made")
    if args.auto: print("⚡ AUTO MODE ENABLED - Running completely unattended")
    
    raw_age_arg = None
    for i, arg in enumerate(sys.argv):
        if arg.startswith("--min-age="): raw_age_arg = arg.split("=")[1]
        elif arg == "--min-age" and i + 1 < len(sys.argv): raw_age_arg = sys.argv[i+1]
        
    if args.min_age > 0: 
        display_age = raw_age_arg if raw_age_arg else f"{args.min_age:g}h"
        print(f"⏳ Filter: Only showing items older than {display_age}")
        
    print(f"🎯 Targets: {', '.join(targets)}")
    print("========================================")
    
    all_secondary_worktrees = []
    strays = []
    
    for target_dir in targets:
        print(f"\nScanning {target_dir}...")
        repos = find_git_repos(target_dir)
        for repo in repos:
            all_secondary_worktrees.extend(get_git_worktrees(repo))
        strays.extend(scan_stray_agent_files(target_dir))
    
    prune_repos = set()
    
    # -- Worktree Cleanup --
    if not all_secondary_worktrees:
        print("\nNo secondary git worktrees found.")
    else:
        filtered_worktrees = []
        for wt in all_secondary_worktrees:
            if not os.path.exists(wt['path']): continue
            mtime = os.path.getmtime(wt['path'])
            if args.min_age > 0 and ((time.time() - mtime) / 3600) < args.min_age: continue
            filtered_worktrees.append(wt)
            
        if not filtered_worktrees:
            print(f"\nFound {len(all_secondary_worktrees)} worktree(s), but none match the minimum age filter.")
        else:
            total_wt = len(filtered_worktrees)
            print(f"\nFound {total_wt} secondary git worktree(s).")
            for i, wt in enumerate(filtered_worktrees, 1):
                path = wt['path']
                branch = wt.get('branch', 'detached')
                repo = wt['repo']
                mtime = os.path.getmtime(path)
                active_warn = " ⚠️ ACTIVE" if is_active(mtime) else ""
                
                print(f"\n[Worktree {i}/{total_wt}]")
                print(f"Repo    : {repo}")
                print(f"Worktree: {path}")
                print(f"Branch  : {branch}")
                print(f"Last Mod: {format_timestamp(mtime)}{active_warn}")
                print(f"Status  : {get_worktree_status(path)}")
                
                while True:
                    if args.auto:
                        choice = 'b'
                        print("Auto-action: Backup & Delete")
                    else:
                        choice = input("Action [v]iew, [b]ackup & delete, [d]elete, [s]kip, [q]uit? (default: s): ").strip().lower()
                        
                    if choice == 'q': return
                    elif choice == 'v':
                        subprocess.run(["ls", "-la", path])
                        subprocess.run(["git", "status"], cwd=path)
                    elif choice in ('b', 'backup'):
                        if args.dry_run:
                            print("[DRY RUN] Would backup and delete worktree.")
                            break
                        branch_name = branch.replace('/', '-') if branch != 'detached' else os.path.basename(path)
                        ref_name = f"refs/backup/cleanup-{branch_name}-{int(time.time())}"
                        print(f"Saving commits to {ref_name}...")
                        run_cmd(["git", "update-ref", ref_name, "HEAD"], cwd=path)
                        logger.info(f"Backed up commit from {path} to {ref_name} in {repo}")
                        
                        out = run_cmd(["git", "status", "--porcelain", "-z"], cwd=path)
                        if out:
                            untracked = [item[3:] for item in out.split('\0') if item.startswith('?? ')]
                            if untracked:
                                backup_dir = os.path.expanduser(f"~/.agent-cleanup-backup/{branch_name}")
                                os.makedirs(backup_dir, exist_ok=True)
                                
                                backed_up_count = 0
                                for f in untracked:
                                    src = os.path.join(path, f)
                                    dst = os.path.abspath(os.path.join(backup_dir, f))
                                    if not dst.startswith(os.path.abspath(backup_dir)): continue
                                    if os.path.exists(src):
                                        os.makedirs(os.path.dirname(dst), exist_ok=True)
                                        if os.path.isdir(src): shutil.copytree(src, dst, dirs_exist_ok=True)
                                        else: shutil.copy2(src, dst)
                                        backed_up_count += 1
                                        
                                if backed_up_count > 0:
                                    print(f"Backed up {backed_up_count} untracked file(s) to {backup_dir}...")
                                
                        print(f"Deleting worktree at {path}...")
                        run_cmd(["git", "worktree", "remove", "--force", path], cwd=repo, capture=False)
                        logger.info(f"Deleted worktree: {path}")
                        prune_repos.add(repo)
                        break
                    elif choice in ('d', 'y', 'yes'):
                        if args.dry_run:
                            print("[DRY RUN] Would force delete worktree.")
                            break
                        run_cmd(["git", "worktree", "remove", "--force", path], cwd=repo, capture=False)
                        logger.info(f"Deleted worktree without backup: {path}")
                        prune_repos.add(repo)
                        break
                    elif choice in ('s', ''): break

    if prune_repos and not args.dry_run:
        print("\n🧹 Pruning git administrative files for removed worktrees...")
        for repo in prune_repos:
            run_cmd(["git", "worktree", "prune"], cwd=repo)
            logger.info(f"Ran git worktree prune in {repo}")

    # -- Stray File Cleanup --
    strays = [s for s in strays if not is_safe_global(s) and "/.git/" not in s]
    
    if not strays:
        print("\nNo stray agent files found.")
    else:
        filtered_strays = []
        for item in strays:
            if not os.path.exists(item): continue
            mtime = os.path.getmtime(item)
            if args.min_age > 0 and ((time.time() - mtime) / 3600) < args.min_age: continue
            filtered_strays.append(item)
            
        total_strays = len(filtered_strays)
        if total_strays == 0:
            print(f"\nFound {len(strays)} stray file(s), but none match the minimum age filter.")
        else:
            print(f"\n🔍 Found {total_strays} potential stray agent files/directories.")
            
            # --- SMART ANALYSIS: Grouping ---
            groups = defaultdict(list)
            singles = []
            
            for item in filtered_strays:
                # FIX: Strip trailing slashes so basename works correctly for directories
                clean_item = item.rstrip(os.sep)
                parent = os.path.dirname(clean_item)
                basename = os.path.basename(clean_item)
                
                # REFINED REGEX: Greedily capture all text and hyphens to group 'nav-pilot-e2e-bin'
                prefix_match = re.match(r"^([a-zA-Z_-]+[.-]?)", basename)
                if prefix_match:
                    prefix = prefix_match.group(1)
                    groups[(parent, prefix)].append(item)
                else:
                    singles.append(item)
                    
            bulk_groups = {}
            for k, items in groups.items():
                if len(items) > 1:
                    bulk_groups[k] = items
                else:
                    singles.extend(items)
            
            if bulk_groups:
                print(f"\n📊 SMART ANALYSIS: Grouped {sum(len(v) for v in bulk_groups.values())} files into {len(bulk_groups)} patterns.")
                for (parent, prefix), items in bulk_groups.items():
                    sample_item = items[0]
                    is_dir = os.path.isdir(sample_item)
                    
                    print(f"\n📦 GROUP: {len(items)} items matching '{prefix}*' in {parent}")
                    print(f"Sample: {get_item_preview(sample_item, is_dir)}")
                    
                    while True:
                        if args.auto:
                            choice = 'd'
                            print("Auto-action: Delete Group")
                        else:
                            choice = input(f"Action [v]iew sample, [d]elete ALL {len(items)}, [s]kip group, [q]uit? (default: s): ").strip().lower()
                            
                        if choice == 'q': return
                        elif choice == 'v':
                            if is_dir: subprocess.run(["ls", "-la", sample_item])
                            else: subprocess.run(["head", "-n", "20", sample_item])
                        elif choice in ('d', 'y', 'yes'):
                            if args.dry_run:
                                print(f"[DRY RUN] Would delete {len(items)} items.")
                                break
                            
                            deleted_count = 0
                            for f in items:
                                if os.path.isdir(f):
                                    try: shutil.rmtree(f, ignore_errors=True); deleted_count += 1
                                    except: pass
                                else:
                                    try: os.remove(f); deleted_count += 1
                                    except: pass
                                    
                            print(f"Deleted {deleted_count} items.")
                            logger.info(f"Bulk deleted {deleted_count} items matching '{prefix}*' in {parent}")
                            break
                        elif choice in ('s', ''):
                            print(f"Skipped {len(items)} items.")
                            break
                            
            if singles:
                print(f"\n--- Processing {len(singles)} individual stray item(s) ---")
                for i, item in enumerate(singles, 1):
                    if not os.path.exists(item): continue
                    mtime = os.path.getmtime(item)
                    active_warn = " ⚠️ ACTIVE" if is_active(mtime) else ""
                    is_dir = os.path.isdir(item)
                    
                    clean_item = item.rstrip(os.sep)
                    basename = os.path.basename(clean_item)
                    
                    print(f"\n[Item {i}/{len(singles)}]: {item}")
                    print(f"Info: {get_item_preview(item, is_dir)}")
                    print(f"Mod : {format_timestamp(mtime)}{active_warn}")
                    
                    while True:
                        prefix_match = re.match(r"^([a-zA-Z_-]+[.-]?)", basename)
                        if args.auto:
                            choice = 'd'
                            print("Auto-action: Delete")
                        else:
                            prompt = "Action [v]iew, [d]elete, [s]kip"
                            if prefix_match:
                                prompt += f", [a]uto-delete all '{prefix_match.group(1)}*'"
                            prompt += ", [q]uit? (default: s): "
                            choice = input(prompt).strip().lower()
                            
                        if choice == 'q': return
                        elif choice == 'v':
                            if is_dir: subprocess.run(["ls", "-la", item])
                            else: subprocess.run(["head", "-n", "20", item])
                        elif choice == 'a' and prefix_match:
                            auto_delete_prefix = prefix_match.group(1)
                            print(f"Auto-deleting {item} and subsequent '{auto_delete_prefix}*' items...")
                            if args.dry_run:
                                print(f"[DRY RUN] Would auto-delete {item}")
                                break
                            if is_dir: shutil.rmtree(item, ignore_errors=True)
                            else: 
                                try: os.remove(item)
                                except: pass
                            logger.info(f"Deleted stray directory: {item}")
                            break
                        elif choice in ('d', 'y', 'yes'):
                            if args.dry_run:
                                print(f"[DRY RUN] Would delete {item}")
                                break
                            if is_dir:
                                try:
                                    shutil.rmtree(item)
                                    logger.info(f"Deleted stray directory: {item}")
                                    print("Deleted directory.")
                                except Exception as e: print(f"Failed to delete directory: {e}")
                            else:
                                try:
                                    os.remove(item)
                                    logger.info(f"Deleted stray file: {item}")
                                    print("Deleted file.")
                                except Exception as e: print(f"Failed to delete file: {e}")
                            break
                        elif choice in ('s', ''): break

    print("\nCleanup complete! 🧹")
    print(f"Audit log saved to: ~/.agent-cleanup-backup/cleanup_audit.log")

if __name__ == "__main__":
    main()
