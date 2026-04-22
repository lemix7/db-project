from django.db import models
#import django AbsractUser to manager a user 
from django.contrib.auth.models import AbstractUser
# Create all  models for Film_Database_Table.

# create User model(Table)
class User(AbstractUser):
    full_name = models.CharField(max_length=100)
    role = models.CharField(max_length=20)
    is_active = models.BooleanField(default=True)
    create_at = models.DateTimeField(auto_now_add=True)

    #return username for database_view
    def __str__(self):
        return self.username

# create a Departments models(Table)
class Department(models.Model):
    name = models.CharField(max_length=100)
    description= models.TextField(blank=True, null=True)

    #return dept_name for database_view
    def __str__(self):
        return self.name

#create a film model(Table)
class Film(models.Model):
    title = models.CharField(max_length=200)
    genre = models.CharField(max_length=50, blank=True, null=True)
    status = models.CharField(max_length=20)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateTimeField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    create_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='film_created')
    create_at = models.DateTimeField(auto_now_add=True)
    #return film_title for database_view
    def __str__(self):
        return self.title
    
#create a Budget models(Table)
class Budget(models.Model):
    film = models.ForeignKey(Film, on_delete=models.CASCADE, related_name='budgets')
    total_amount = models.DecimalField(max_digits=15, decimal_places=2)
    currency = models.CharField(max_length=10, default='USD')
    create_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    create_at = models.DateTimeField(auto_now_add=True)


#create a expense models(Table)
class Expense(models.Model):
    film = models.ForeignKey(Film, on_delete=models.CASCADE, related_name='expenses')
    category = models.CharField(max_length=50)
    description = models.TextField(blank=True, null=True)
    amount = models.DecimalField(max_digits=15, decimal_places=2)
    expense_date = models.DateField()
    recorded_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)


#create a Member models(Table)
class CrewMember(models.Model):
    user= models.OneToOneField(User, on_delete=models.CASCADE, related_name='crew_profile')
    department = models.ForeignKey(Department, on_delete=models.SET_NULL, null=True)
    job_title = models.CharField(max_length=20, blank=True,null=True)
    hire_date = models.DateField(blank=True, null=True)

    #return user_full_name job_title for database_view
    def __str__(self):
        return f"{self.user.full_name} - {self.job_title}"



#create filmCrewm models(Table)
class FilmCrew(models.Model):
    film = models.ForeignKey(Film, on_delete=models.CASCADE)
    crew_member = models.ForeignKey(CrewMember, on_delete=models.CASCADE)
    role_on_film = models.CharField(max_length=100)
    assigned_at = models.DateTimeField(auto_now_add=True)



#create a audit log models (Table)
class AuditLog(models.Model):
    table_name = models.CharField(max_length=50)
    operation = models.CharField(max_length=10)
    record_id = models.IntegerField()
    change_at = models.DateTimeField(auto_now_add=True)
    old_data = models.JSONField(null=True, blank=True)
    new_data = models.JSONField(null=True, blank=True)

    #return operation made table_name an time of change for database_view

    def __str__(self):
        return f"{self.operation} on {self.table_name} at {self.change_at}"
    




