FROM tomee
RUN apt update -y
COPY . /app
COPY webapp/target/webapp.war /usr/local/tomee/webapps/test.war
