from flask import Flask, request, render_template, redirect, url_for, flash, send_file, jsonify
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.exc import IntegrityError
from openai  import OpenAI
from twilio.rest import Client
from pathlib import Path
import requests
from io import BytesIO
import pyttsx3
import base64
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///database.db'
app.config['SECRET_KEY'] = 'your_secret_key_here'  
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# Watson Credentials
WATSON_API_KEY = os.environ.get('WATSON_API_KEY')
WATSON_URL = "https://api.eu-gb.text-to-speech.watson.cloud.ibm.com/v1/synthesize"
WATSON_AUTH = "Basic " + base64.b64encode(("apikey:" + WATSON_API_KEY).encode()).decode()

# Weather Credentials
WEATHER_API_KEY = os.environ.get('WEATHER_API_KEY')
WEATHER_URL = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/"

# openAI
openAIClient = OpenAI()


# Twilio Credentials
account_sid = os.environ.get('TWILIO_ACCOUNT_SID')
auth_token = os.environ.get('TWILIO_AUTH_TOKEN')
twilioClient = Client(account_sid, auth_token)

# DB Models
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), unique=True, nullable=False)
    phone = db.Column(db.String(20), nullable=False)
    city = db.Column(db.String(50), nullable=False)
    friends = db.relationship('Friend', backref='user', lazy=True)

class Friend(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), nullable=False)
    phone = db.Column(db.String(20), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)

class Todo(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    content = db.Column(db.String(200), nullable=False)
    completed = db.Column(db.Boolean, default=False, nullable=False)

    def __repr__(self):
        return f'<Todo {self.id} {self.content}>'


@app.route('/', methods=['GET', 'POST'])
def index():

    """
    Renders the main page with user information and todos.
    
    If the request method is POST, updates the user and friends information.
    Otherwise, retrieves the first user and their todos to display.
    
    Returns:
        str: The rendered HTML for the main page.
    """

    if request.method == 'POST':
        user_id = request.form.get('user_id')
        user = User.query.get(user_id)
        if user:
            user.name = request.form['name']
            user.phone = request.form['phone']
            user.city = request.form['city']
            
  
            friends_data = zip(request.form.getlist('friend_id[]'), 
                               request.form.getlist('friend_name[]'), 
                               request.form.getlist('friend_phone[]'))
            existing_friends = {f.id: f for f in user.friends}
            for friend_id, friend_name, friend_phone in friends_data:
                if friend_id:
                    friend = existing_friends.get(int(friend_id))
                    if friend:
                        friend.name = friend_name
                        friend.phone = friend_phone
                else:  
                    new_friend = Friend(name=friend_name, phone=friend_phone, user_id=user.id)
                    db.session.add(new_friend)

            db.session.commit()
        flash('User and friends updated successfully')
        return redirect(url_for('index'))

    user = User.query.first() 
    todos = Todo.query.all()
    return render_template('index.html', user=user, friends=user.friends if user else [], todos=todos)


@app.route('/get-audio', methods=['POST'])
def get_audio():

    """
    Generates audio for a given text using text-to-speech.

    If the text is "Good Morning" or "Good Night", it personalizes the message with the user's name.
    
    Returns:
        Response: The audio file generated from the text.
    """



    text = request.json.get("text")
    if not text:
        return "Invalid request. 'text' is required.", 400
    
    if text == "Good Morning":
        user = User.query.first()
        text = f"Good Morning, {user.name}"
    
    if text == "Good Night":
        user = User.query.first()
        text = f"Good Night, {user.name}"

    return convert_text_to_speech(text)

@app.route('/weather', methods=['POST'])
def get_weather():


    """
    Fetches the current weather for a specified city or the user's city.

    Converts the weather information into speech.

    Returns:
        Response: The audio file of the weather information.
    """



    default_city = User.query.first().city
    city = request.args.get('city', default_city)
    final_url = f"{WEATHER_URL}{city}?unitGroup=metric&key={WEATHER_API_KEY}&contentType=json"
    weather_response = requests.get(final_url)
    if weather_response.status_code == 200:
        weather_data = weather_response.json()
        text = f"The current weather in {city} is {weather_data['currentConditions']['conditions']}, with a temperature of {weather_data['currentConditions']['temp']} degrees Celsius."

        return convert_text_to_speech(text)
    else:
        return f"Error fetching weather: {weather_response.status_code}", weather_response.status_code

def call_chatgpt_api(user_query, system="search"):

    """
    Calls the ChatGPT API to get a response for a given user query.

    Args:
        user_query (str): The user's query to ChatGPT.
        system (str): The system prompt for ChatGPT to follow ("search" or "song").
    
    Returns:
        str: The response from ChatGPT.
    """

    if system == "search":
        system_query = "Your responses should be brief and abstract, no more than 10 words."
    if system == "song":
        system_query = "Your response should be to complete the song's next 1 or 2 lines (maximum) whichever feels appropriate."

    completion = openAIClient.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content":system_query},
            {"role": "user", "content": user_query}
        ]
    ) 
    print (completion.choices[0].message)
    return completion.choices[0].message.content

