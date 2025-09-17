import os
from django.shortcuts import render
from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from .tasks import add

def home(request):
    if request.method == 'POST':
        try:
            x = int(request.POST.get('x', 0))
            y = int(request.POST.get('y', 0))

            # Get server ID from environment variable
            server_id = int(os.environ.get('SERVER_ID', 1))

            # Submit task with server ID
            add.delay(x, y, server_id)

            return HttpResponse(f"Task submitted successfully! Adding {x} + {y} (Server {server_id})")
        except ValueError:
            return HttpResponse("Please enter valid numbers")

    # Display server ID on the form
    server_id = os.environ.get('SERVER_ID', 'Unknown')
    return render(request, 'myapp/home.html', {'server_id': server_id})
