FROM python:3.8-slim

WORKDIR /app
COPY . .

RUN python3 -m pip install -r requirements.txt

CMD [ "python3", "app.py" ]
