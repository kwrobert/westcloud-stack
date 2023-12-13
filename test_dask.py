from dask.distributed import Client, progress, get_worker
import os

client = Client("tcp://localhost:8786") # NOTE: Replace scheduler IP here

def run_on_worker(data):
    print("Inside run on worker. Printing environment variables:")
    print(os.environ) # This contains the NODE_ARG, GROUP_ARG and ALL_ARG env variables. Use as needed.
    return os.environ

num_of_workers = len(client.scheduler_info()["workers"])
print("Number of connected workers = ", num_of_workers)
futures = client.map(run_on_worker, range(num_of_workers))
results = client.gather(futures)
print("Received results from workers:")
print(results)
