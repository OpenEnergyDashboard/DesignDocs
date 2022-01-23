#!/bin/bash

# This script inserts the first version of the meters and data into the database. The ids will be updated by a database script.

# This creates meters.
curl localhost:3000/api/csv/meters -X POST -F 'headerRow=true' -F 'gzip=false' -F 'email=test@example.com' -F 'password=password' -F 'csvfile=@oedData/meters.csv'

# Insert each meter with readings into the database. Note that the meter name does not include the beginning M since that will be added by the database script.
curl localhost:3000/api/csv/readings -X POST -F 'meterName=eter 1' -F 'headerRow=true' -F 'gzip=false' -F 'email=test@example.com' -F 'password=password' -F 'csvfile=@oedData/Readings1.csv'
curl localhost:3000/api/csv/readings -X POST -F 'meterName=eter 2' -F 'headerRow=true' -F 'gzip=false' -F 'email=test@example.com' -F 'password=password' -F 'csvfile=@oedData/Readings2.csv'
curl localhost:3000/api/csv/readings -X POST -F 'meterName=eter A' -F 'headerRow=true' -F 'lengthVariation=8000000' -F 'gzip=false' -F 'email=test@example.com' -F 'password=password' -F 'csvfile=@oedData/ReadingsA.csv'
curl localhost:3000/api/csv/readings -X POST -F 'meterName=eter B' -F 'headerRow=true' -F 'lengthVariation=8000000' -F 'gzip=false' -F 'email=test@example.com' -F 'password=password' -F 'csvfile=@oedData/ReadingsB.csv'
curl localhost:3000/api/csv/readings -X POST -F 'meterName=eter C' -F 'headerRow=true' -F 'lengthVariation=8000000' -F 'gzip=false' -F 'email=test@example.com' -F 'password=password' -F 'csvfile=@oedData/ReadingsC.csv'
curl localhost:3000/api/csv/readings -X POST -F 'refreshReadings=true' -F 'refreshHourlyReadings=true' -F 'meterName=eter D' -F 'headerRow=true' -F 'lengthVariation=8000000' -F 'gzip=false' -F 'email=test@example.com' -F 'password=password' -F 'csvfile=@oedData/ReadingsD.csv'
