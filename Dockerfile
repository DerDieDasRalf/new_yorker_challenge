# Alpine 3.10 in the Spark image used below is end-of-life and has no patched package.
# We use a current Alpine image to generate certificate stores with the
# eMudhra security fix.
# Incident details: https://blog.cloudflare.com/emudhra-certificate-compromise/
FROM alpine:3.23 AS certificates
RUN apk add --no-cache \
    ca-certificates-bundle=20261020-r0 \
    java-cacerts=1.1-r0

FROM bde2020/spark-master:2.4.5-hadoop2.7

# Keep the old Spark environment, but replace its Linux and Java trust stores.
COPY --from=certificates /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=certificates /etc/ssl/certs/java/cacerts /etc/ssl/certs/java/cacerts
# Old pip may use its own CA bundle, so explicitly select the patched one.
ENV PIP_CERT=/etc/ssl/certs/ca-certificates.crt

COPY recommender /app/recommender
COPY data /app/data
COPY spark-defaults.conf /spark/conf

RUN pip install pyspark==2.4.5

RUN apk update
RUN apk add build-base
RUN apk add python-dev
RUN pip install numpy
