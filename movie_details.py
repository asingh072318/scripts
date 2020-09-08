#!/usr/bin/python
#################################################################
# API used: Movies/TVShows Data (IMDB)
#           By amrelrafie
# www.rapidapi.com
# Pass name of movie as argument on terminal to see the options
# Select any option and get the Director and Cast details
# 
# /movie_details.py badlapur          
# 1. Badlapur Boys
# 2. Badlapur
# Enter your choice: 2
#
#
# Directors of this movie are: 
#
#
#
# Sriram Raghavan
# Priyangi Borthakur
#
#
# Cast of this movie are: 
#
#
#
# Varun Dhawan
# Nawazuddin Siddiqui
# Huma Qureshi
# Yami Gautam
# Divya Dutta
# Radhika Apte
# Vinay Pathak
####################################################################

import requests
import sys
import json

with open("./keys/movie.json") as f:
  config = json.load(f)

search=""
for i in range(1, len(sys.argv)):
  if i != 1:
    search += " "
  search += sys.argv[i]

url = "https://movies-tvshows-data-imdb.p.rapidapi.com/"

querystring_getid = {"title":search,"type":"get-movies-by-title"}

headers = {
    'x-rapidapi-host': config['x-rapidapi-host'],
    'x-rapidapi-key': config['x-rapidapi-key']
    }

response_movies = requests.request("GET", url, headers=headers, params=querystring_getid).json()["movie_results"]

index=1
for movie in response_movies:
  print(str(index)+". "+movie["title"])
  index+=1
choice = input("Enter your choice: ")

querystring_getdetails = {"imdb":response_movies[int(choice)-1]["imdb_id"],"type":"get-movie-details"}
response_details = requests.request("GET", url, headers=headers, params=querystring_getdetails).json()

directors = response_details["directors"]
print("\n")
print("Directors of this movie are: ")
print("\n\n")
for director in directors:
  print(director)

stars = response_details["stars"]
print("\n")
print("Cast of this movie are: ")
print("\n\n")
for cast in stars:
  print(cast)
