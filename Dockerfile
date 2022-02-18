FROM ubuntu:20.04

RUN apt-get update && apt-get install -y netcat jq bc
RUN mkdir /app
COPY automate-shed-heating.sh common.sh /app/

ENTRYPOINT ["/app/automate-shed-heating.sh"]
