from flask import Flask, render_template, redirect, request, url_for

app = Flask(__name__)

todos = []

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/add", methods = ['POST'])
def add():
    todo = request.form['todo']
    todos.append({'task':todo, 'done':False})
    return redirect(url_for('index'))



