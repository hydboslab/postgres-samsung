#!/usr/bin/python3

import sys
import subprocess
import threading
from time import sleep

PSQL=""
PORT='5678'
CAPTURE_TIME=0

FLAG=False

class Worker(threading.Thread):
	def __init__(self):
		threading.Thread.__init__(self)

	def run(self):
		global PSQL, PORT, FLAG
		
		query = "SELECT relation::regclass, * FROM pg_locks WHERE NOT granted;"
		pg = [PSQL, '-p', PORT, '-d', 'postgres', '-c', query]

		print("worker start")

		while FLAG == False:
			process = subprocess.run(pg, capture_output=True)
			stdout_as_str = process.stdout.decode("utf-8")

			if stdout_as_str.split('\n')[-3] != "(0 rows)":
				print(stdout_as_str)

			sleep(0.01)
	
		print("worker finished")

if __name__ == "__main__":
	if len(sys.argv) != 2:
		print("Usage: python3 pg_lock.py (capture time)")
		exit()

	CAPTURE_TIME = int(sys.argv[1])
	PSQL = subprocess.run(["pwd"], capture_output=True).stdout.decode("utf-8").split('\n')[0] + "/pgsql/bin/psql"
	
	worker = Worker()
	worker.start()

	sleep(CAPTURE_TIME)

	FLAG = True

	worker.join()