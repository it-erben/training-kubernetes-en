from flask import Flask

app = Flask(__name__)

@app.route('/')
def hallo():
    return "Hallo, Willkommen bei der Docker-Flask-Anwendung!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
