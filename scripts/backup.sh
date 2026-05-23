#!/bin/bash
set -e

NAMESPACE="skillpulse"
POD="mysql-0"
BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/skillpulse-$TIMESTAMP.sql"

echo "==================================="
echo " SkillPulse MySQL Backup"
echo "==================================="
echo

echo "[1/3] Creating backup directory..."
mkdir -p $BACKUP_DIR
echo

echo "[2/3] Taking MySQL dump..."
# FIX: redirect must be on the SAME line as the command
kubectl exec -n $NAMESPACE $POD -- \
  mysqldump --no-tablespaces -uskillpulse -pskillpulse123 skillpulse > "$BACKUP_FILE"

# verify file is non-empty
if [ ! -s "$BACKUP_FILE" ]; then
  echo "ERROR: Backup file is empty. Something went wrong."
  exit 1
fi
echo

echo "[3/3] Backup completed successfully."
echo
echo "Backup saved at:"
echo "$BACKUP_FILE"
echo "Size: $(du -sh "$BACKUP_FILE" | cut -f1)"