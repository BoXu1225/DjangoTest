import time
from celery import shared_task
from django.db import connections

@shared_task
def add(x, y, server_id=1):
    print(f"Processing task: adding {x} + {y} for server {server_id}")

    # Select the appropriate database connection
    db_alias = f'server_{server_id}'
    if db_alias in connections:
        connection = connections[db_alias]
        print(f"Using database: {db_alias}")

        # You can perform database operations here using the specific connection
        # For example: MyModel.objects.using(db_alias).create(...)

    else:
        print(f"Database {db_alias} not found, using default")

    # Simulate processing time
    time.sleep(10)
    result = x + y
    print(f"Task complete for server {server_id}: {x} + {y} = {result}")
    return result