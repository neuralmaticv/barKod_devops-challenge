from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello_world():
    return '<h1>barKod & arch.cloud</h2>'

if __name__ == "__main__":
    app.run(threaded=True,host="0.0.0.0",port=8000)
