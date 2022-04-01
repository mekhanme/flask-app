FROM python:3.8-alpine

COPY ./ /app
RUN apk update && pip install -r /app/requirements.txt --no-cache-dir
EXPOSE 5000
CMD flask run --host=0.0.0.0