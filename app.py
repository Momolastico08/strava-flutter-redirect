from flask import Flask, request, redirect

app = Flask(__name__)

@app.route('/callback')
def strava_redirect():
    code = request.args.get('code')
    if code:
        # Redirige vers l'application Flutter (schéma personnalisé)
        return redirect(f"muscutracker://auth/callback?code={code}")
    return "❌ Aucun code reçu", 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=10000)
