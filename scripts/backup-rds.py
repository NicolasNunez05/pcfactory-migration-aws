import boto3
import json
from datetime import datetime

rds = boto3.client("rds")
s3 = boto3.client("s3")

def lambda_handler(event, context):
    """Crear backup de RDS y exportar a S3"""
    
    db_instance = "pcfactory-db"
    snapshot_id = f"{db_instance}-snapshot-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
    
    try:
        # Crear snapshot
        print(f"Creating snapshot: {snapshot_id}")
        response = rds.create_db_snapshot(
            DBSnapshotIdentifier=snapshot_id,
            DBInstanceIdentifier=db_instance,
            Tags=[
                {"Key": "AutoBackup", "Value": "True"},
                {"Key": "Project", "Value": "PCFactory"}
            ]
        )
        
        print(f" Snapshot created: {snapshot_id}")
        
        # Exportar a S3
        export_id = f"{db_instance}-export-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
        
        rds.start_export_task(
            ExportTaskIdentifier=export_id,
            SourceArn=response["DBSnapshot"]["DBSnapshotArn"],
            S3BucketName="pcfactory-backups",
            S3Prefix=f"rds-exports/{datetime.now().strftime('%Y/%m/%d')}/",
            IamRoleArn="arn:aws:iam::787124622819:role/RDSExportRole",
            ExportOnly=[]
        )
        
        print(f" Export task started: {export_id}")
        
        return {
            "statusCode": 200,
            "body": json.dumps({
                "snapshot": snapshot_id,
                "export": export_id,
                "message": "Backup successful"
            })
        }
    
    except Exception as e:
        print(f" Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
