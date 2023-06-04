from flask import Flask
from prometheus_flask_exporter import PrometheusMetrics
import subprocess

app = Flask(__name__)
PrometheusMetrics(app)

endpoints = ("/", "/holdmybeer", "/error")

@app.route('/') # I defined a function that will launch a subprocess when the root is called and run the script provided in the challenge
def display_timestamp():

    process = subprocess.Popen(['python', 'print_timestamp.py'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, error = process.communicate()

    return output.decode()

@app.route("/error") # generate 500 HTTP response for complimenting the grafana graph
def oops():
    return ":(", 500

@app.route("/holdmybeer") # generate a 200 HTTP response at a different latency
def iwillholdit():
    return "Thank you very much kind sir!"
# app will listen on all ips and open on port 5000 along with serving data multithreaded if possible
if __name__ == "__main__":
    app.run("0.0.0.0", 5000, threaded=True)
