FROM lntinfa/infa-base-jdk
MAINTAINER LNT

ADD h2/ /opt/h2
RUN chmod 755 /opt/h2/bin/*.sh

ADD bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh; \
    chmod 700 /etc/bootstrap.sh


RUN mkdir /export

ENV BOOTSTRAP /etc/bootstrap.sh

CMD ["/etc/bootstrap.sh", "-d"]

EXPOSE 9092 5435
