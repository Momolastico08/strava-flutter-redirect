from flask import Flask, request, redirect

app = Flask(__name__)

@app.route('/strava/callback')
def strava_callback():
    code = request.args.get('code')
    if not code:
        return "❌ Code manquant", 400
    return redirect(f"muscutracker://auth/callback?code={code}", code=302)

@app.route('/')
def home():
    return "✅ Backend Strava en ligne"
