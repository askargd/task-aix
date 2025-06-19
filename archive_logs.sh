#!/bin/bash

# Log Archive and S3 Upload Script
# Purpose: Archive /var/log files daily and upload to S3

# Configuration
LOG_SOURCE_DIR="/var/log"
ARCHIVE_DIR="/var/log/archives"
S3_BUCKET="logs-ec2-dev-askar011"  # Replace with your S3 bucket name
S3_PREFIX="ec2-logs/$(hostname)"     # S3 path prefix
RETENTION_DAYS=7                     # Keep local archives for 7 days
LOG_FILE="/var/log/log-archiver.log"

# Create timestamp for archive
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_NAME="logs_${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${ARCHIVE_DIR}/${ARCHIVE_NAME}"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

# Function to check if AWS CLI is configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_message "ERROR: AWS CLI not found. Please install AWS CLI."
        exit 1
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        log_message "ERROR: AWS CLI not configured properly. Check IAM permissions."
        exit 1
    fi
}

# Function to create archive directory
create_archive_dir() {
    if [ ! -d "${ARCHIVE_DIR}" ]; then
        mkdir -p "${ARCHIVE_DIR}"
        log_message "Created archive directory: ${ARCHIVE_DIR}"
    fi
}

# Function to create log archive
create_archive() {
    log_message "Starting log archive creation..."

    # Create temporary directory for logs to archive
    TEMP_DIR=$(mktemp -d)

    # Copy rotated logs (exclude current active logs and our own log file)
    find "${LOG_SOURCE_DIR}" -type f \
        ! -name "log-archiver.log*" \
        -exec cp {} "${TEMP_DIR}/" \; 2>/dev/null

    # Check if we have files to archive
    if [ -z "$(ls -A ${TEMP_DIR})" ]; then
        log_message "WARNING: No rotated log files found to archive"
        rm -rf "${TEMP_DIR}"
        return 1
    fi

    # Create compressed archive
    if tar -czf "${ARCHIVE_PATH}" -C "${TEMP_DIR}" .; then
        log_message "Archive created successfully: ${ARCHIVE_PATH}"
        ARCHIVE_SIZE=$(du -h "${ARCHIVE_PATH}" | cut -f1)
        log_message "Archive size: ${ARCHIVE_SIZE}"
    else
        log_message "ERROR: Failed to create archive"
        rm -rf "${TEMP_DIR}"
        return 1
    fi

    # Cleanup temporary directory
    rm -rf "${TEMP_DIR}"
    return 0
}

# Function to upload archive to S3
upload_to_s3() {
    local archive_file="$1"
    local s3_key="${S3_PREFIX}/$(date +%Y/%m/%d)/${ARCHIVE_NAME}"

    log_message "Uploading archive to S3: s3://${S3_BUCKET}/${s3_key}"

    if aws s3 cp "${archive_file}" "s3://${S3_BUCKET}/${s3_key}" \
        --storage-class STANDARD_IA \
        --metadata "hostname=$(hostname),timestamp=${TIMESTAMP}"; then
        log_message "Successfully uploaded to S3: s3://${S3_BUCKET}/${s3_key}"
        return 0
    else
        log_message "ERROR: Failed to upload to S3"
        return 1
    fi
}

# Function to cleanup old local archives
cleanup_old_archives() {
    log_message "Cleaning up local archives older than ${RETENTION_DAYS} days..."

    find "${ARCHIVE_DIR}" -name "logs_*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete

    if [ $? -eq 0 ]; then
        log_message "Old archives cleanup completed"
    else
        log_message "WARNING: Issues during cleanup"
    fi
}

# Function to send notification (optional)
send_notification() {
    local status="$1"
    local message="$2"

    # You can customize this to send SNS notifications, emails, etc.
    log_message "NOTIFICATION: ${status} - ${message}"

    # Example SNS notification (uncomment and configure if needed)
    # aws sns publish --topic-arn "arn:aws:sns:region:account:log-archive-notifications" \
    #     --message "${message}" --subject "Log Archive ${status}"
}

# Main execution
main() {
    log_message "Starting log archiving process..."

    # Check prerequisites
    check_aws_cli
    create_archive_dir

    # Create archive
    if create_archive; then
        # Upload to S3
        if upload_to_s3 "${ARCHIVE_PATH}"; then
            send_notification "SUCCESS" "Log archive uploaded successfully: ${ARCHIVE_NAME}"

            # Cleanup old archives
            cleanup_old_archives

            log_message "Log archiving process completed successfully"
        else
            send_notification "FAILED" "Failed to upload log archive to S3: ${ARCHIVE_NAME}"
            log_message "Log archiving process failed during S3 upload"
            exit 1
        fi
    else
        send_notification "FAILED" "Failed to create log archive"
        log_message "Log archiving process failed during archive creation"
        exit 1
    fi
}

# Execute main function
main "$@"