@app.route('/chatgpt', methods=['POST'])
def chat_with_gpt():


    """
    Handles a chat request with ChatGPT.

    Retrieves the user query from the request and gets a response from ChatGPT.

    Returns:
        Response: The audio file of the ChatGPT response.
    """



    user_query = request.json.get("query")

    response_text = call_chatgpt_api(user_query, system="search")
    return convert_text_to_speech(response_text)

@app.route('/song', methods=['POST'])
def completeSong():

    """
    Completes the next line or two of a song using ChatGPT.

    Retrieves the user query (song lyrics) from the request and gets a response from ChatGPT.

    Returns:
        Response: The audio file of the completed song lyrics.
    """



    user_query = request.json.get("query")
    response_text = call_chatgpt_api(user_query, system="song")
    return convert_text_to_speech(response_text)

# For Marvin
@app.route('/addTodo', methods=['POST'])
def addTodo():


    """
    Adds a new todo item to the database.

    Retrieves the todo content from the request and adds it to the database.

    Returns:
        Response: A JSON response indicating success or failure.
    """

    todo_content = request.json.get("todo")
    if not todo_content:
        return jsonify({"error": "No todo content provided"}), 400

    new_todo = Todo(content=todo_content)
    db.session.add(new_todo)
    try:
        db.session.commit()
        return jsonify({"message": "Todo added successfully!", "todo": {"id": new_todo.id, "content": new_todo.content, "completed": new_todo.completed}}), 201
    except IntegrityError:
        db.session.rollback()
        return jsonify({"error": "Could not add the todo"}), 500

@app.route('/tellTodos', methods=['POST'])
def tellTodos():

    """
    Retrieves all incomplete todo items and converts them to speech.

    Returns:
        Response: The audio file listing all incomplete todo items.
    """



    todos = Todo.query.filter_by(completed=False).all()

    if not todos:
        response_text = "You currently have no incomplete todo items."
    else:
        response_text = "Here are your incomplete todo items: "
        response_text += ", ".join(f"Number {i+1}, {todo.content}" for i, todo in enumerate(todos))
    
    return convert_text_to_speech(response_text)

# For Website
@app.route('/update_todos', methods=['POST'])
def update_todos():

    """
    Updates the completion status of todo items based on the form data.

    Marks the todo items as completed or not completed in the database.

    Returns:
        Response: Redirects to the main page with a success flash message.
    """

    completed_ids = request.form.getlist('completed[]')
    todos = Todo.query.all()
    for todo in todos:
        todo.completed = str(todo.id) in completed_ids
    db.session.commit()
    flash('Todos updated successfully')
    return redirect(url_for('index'))

