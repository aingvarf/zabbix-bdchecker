#!/usr/bin/python
import socket
import sys

# echo "DSN1,SQL_NAME,PARAM1,PARAM2" | ./get_data.py localhost 10000

if (len(sys.argv) != 3):
    print "usage: " + sys.argv[0] + " host port <message >answer"
else:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((sys.argv[1], int(sys.argv[2])))
    msg = sys.stdin.read()
    s.send(msg)
    answer = s.recv(1024)
    print answer
