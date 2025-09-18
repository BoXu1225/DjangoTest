import time
from celery import shared_task
from django.db import connections
from django.utils import timezone
from .models import Calculation

@shared_task(bind=True)
def add(self, x, y, server_id=1):
    task_id = self.request.id
    print(f"Processing task {task_id}: adding {x} + {y} for server {server_id}")

    # Select the appropriate database connection
    db_alias = f'server_{server_id}'
    if db_alias not in connections:
        print(f"Database {db_alias} not found, using default")
        db_alias = 'default'

    print(f"Using database: {db_alias}")

    # Record the start time
    start_time = timezone.now()

    # Simulate processing time
    time.sleep(10)
    result = x + y

    # Save the calculation to the database
    try:
        calculation = Calculation.objects.using(db_alias).create(
            x=x,
            y=y,
            result=result,
            server_id=server_id,
            task_id=task_id,
            created_at=start_time
        )
        print(f"Task complete for server {server_id}: {x} + {y} = {result} (saved to database {db_alias})")
        print(f"Calculation record ID: {calculation.id}")
    except Exception as e:
        print(f"Error saving calculation to database: {e}")

    return result