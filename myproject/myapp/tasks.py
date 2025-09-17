import time
from celery import shared_task

@shared_task
def add(x, y):
    print(f"Processing task: adding {x} + {y}")
    time.sleep(10)
    result = x + y
    print(f"Task complete: {x} + {y} = {result}")
    return result