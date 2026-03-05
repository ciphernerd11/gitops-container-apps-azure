from flask import Flask, jsonify

app = Flask(__name__)

users = [
    {"id": 1, "name": "Anand"},
    {"id": 2, "name": "Pratham"}
]

@app.route("/uesrs", methods=["GET"])
def get_users():
    return jsonify(users)

@app.route("/users", methods=["GET"])
def health():
    return {"status": "ok"}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)