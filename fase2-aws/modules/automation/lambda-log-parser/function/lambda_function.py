"""
Lambda Function: Log Parser
Parsea logs de CloudWatch y extrae métricas custom
Trigger: CloudWatch Logs Subscription Filter
"""

import json
import base64
import gzip
import boto3
import os
from datetime import datetime

cloudwatch = boto3.client('cloudwatch')

# Configuración
NAMESPACE = os.environ.get('CLOUDWATCH_NAMESPACE', 'PCFactory/Custom')
PROJECT_NAME = os.environ.get('PROJECT_NAME', 'pcfactory')

def lambda_handler(event, context):
    """
    Procesa logs de CloudWatch y extrae métricas
    """
    print(f"Evento recibido: {json.dumps(event)}")
    
    try:
        # Decodificar datos de CloudWatch Logs
        log_data = extract_log_data(event)
        
        # Parsear y analizar logs
        metrics = parse_logs(log_data)
        
        # Enviar métricas a CloudWatch
        if metrics:
            send_metrics_to_cloudwatch(metrics)
            print(f"✓ {len(metrics)} métricas enviadas a CloudWatch")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Logs procesados exitosamente',
                'metrics_count': len(metrics)
            })
        }
        
    except Exception as e:
        print(f"✗ Error procesando logs: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def extract_log_data(event):
    """Extrae y decodifica datos de CloudWatch Logs"""
    # CloudWatch Logs envía datos comprimidos en base64
    compressed_payload = base64.b64decode(event['awslogs']['data'])
    uncompressed_payload = gzip.decompress(compressed_payload)
    log_data = json.loads(uncompressed_payload)
    return log_data

def parse_logs(log_data):
    """
    Parsea logs y extrae métricas relevantes
    Busca patrones específicos en los logs
    """
    metrics = []
    
    for log_event in log_data['logEvents']:
        message = log_event['message']
        timestamp = log_event['timestamp']
        
        # Detectar errores
        if 'ERROR' in message or 'error' in message:
            metrics.append({
                'MetricName': 'ApplicationErrors',
                'Value': 1,
                'Unit': 'Count',
                'Timestamp': datetime.fromtimestamp(timestamp / 1000),
                'Dimensions': [
                    {'Name': 'LogGroup', 'Value': log_data['logGroup']},
                    {'Name': 'Severity', 'Value': 'Error'}
                ]
            })
        
        # Detectar warnings
        if 'WARNING' in message or 'warning' in message:
            metrics.append({
                'MetricName': 'ApplicationWarnings',
                'Value': 1,
                'Unit': 'Count',
                'Timestamp': datetime.fromtimestamp(timestamp / 1000),
                'Dimensions': [
                    {'Name': 'LogGroup', 'Value': log_data['logGroup']},
                    {'Name': 'Severity', 'Value': 'Warning'}
                ]
            })
        
        # Detectar tiempos de respuesta (ejemplo: "Response time: 1.5s")
        if 'Response time:' in message:
            try:
                time_str = message.split('Response time:')[1].strip().split('s')[0]
                response_time = float(time_str)
                metrics.append({
                    'MetricName': 'ResponseTime',
                    'Value': response_time,
                    'Unit': 'Seconds',
                    'Timestamp': datetime.fromtimestamp(timestamp / 1000),
                    'Dimensions': [
                        {'Name': 'LogGroup', 'Value': log_data['logGroup']}
                    ]
                })
            except:
                pass
        
        # Detectar conexiones de base de datos
        if 'Database connection' in message:
            if 'established' in message:
                metrics.append({
                    'MetricName': 'DatabaseConnections',
                    'Value': 1,
                    'Unit': 'Count',
                    'Timestamp': datetime.fromtimestamp(timestamp / 1000),
                    'Dimensions': [
                        {'Name': 'Status', 'Value': 'Connected'}
                    ]
                })
            elif 'failed' in message:
                metrics.append({
                    'MetricName': 'DatabaseConnectionErrors',
                    'Value': 1,
                    'Unit': 'Count',
                    'Timestamp': datetime.fromtimestamp(timestamp / 1000),
                    'Dimensions': [
                        {'Name': 'Status', 'Value': 'Failed'}
                    ]
                })
    
    return metrics

def send_metrics_to_cloudwatch(metrics):
    """Envía métricas a CloudWatch"""
    # CloudWatch solo acepta 20 métricas por llamada
    batch_size = 20
    
    for i in range(0, len(metrics), batch_size):
        batch = metrics[i:i + batch_size]
        
        try:
            cloudwatch.put_metric_data(
                Namespace=NAMESPACE,
                MetricData=batch
            )
            print(f"✓ Batch de {len(batch)} métricas enviado")
        except Exception as e:
            print(f"✗ Error enviando batch: {str(e)}")
