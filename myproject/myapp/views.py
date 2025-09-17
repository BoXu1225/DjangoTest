from django.shortcuts import render
from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from .tasks import add

def home(request):
    if request.method == 'POST':
        try:
            x = int(request.POST.get('x', 0))
            y = int(request.POST.get('y', 0))

            add.delay(x, y)

            return HttpResponse(f"Task submitted successfully! Adding {x} + {y}")
        except ValueError:
            return HttpResponse("Please enter valid numbers")

    return render(request, 'myapp/home.html')
