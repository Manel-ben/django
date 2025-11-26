from django.db import models

class University(models.Model):
    name = models.CharField(max_length=200)

    def __str__(self):
        return self.name

class Student(models.Model):
    name = models.CharField(max_length=100)
    address = models.CharField(max_length=200)
    university = models.ForeignKey(University, related_name='students', on_delete=models.CASCADE, null=True, blank=True)

    def __str__(self):
        return self.name