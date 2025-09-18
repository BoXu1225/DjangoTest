import os
from django.shortcuts import render
from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from .tasks import add
from .models import Calculation

def home(request):
    server_id = os.environ.get('SERVER_ID', 'Unknown')

    if request.method == 'POST':
        try:
            x = int(request.POST.get('x', 0))
            y = int(request.POST.get('y', 0))

            # Get server ID from environment variable
            server_id_int = int(os.environ.get('SERVER_ID', 1))

            # Submit task with server ID
            task = add.delay(x, y, server_id_int)

            return HttpResponse(f"Task submitted successfully! Adding {x} + {y} (Server {server_id_int})<br>"
                              f"Task ID: {task.id}<br>"
                              f"<a href='/'>← Back to form</a>")
        except ValueError:
            return HttpResponse("Please enter valid numbers")

    # Get recent calculations for this server
    try:
        server_id_int = int(server_id) if server_id != 'Unknown' else 1
        recent_calculations = Calculation.objects.filter(server_id=server_id_int).order_by('-processed_at')[:10]
    except:
        recent_calculations = []

    context = {
        'server_id': server_id,
        'recent_calculations': recent_calculations
    }
    return render(request, 'myapp/home.html', context)
