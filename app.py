from flask import Flask, request

app = Flask(__name__)

@app.route('/callback')
def strava_redirect():
    code = request.args.get('code')
    return f"<h1>Code reçu : {code}</h1>"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=10000)
