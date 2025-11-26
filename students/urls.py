from django.urls import path 
from . import views 
urlpatterns = [ path('add/', views.add_student, name='add_student'), 
               path('getAll/', views.get_all_students, name='get_all_students'), 
               path('getAllUniv/', views.getAllUniv, name='get_all_universities'),
               ]