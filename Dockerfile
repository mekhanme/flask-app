FROM python:3.8-alpine

COPY ./app /app
RUN apk update && pip install -r /app/requirements.txt --no-cache-dir
RUN pip install -e /app
EXPOSE 5000
CMD flask run --host=0.0.0.0