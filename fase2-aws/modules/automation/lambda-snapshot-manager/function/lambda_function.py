"""
Lambda Function: RDS Snapshot Manager
Crea snapshots automáticos de RDS y gestiona retención
Trigger: EventBridge (schedule)
"""

import json
import boto3
import os
from datetime import datetime, timedelta

rds = boto3.client('rds')
sns = boto3.client('sns')

PROJECT_NAME = os.environ.get('PROJECT_NAME', 'pcfactory')
NOTIFICATION_TOPIC = os.environ.get('NOTIFICATION_TOPIC_ARN', '')
RETENTION_DAYS = int(os.environ.get('RETENTION_DAYS', '7'))

def lambda_handler(event, context):
    """
    Crea snapshot de RDS y elimina snapshots antiguos
    """
    print(f"Iniciando creación de snapshot...")
    print(f"Retention days: {RETENTION_DAYS}")
    
    results = {
        'snapshots_created': [],
        'snapshots_deleted': [],
        'errors': []
    }
    
    try:
        # Obtener todas las instancias RDS del proyecto
        db_instances = get_project_db_instances()
        
        for db_instance_id in db_instances:
            # Crear snapshot
            snapshot_result = create_snapshot(db_instance_id)
            if snapshot_result['success']:
                results['snapshots_created'].append(snapshot_result['snapshot_id'])
            else:
                results['errors'].append(snapshot_result['error'])
            
            # Limpiar snapshots antiguos
            deleted = cleanup_old_snapshots(db_instance_id)
            results['snapshots_deleted'].extend(deleted)
        
        # Notificar resultado
        notify_results(results)
        
        return {
            'statusCode': 200,
            'body': json.dumps(results)
        }
        
    except Exception as e:
        print(f"✗ Error en snapshot manager: {str(e)}")
        results['errors'].append(str(e))
        return {
            'statusCode': 500,
            'body': json.dumps(results)
        }

def get_project_db_instances():
    """Obtiene lista de instancias RDS del proyecto"""
    try:
        response = rds.describe_db_instances()
        
        # Filtrar solo instancias del proyecto
        project_instances = []
        for db_instance in response['DBInstances']:
            db_id = db_instance['DBInstanceIdentifier']
            # Verificar si el nombre contiene el nombre del proyecto
            if PROJECT_NAME in db_id:
                project_instances.append(db_id)
        
        print(f"✓ {len(project_instances)} instancias RDS encontradas: {project_instances}")
        return project_instances
        
    except Exception as e:
        print(f"✗ Error obteniendo instancias RDS: {str(e)}")
        return []

def create_snapshot(db_instance_id):
    """Crea un snapshot manual de la instancia RDS"""
    timestamp = datetime.now().strftime('%Y-%m-%d-%H-%M')
    snapshot_id = f"{db_instance_id}-auto-{timestamp}"
    
    try:
        print(f"Creando snapshot: {snapshot_id}")
        
        response = rds.create_db_snapshot(
            DBSnapshotIdentifier=snapshot_id,
            DBInstanceIdentifier=db_instance_id,
            Tags=[
                {'Key': 'Type', 'Value': 'Automated'},
                {'Key': 'CreatedBy', 'Value': 'Lambda'},
                {'Key': 'Project', 'Value': PROJECT_NAME},
                {'Key': 'Timestamp', 'Value': timestamp}
            ]
        )
        
        print(f"✓ Snapshot creado: {snapshot_id}")
        return {
            'success': True,
            'snapshot_id': snapshot_id
        }
        
    except Exception as e:
        print(f"✗ Error creando snapshot: {str(e)}")
        return {
            'success': False,
            'error': str(e)
        }

def cleanup_old_snapshots(db_instance_id):
    """Elimina snapshots que exceden el período de retención"""
    deleted_snapshots = []
    cutoff_date = datetime.now() - timedelta(days=RETENTION_DAYS)
    
    try:
        # Obtener snapshots del DB instance
        response = rds.describe_db_snapshots(
            DBInstanceIdentifier=db_instance_id,
            SnapshotType='manual'
        )
        
        for snapshot in response['DBSnapshots']:
            snapshot_id = snapshot['DBSnapshotIdentifier']
            snapshot_time = snapshot['SnapshotCreateTime'].replace(tzinfo=None)
            
            # Verificar si es un snapshot automático (creado por Lambda)
            if '-auto-' not in snapshot_id:
                continue
            
            # Eliminar si es más antiguo que el período de retención
            if snapshot_time < cutoff_date:
                print(f"Eliminando snapshot antiguo: {snapshot_id} (creado {snapshot_time})")
                
                rds.delete_db_snapshot(DBSnapshotIdentifier=snapshot_id)
                deleted_snapshots.append(snapshot_id)
                print(f"✓ Snapshot eliminado: {snapshot_id}")
        
        if deleted_snapshots:
            print(f"✓ {len(deleted_snapshots)} snapshots antiguos eliminados")
        else:
            print("No hay snapshots antiguos para eliminar")
        
        return deleted_snapshots
        
    except Exception as e:
        print(f"✗ Error limpiando snapshots: {str(e)}")
        return []

def notify_results(results):
    """Notifica resultados vía SNS"""
    if not NOTIFICATION_TOPIC:
        return
    
    created_count = len(results['snapshots_created'])
    deleted_count = len(results['snapshots_deleted'])
    errors_count = len(results['errors'])
    
    status_emoji = "✅" if errors_count == 0 else "⚠️"
    
    message = f"""
    {status_emoji} RDS Snapshot Manager - Ejecución Completada
    
    📸 Snapshots creados: {created_count}
    {chr(10).join(['  - ' + s for s in results['snapshots_created']])}
    
    🗑️ Snapshots eliminados: {deleted_count}
    {chr(10).join(['  - ' + s for s in results['snapshots_deleted']])}
    
    ❌ Errores: {errors_count}
    {chr(10).join(['  - ' + e for e in results['errors']])}
    
    ⏰ Timestamp: {datetime.now().isoformat()}
    📅 Retención configurada: {RETENTION_DAYS} días
    """
    
    try:
        sns.publish(
            TopicArn=NOTIFICATION_TOPIC,
            Subject=f'{status_emoji} RDS Snapshots: {created_count} creados, {deleted_count} eliminados',
            Message=message
        )
        print("✓ Notificación enviada")
    except Exception as e:
        print(f"✗ Error enviando notificación: {str(e)}")
