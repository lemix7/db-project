from django.shortcuts import render
from django.http import HttpResponse

# Create your views here.
#create a home method view
def home(require):
    return HttpResponse("hello, man this my best film app")