from flask import Flask, jsonify, request
import datetime
import socket
import os

app = Flask(__name__)

@app.route('/')
def get_time_and_ip():
    timestamp = datetime.datetime.now().isoformat()
    ip_address = request.remote_addr
    return jsonify({"timestamp": timestamp, "ip": ip_address})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
