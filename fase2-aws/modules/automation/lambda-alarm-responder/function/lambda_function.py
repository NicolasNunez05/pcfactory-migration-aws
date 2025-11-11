"""
Lambda Function: Alarm Responder
Responde automáticamente a alarmas de CloudWatch (auto-remediation)
Trigger: SNS Topic (alarmas de CloudWatch)
"""

import json
import boto3
import os
from datetime import datetime

# Clientes AWS
ec2 = boto3.client('ec2')
rds = boto3.client('rds')
autoscaling = boto3.client('autoscaling')
cloudwatch = boto3.client('cloudwatch')
sns = boto3.client('sns')

PROJECT_NAME = os.environ.get('PROJECT_NAME', 'pcfactory')
NOTIFICATION_TOPIC = os.environ.get('NOTIFICATION_TOPIC_ARN', '')

def lambda_handler(event, context):
    """
    Procesa alarmas de CloudWatch y ejecuta acciones de remediación
    """
    print(f"Evento recibido: {json.dumps(event)}")
    
    try:
        # Parsear mensaje SNS
        for record in event['Records']:
            sns_message = json.loads(record['Sns']['Message'])
            
            alarm_name = sns_message.get('AlarmName', '')
            alarm_state = sns_message.get('NewStateValue', '')
            alarm_reason = sns_message.get('NewStateReason', '')
            
            print(f"Alarma: {alarm_name}")
            print(f"Estado: {alarm_state}")
            print(f"Razón: {alarm_reason}")
            
            # Solo actuar si la alarma está en estado ALARM
            if alarm_state != 'ALARM':
                print(f"Alarma no está en estado ALARM, ignorando")
                continue
            
            # Determinar acción según tipo de alarma
            action_taken = handle_alarm(alarm_name, sns_message)
            
            # Notificar acción tomada
            if action_taken:
                notify_action(alarm_name, action_taken)
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Alarma procesada exitosamente'})
        }
        
    except Exception as e:
        print(f"✗ Error procesando alarma: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def handle_alarm(alarm_name, alarm_data):
    """
    Determina qué acción tomar según el tipo de alarma
    """
    action_taken = None
    
    # ========================================================================
    # ALARMAS DE EC2
    # ========================================================================
    
    # EC2: CPU Alta - Escalar Auto Scaling Group
    if 'ec2-cpu-high' in alarm_name.lower():
        action_taken = scale_up_autoscaling_group()
    
    # EC2: Status Check Failed - Reiniciar instancia
    elif 'status-check' in alarm_name.lower():
        instance_id = extract_instance_id(alarm_data)
        if instance_id:
            action_taken = reboot_instance(instance_id)
    
    # EC2: Memoria Alta - Limpiar caché (custom action)
    elif 'memory-high' in alarm_name.lower():
        action_taken = "Alarma de memoria alta detectada. Considerar escalar verticalmente."
    
    # ========================================================================
    # ALARMAS DE RDS
    # ========================================================================
    
    # RDS: CPU Alta - Aumentar tamaño de instancia (requiere aprobación manual)
    elif 'rds-cpu-high' in alarm_name.lower():
        action_taken = "CPU alta en RDS. Recomendación: aumentar tamaño de instancia."
        # En producción, podrías crear un ticket automático aquí
    
    # RDS: Storage Bajo - Aumentar almacenamiento
    elif 'rds-storage-low' in alarm_name.lower():
        db_instance_id = extract_db_instance_id(alarm_data)
        if db_instance_id:
            action_taken = increase_rds_storage(db_instance_id)
    
    # RDS: Conexiones Altas - Cerrar conexiones idle (requiere script DB)
    elif 'rds-connections-high' in alarm_name.lower():
        action_taken = "Conexiones altas en RDS. Verificar pool de conexiones de aplicación."
    
    # ========================================================================
    # ALARMAS DE SEGURIDAD
    # ========================================================================
    
    # VPN: Auth Failures - Posible ataque de fuerza bruta
    elif 'vpn-auth-failures' in alarm_name.lower():
        action_taken = "Fallos de autenticación VPN. Posible ataque. Revisar logs de seguridad."
        # En producción, podrías deshabilitar temporalmente el endpoint
    
    # Firewall: Invalid Packets - Posible ataque
    elif 'firewall-invalid-packets' in alarm_name.lower():
        action_taken = "Paquetes inválidos detectados. Verificar reglas de firewall."
    
    # ========================================================================
    # ALARMAS DE RED
    # ========================================================================
    
    # VPC: Rejected Connections altas
    elif 'rejected-connections' in alarm_name.lower():
        action_taken = "Conexiones rechazadas altas. Verificar reglas de seguridad."
    
    else:
        action_taken = f"Alarma desconocida: {alarm_name}. No hay acción automática configurada."
    
    return action_taken

# ============================================================================
# FUNCIONES DE REMEDIACIÓN
# ============================================================================

def scale_up_autoscaling_group():
    """Incrementa el desired capacity del Auto Scaling Group"""
    try:
        asg_name = f"{PROJECT_NAME}-app-asg"
        
        # Obtener configuración actual
        response = autoscaling.describe_auto_scaling_groups(
            AutoScalingGroupNames=[asg_name]
        )
        
        if not response['AutoScalingGroups']:
            return "Auto Scaling Group no encontrado"
        
        asg = response['AutoScalingGroups'][0]
        current_desired = asg['DesiredCapacity']
        max_size = asg['MaxSize']
        
        # Incrementar desired capacity (pero no exceder max)
        new_desired = min(current_desired + 1, max_size)
        
        if new_desired > current_desired:
            autoscaling.set_desired_capacity(
                AutoScalingGroupName=asg_name,
                DesiredCapacity=new_desired
            )
            return f"✓ Auto Scaling Group escalado de {current_desired} a {new_desired} instancias"
        else:
            return f"Auto Scaling Group ya está en capacidad máxima ({max_size})"
        
    except Exception as e:
        return f"✗ Error escalando ASG: {str(e)}"

def reboot_instance(instance_id):
    """Reinicia una instancia EC2"""
    try:
        ec2.reboot_instances(InstanceIds=[instance_id])
        return f"✓ Instancia {instance_id} reiniciada"
    except Exception as e:
        return f"✗ Error reiniciando instancia: {str(e)}"

def increase_rds_storage(db_instance_id):
    """Aumenta el almacenamiento de RDS en 20 GB"""
    try:
        # Obtener almacenamiento actual
        response = rds.describe_db_instances(DBInstanceIdentifier=db_instance_id)
        current_storage = response['DBInstances'][0]['AllocatedStorage']
        
        # Aumentar 20 GB
        new_storage = current_storage + 20
        
        rds.modify_db_instance(
            DBInstanceIdentifier=db_instance_id,
            AllocatedStorage=new_storage,
            ApplyImmediately=True
        )
        
        return f"✓ Almacenamiento RDS aumentado de {current_storage} GB a {new_storage} GB"
    except Exception as e:
        return f"✗ Error aumentando almacenamiento RDS: {str(e)}"

# ============================================================================
# FUNCIONES AUXILIARES
# ============================================================================

def extract_instance_id(alarm_data):
    """Extrae el instance ID de los datos de la alarma"""
    try:
        dimensions = alarm_data.get('Trigger', {}).get('Dimensions', [])
        for dim in dimensions:
            if dim.get('name') == 'InstanceId':
                return dim.get('value')
    except:
        pass
    return None

def extract_db_instance_id(alarm_data):
    """Extrae el DB instance ID de los datos de la alarma"""
    try:
        dimensions = alarm_data.get('Trigger', {}).get('Dimensions', [])
        for dim in dimensions:
            if dim.get('name') == 'DBInstanceIdentifier':
                return dim.get('value')
    except:
        pass
    return None

def notify_action(alarm_name, action_taken):
    """Notifica la acción tomada vía SNS"""
    if not NOTIFICATION_TOPIC:
        return
    
    try:
        message = f"""
        🤖 Auto-Remediation Ejecutada
        
        Alarma: {alarm_name}
        Acción: {action_taken}
        Timestamp: {datetime.now().isoformat()}
        
        Esta acción fue ejecutada automáticamente por Lambda.
        """
        
        sns.publish(
            TopicArn=NOTIFICATION_TOPIC,
            Subject=f'Auto-Remediation: {alarm_name}',
            Message=message
        )
        print(f"✓ Notificación enviada a SNS")
    except Exception as e:
        print(f"✗ Error enviando notificación: {str(e)}")
