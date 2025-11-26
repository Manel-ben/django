from rest_framework.decorators import api_view 
from rest_framework.response import Response 
from .models import Student 
from .serializers import StudentSerializer 
from django.http import JsonResponse
@api_view(['POST']) 
def add_student(request):
     serializer = StudentSerializer(data=request.data) 
     if serializer.is_valid():
         serializer.save() 
         return Response({"message": "New student is added"}) 
     return Response(serializer.errors, status=400) 

@api_view(['GET']) 
def get_all_students(request): 
    students = Student.objects.all()
    serializer = StudentSerializer(students, many=True) 
    return Response(serializer.data)

@api_view(['GET'])
def getAllUniv(request):
    data = list(Student.objects.values("name", "university__name"))
    return JsonResponse(data, safe=False)