@app.route('/delete_todo/<int:todo_id>', methods=['POST'])
def delete_todo(todo_id):

    """
    Deletes a specified todo item from the database.

    Args:
        todo_id (int): The ID of the todo item to delete.

    Returns:
        Response: Redirects to the main page with a flash message indicating success or failure.
    """


    todo = Todo.query.get(todo_id)
    if todo:
        db.session.delete(todo)
        db.session.commit()
        flash('Todo deleted successfully')
    else:
        flash('Todo not found')
    return redirect(url_for('index'))

@app.route('/addTodoFromWebsite', methods=['POST'])
def addTodoFromWebsite():

    """
    Adds a new todo item from the website form.

    Retrieves the todo content from the form and adds it to the database.

    Returns:
        Response: Redirects to the main page with a flash message indicating success or failure.
    """


    todo_content = request.form['todo']
    if not todo_content:
        flash('No todo content provided')
        return redirect(url_for('index'))

    new_todo = Todo(content=todo_content)
    db.session.add(new_todo)
    db.session.commit()
    flash('Todo added successfully')
    return redirect(url_for('index'))

# LOCAL TTS SERVICE
# def convert_text_to_speech(text):
#     engine = pyttsx3.init()
#     audio_stream = BytesIO()

#     def on_save(name, completed):
#         if completed:
#             audio_stream.seek(0)

#     engine.save_to_file(text, audio_stream)
#     engine.runAndWait()
    
#     audio_stream.seek(0)
#     return send_file(audio_stream, mimetype='audio/wav')

# IBM TTS SERVICE
def convert_text_to_speech(text):

    """
    Converts the given text to speech using IBM Watson TTS service.

    Args:
        text (str): The text to convert to speech.

    Returns:
        Response: The audio file generated from the text.
    """

    headers = {
        "Authorization": WATSON_AUTH,
        "Content-Type": "application/json",
        "Accept": "audio/wav"
    }
    payload = {"text": text}
    response = requests.post(WATSON_URL, headers=headers, json=payload)
    if response.status_code == 200:
        audio_stream = BytesIO(response.content)
        audio_stream.seek(0)
        return send_file(audio_stream, mimetype='audio/wav')
    else:
        return f"Error converting text to speech: {response.status_code}", response.status_code

# OPENAI TTS SERVICE
# def convert_text_to_speech(text):
#     try:
#         response = openAIClient.audio.speech.create(
#             model="tts-1", 
#             voice="alloy",
#             input=text
#         )
#         speech_file_path = Path(__file__).parent / "speech.wav"

#         # Write the binary audio content directly from the API's response
#         with open(speech_file_path, "wb") as f:
#             f.write(response.content)

#         # Return the WAV file to the client directly
#         return send_file(speech_file_path, mimetype='audio/wav')

#     except Exception as e:
#         app.logger.error(f"Error in generating TTS audio: {str(e)}")
#         return {"error": str(e)}, 500


def sendText(to, body):

    """
    Sends a text message using Twilio API.

    Args:
        to (str): The recipient's phone number.
        body (str): The message content.

    Returns:
        Response: A JSON response indicating success or failure.
    """

    try:
        message = twilioClient.messages.create(
                    body=body,
                    from_='+447700105367',
                    to=to
        )
            
        print(message.sid)

        return jsonify({"status": "success", "to": to, "body": body})

    except Exception as e:  
        print(f"Error in sending text: {str(e)}")
        return {"error": str(e)}, 500

@app.route('/text', methods=['POST'])
def text_request():

    """
    Handles a request to send a text message to a friend.

    Retrieves the friend's name and message body from the request, 
    finds the friend's phone number in the database, and sends the message.

    Returns:
        Response: A JSON response indicating success or an error message if the friend is not found.
    """

    data = request.json 
    name = data.get('name', '')
    body = data.get('body', '')
    
    friend = Friend.query.filter_by(name=name).first()
    if friend:
        body = data.get('body', '')
        return sendText(friend.phone, body)
    else:
        return {"error": "Friend not found"}, 404

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=True, host='0.0.0.0')

