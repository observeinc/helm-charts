from functools import wraps

def print_test_decorator(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        print('\n')
        print("*" * 30)
        print("Running Test:", func.__name__)      
        print("*" * 30)   
        print('\n')
   
        result = func(*args, **kwargs) 
        return result
    return wrapper