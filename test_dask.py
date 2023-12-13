import json
from dask.distributed import Client, progress, get_worker
import os

client = Client("tcp://localhost:8786") # NOTE: Replace scheduler IP here
# client = Client(processes=False) # NOTE: Replace scheduler IP here

def run_on_worker(data):
    print("Inside run on worker. Printing environment variables:")
    print(os.environ) # This contains the NODE_ARG, GROUP_ARG and ALL_ARG env variables. Use as needed.
    worker = get_worker()
    print(worker)
    with open(f"/share/worker_{worker.id}_function_{data}.txt", "w+") as f:
        f.write(f"Hello from worker {worker.id} with data {data}")
    
    with open(f"/share/worker_{worker.id}_env.json", "w+") as f:
        json.dump(dict(os.environ), f)
    return True

num_of_workers = len(client.scheduler_info()["workers"])
print("Number of connected workers = ", num_of_workers)
futures = client.map(run_on_worker, range(num_of_workers*3))
results = client.gather(futures)
print("Received results from workers:")
print(results)
