#!/bin/bash

# -------------------------
# Backdated Commit Script
# -------------------------

# Configuration
REPO_DIR="."
MAIN_BRANCH="main"
START_DATE="2025-04-01"
END_DATE="2025-04-30"
TOTAL_COMMITS=50
MIN_HOUR=21  # 9 PM
MAX_HOUR=23  # 11 PM
FILES=("file1.txt" "file2.txt" "file3.txt" "file4.txt")
COMMIT_FILE="commit_log.txt"

# -------------------------
# Functions
# -------------------------
function error_exit {
    echo "Error: $1"
    exit 1
}

function check_git_repo {
    git rev-parse --is-inside-work-tree &>/dev/null || error_exit "Not a git repository!"
}

function check_remote {
    git remote get-url origin &>/dev/null || error_exit "Remote 'origin' not found!"
}

# -------------------------
# User Confirmation
# -------------------------
echo "This script will create $TOTAL_COMMITS backdated commits between $START_DATE and $END_DATE."
echo "All commits will be between $MIN_HOUR:00 and $MAX_HOUR:59."
echo "Files updated: ${FILES[*]}"
read -p "Do you want to proceed? (y/n): " CONFIRM
[[ "$CONFIRM" != "y" ]] && echo "Aborted." && exit 0

# -------------------------
# Checks
# -------------------------
cd "$REPO_DIR" || error_exit "Cannot enter repo directory."
check_git_repo
check_remote

# -------------------------
# Create branch
# -------------------------
BRANCH_NAME="backdate-commits-$(date +%s)"
git checkout -b "$BRANCH_NAME" || error_exit "Failed to create branch."

# -------------------------
# Generate commit dates
# -------------------------
declare -a COMMIT_DATES
for i in $(seq 1 $TOTAL_COMMITS); do
    random_date=$(shuf -n 1 -i $(date -d "$START_DATE" +%s)-$(date -d "$END_DATE" +%s))
    formatted_date=$(date -d "@$random_date" +"%Y-%m-%d")
    random_hour=$(shuf -n 1 -i $MIN_HOUR-$MAX_HOUR)
    random_minute=$(shuf -n 1 -i 0-59)
    random_second=$(shuf -n 1 -i 0-59)
    commit_date="${formatted_date} ${random_hour}:${random_minute}:${random_second}"
    COMMIT_DATES+=("$commit_date")
done

# Sort commit dates
IFS=$'\n' COMMIT_DATES=($(printf "%s\n" "${COMMIT_DATES[@]}" | sort))
unset IFS

# -------------------------
# Create commits
# -------------------------
for idx in "${!COMMIT_DATES[@]}"; do
    commit_date="${COMMIT_DATES[$idx]}"
    echo "Creating commit $((idx+1))/$TOTAL_COMMITS for $commit_date"

    # Update each file with unique content
    for file in "${FILES[@]}"; do
        echo "Update $(date +%s) at $commit_date" >> "$file"
    done

    # Commit changes
    git add "${FILES[@]}"
    GIT_AUTHOR_DATE="$commit_date" GIT_COMMITTER_DATE="$commit_date" \
        git commit -m "Backdated commit $((idx+1)) on $commit_date" \
        || echo "Failed to commit at $commit_date"

    sleep 1  # small delay
done

# -------------------------
# Merge and push
# -------------------------
git checkout "$MAIN_BRANCH" || error_exit "Cannot switch to $MAIN_BRANCH."
git merge "$BRANCH_NAME" || error_exit "Merge failed."
git push origin "$MAIN_BRANCH" || error_exit "Push failed."

# Cleanup
git branch -d "$BRANCH_NAME"

echo "Backdated commits created and pushed successfully!"
